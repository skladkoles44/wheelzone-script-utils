#!/bin/bash
# uuid: 2025-08-26T13:20:09+03:00-846525684
# title: install_shop_db (2).sh
# component: .
# updated_at: 2025-08-26T13:20:09+03:00


# === ИНИЦИАЛИЗАЦИЯ shop_db ===

echo "[+] Генерация пароля..."
DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
echo "[+] Пароль: $DB_PASSWORD"

echo "[+] Запуск mysql-скрипта..."
mysql -uroot -p"hdDBDjFXBG6UICE9" <<EOF_SQL
CREATE DATABASE IF NOT EXISTS shop_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE shop_db;

CREATE TABLE suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) GENERATED ALWAYS AS (UPPER(SUBSTRING(REPLACE(name, ' ', '_'), 1, 20))) STORED UNIQUE,
    contact_info JSON NOT NULL,
    contract_details JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX idx_supplier_active (is_active)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED;

CREATE TABLE warehouses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    location POINT SRID 4326 NOT NULL,
    address JSON NOT NULL,
    working_hours JSON,
    capacity INT,
    is_default BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE,
    SPATIAL INDEX idx_warehouse_location (location),
    UNIQUE KEY uk_supplier_warehouse (supplier_id, name)
) ENGINE=InnoDB;

CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lft INT NOT NULL,
    rgt INT NOT NULL,
    depth INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(120) NOT NULL,
    image_url VARCHAR(512),
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSON,
    UNIQUE KEY uk_category_slug (slug),
    INDEX idx_category_tree (lft, rgt, depth),
    INDEX idx_category_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(50) NOT NULL,
    barcode VARCHAR(50),
    category_id INT NOT NULL,
    brand_id INT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    specifications JSON NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_virtual BOOLEAN DEFAULT FALSE,
    tax_rate DECIMAL(5,2) DEFAULT 20.00,
    created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    fulltext_desc TEXT GENERATED ALWAYS AS (CONCAT(name, ' ', COALESCE(description, ''))) STORED,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    UNIQUE KEY uk_product_sku (sku),
    UNIQUE KEY uk_product_barcode (barcode),
    FULLTEXT INDEX ft_product_search (fulltext_desc),
    INDEX idx_product_active (is_active)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED;

CREATE TABLE inventory (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    warehouse_id INT NOT NULL,
    available_qty INT NOT NULL DEFAULT 0,
    reserved_qty INT NOT NULL DEFAULT 0,
    in_transit_qty INT NOT NULL DEFAULT 0,
    min_stock_level INT NOT NULL DEFAULT 5,
    last_restocked_at DATETIME(6),
    next_restock_at DATETIME(6),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    UNIQUE KEY uk_product_warehouse (product_id, warehouse_id),
    INDEX idx_inventory_stock (available_qty),
    INDEX idx_inventory_restock (next_restock_at)
) ENGINE=InnoDB;

CREATE TABLE pricing (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    base_price DECIMAL(12,2) NOT NULL,
    sale_price DECIMAL(12,2),
    currency CHAR(3) DEFAULT 'RUB',
    cost_price DECIMAL(12,2),
    price_changes JSON DEFAULT (JSON_ARRAY()),
    valid_from DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    valid_to DATETIME(6) DEFAULT '9999-12-31 23:59:59.999999',
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_pricing_valid (valid_from, valid_to),
    INDEX idx_pricing_active (sale_price)
) ENGINE=InnoDB;

CREATE TABLE promotions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    discount_type ENUM('percentage', 'fixed', 'bundle') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    conditions JSON NOT NULL,
    start_date DATETIME(6) NOT NULL,
    end_date DATETIME(6) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    priority INT DEFAULT 0,
    metadata JSON,
    INDEX idx_promotion_dates (start_date, end_date),
    INDEX idx_promotion_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE attribute_definitions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(120) NOT NULL,
    data_type ENUM('string', 'number', 'boolean', 'json') NOT NULL,
    is_filterable BOOLEAN DEFAULT FALSE,
    is_required BOOLEAN DEFAULT FALSE,
    validation_rules JSON,
    UNIQUE KEY uk_attribute_slug (slug)
) ENGINE=InnoDB;

CREATE TABLE product_attributes (
    product_id BIGINT NOT NULL,
    attribute_id INT NOT NULL,
    string_value VARCHAR(255),
    number_value DECIMAL(19,4),
    boolean_value BOOLEAN,
    json_value JSON,
    updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (product_id, attribute_id),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (attribute_id) REFERENCES attribute_definitions(id) ON DELETE CASCADE,
    INDEX idx_attr_string (attribute_id, string_value),
    INDEX idx_attr_number (attribute_id, number_value),
    INDEX idx_attr_boolean (attribute_id, boolean_value)
) ENGINE=InnoDB;

CREATE TABLE import_batches (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    type ENUM('products', 'prices', 'inventory') NOT NULL,
    status ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending',
    file_path VARCHAR(512),
    mappings JSON,
    stats JSON,
    started_at DATETIME(6),
    completed_at DATETIME(6),
    created_by VARCHAR(100),
    INDEX idx_import_status (status)
) ENGINE=InnoDB;

CREATE TABLE import_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    batch_id BIGINT NOT NULL,
    line_number INT NOT NULL,
    sku VARCHAR(50),
    status ENUM('success', 'warning', 'error') NOT NULL,
    message TEXT,
    data JSON,
    FOREIGN KEY (batch_id) REFERENCES import_batches(id) ON DELETE CASCADE,
    INDEX idx_import_log_batch (batch_id, status)
) ENGINE=InnoDB;

CREATE TABLE audit_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL,
    changed_by VARCHAR(100),
    old_values JSON,
    new_values JSON,
    changed_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_audit_entity (entity_type, entity_id),
    INDEX idx_audit_time (changed_at)
) ENGINE=InnoDB;

CREATE TABLE cache_store (
    cache_key VARCHAR(255) PRIMARY KEY,
    cache_value LONGTEXT NOT NULL,
    expires_at DATETIME(6) NOT NULL,
    tags JSON,
    INDEX idx_cache_expiry (expires_at)
) ENGINE=InnoDB;

CREATE TABLE schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    applied_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
    checksum VARCHAR(64),
    execution_time_ms INT
) ENGINE=InnoDB;

CREATE USER 'shop_app'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON shop_db.* TO 'shop_app'@'%';
FLUSH PRIVILEGES;
EOF_SQL

echo "[✓] База данных shop_db создана. Пароль пользователя shop_app: $DB_PASSWORD"
