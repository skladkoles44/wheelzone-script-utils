#!/usr/bin/env bash
# title: WZ :: Autoparts DB Bringup (idempotent)
# version: 1.1.0
set -Eeuo pipefail; IFS=$'\n\t'

VPS_HOST="${VPS_HOST:-79.174.85.106}"
VPS_PORT="${VPS_PORT:-2222}"
DB_NAME="${DB_NAME:-wz_products}"
DB_OWNER_ROLE="${DB_OWNER_ROLE:-wz_app}"
DB_OWNER_PASS="${DB_OWNER_PASS:-}"
DB_READ_ROLE="${DB_READ_ROLE:-wz_readonly}"
ENV_PATH="${ENV_PATH:-/root/.env.wzdb}"

say(){ printf "==[ %s ]==\n" "$*"; }

say "CONNECT VPS ${VPS_HOST}:${VPS_PORT}"
ssh -p "$VPS_PORT" "root@${VPS_HOST}" bash -se <<'SQL'
set -Eeuo pipefail
log(){ printf "[WZ] %s\n" "$*"; }
PSQL(){ sudo -u postgres psql -v ON_ERROR_STOP=1 "$@"; }

DB_NAME="${DB_NAME:-wz_products}"
DB_OWNER_ROLE="${DB_OWNER_ROLE:-wz_app}"
DB_OWNER_PASS="${DB_OWNER_PASS:-}"
DB_READ_ROLE="${DB_READ_ROLE:-wz_readonly}"
ENV_PATH="${ENV_PATH:-/root/.env.wzdb}"

[ -z "$DB_OWNER_PASS" ] && DB_OWNER_PASS="$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 28)"

# роли
PSQL <<EOSQL
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='${DB_OWNER_ROLE}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${DB_OWNER_ROLE}', '${DB_OWNER_PASS}');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='${DB_READ_ROLE}') THEN
    EXECUTE format('CREATE ROLE %I NOINHERIT', '${DB_READ_ROLE}');
  END IF;
END$$;
EOSQL

# база
EXISTS=\$(PSQL -At -c "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")
if [ -z "\$EXISTS" ]; then
  PSQL -c "CREATE DATABASE \"${DB_NAME}\" OWNER \"${DB_OWNER_ROLE}\""
fi

# схема
PSQL -d "\$DB_NAME" <<'EOSQL'
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS core;

-- brands
CREATE TABLE IF NOT EXISTS ref.brands (id BIGSERIAL PRIMARY KEY);
ALTER TABLE ref.brands
  ADD COLUMN IF NOT EXISTS uuid uuid DEFAULT gen_random_uuid() NOT NULL,
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS country text,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
DO $$BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname='ux_brands_name') THEN
    CREATE UNIQUE INDEX ux_brands_name ON ref.brands(LOWER(name));
  END IF;
END$$;

-- categories
CREATE TABLE IF NOT EXISTS ref.categories (id BIGSERIAL PRIMARY KEY);
ALTER TABLE ref.categories
  ADD COLUMN IF NOT EXISTS uuid uuid DEFAULT gen_random_uuid() NOT NULL,
  ADD COLUMN IF NOT EXISTS code text,
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
DO $$BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname='ux_categories_code') THEN
    CREATE UNIQUE INDEX ux_categories_code ON ref.categories(LOWER(code));
  END IF;
END$$;

-- suppliers
CREATE TABLE IF NOT EXISTS ref.suppliers (id BIGSERIAL PRIMARY KEY);
ALTER TABLE ref.suppliers
  ADD COLUMN IF NOT EXISTS uuid uuid DEFAULT gen_random_uuid() NOT NULL,
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS site text,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- products
CREATE TABLE IF NOT EXISTS core.products (id BIGSERIAL PRIMARY KEY);
ALTER TABLE core.products
  ADD COLUMN IF NOT EXISTS uuid uuid DEFAULT gen_random_uuid() NOT NULL,
  ADD COLUMN IF NOT EXISTS brand_id bigint,
  ADD COLUMN IF NOT EXISTS category_id bigint,
  ADD COLUMN IF NOT EXISTS model text,
  ADD COLUMN IF NOT EXISTS season text,
  ADD COLUMN IF NOT EXISTS spec_json jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
CREATE INDEX IF NOT EXISTS ix_products_model ON core.products(LOWER(model));

-- variants
CREATE TABLE IF NOT EXISTS core.variants (id BIGSERIAL PRIMARY KEY);
ALTER TABLE core.variants
  ADD COLUMN IF NOT EXISTS uuid uuid DEFAULT gen_random_uuid() NOT NULL,
  ADD COLUMN IF NOT EXISTS product_id bigint,
  ADD COLUMN IF NOT EXISTS size_label text,
  ADD COLUMN IF NOT EXISTS load_index text,
  ADD COLUMN IF NOT EXISTS speed_index text,
  ADD COLUMN IF NOT EXISTS ean text,
  ADD COLUMN IF NOT EXISTS extras_json jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
CREATE INDEX IF NOT EXISTS ix_variants_ean ON core.variants(LOWER(ean));

-- prices
CREATE TABLE IF NOT EXISTS core.prices (id BIGSERIAL PRIMARY KEY);
ALTER TABLE core.prices
  ADD COLUMN IF NOT EXISTS variant_id bigint,
  ADD COLUMN IF NOT EXISTS supplier_id bigint,
  ADD COLUMN IF NOT EXISTS price numeric(12,2),
  ADD COLUMN IF NOT EXISTS currency text DEFAULT 'RUB',
  ADD COLUMN IF NOT EXISTS valid_from timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS valid_to timestamptz,
  ADD COLUMN IF NOT EXISTS meta_json jsonb DEFAULT '{}'::jsonb;

-- stocks
CREATE TABLE IF NOT EXISTS core.stocks (id BIGSERIAL PRIMARY KEY);
ALTER TABLE core.stocks
  ADD COLUMN IF NOT EXISTS variant_id bigint,
  ADD COLUMN IF NOT EXISTS supplier_id bigint,
  ADD COLUMN IF NOT EXISTS qty int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS location text,
  ADD COLUMN IF NOT EXISTS meta_json jsonb DEFAULT '{}'::jsonb;

-- view (пересоздаётся всегда)
CREATE OR REPLACE VIEW core.v_search_index AS
SELECT v.id as variant_id, p.id as product_id, b.name as brand, p.model, c.code as category,
       v.size_label, v.load_index, v.speed_index, v.ean,
       (SELECT pr.price FROM core.prices pr WHERE pr.variant_id=v.id AND (pr.valid_to IS NULL OR pr.valid_to>now())
        ORDER BY pr.price ASC LIMIT 1) AS min_price,
       (SELECT SUM(st.qty)::INT FROM core.stocks st WHERE st.variant_id=v.id) AS total_qty
FROM core.variants v
JOIN core.products p ON p.id=v.product_id
LEFT JOIN ref.brands b ON b.id=p.brand_id
LEFT JOIN ref.categories c ON c.id=p.category_id;

GRANT USAGE ON SCHEMA ref, core TO PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA ref, core TO PUBLIC;
EOSQL

# ENV
URL="postgres://${DB_OWNER_ROLE}:${DB_OWNER_PASS}@127.0.0.1:5432/${DB_NAME}"
echo "DATABASE_URL=${URL}" > "$ENV_PATH"
chmod 600 "$ENV_PATH"
echo "[ENV] $(echo "$URL" | sed -E 's#(postgres://[^:]+:)[^@]+#***REMOVED*******#')"

log "Smoke counts"
PSQL -At -d "$DB_NAME" -c "SELECT 'brands',count(*) FROM ref.brands
UNION ALL SELECT 'products',count(*) FROM core.products
UNION ALL SELECT 'variants',count(*) FROM core.variants
UNION ALL SELECT 'prices',count(*) FROM core.prices
UNION ALL SELECT 'stocks',count(*) FROM core.stocks
ORDER BY 1;" | sed 's/^/[CNT] /'
SQL
