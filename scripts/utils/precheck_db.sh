#!/usr/bin/env bash
set -Eeuo pipefail

# VPS параметры (перепиши через env при нужде)
VPS_HOST="${VPS_HOST:-79.174.85.106}"
VPS_PORT="${VPS_PORT:-2222}"

# раскраска
_G=$'\033[1;92m'; _Y=$'\033[1;93m'; _R=$'\033[1;91m'; _Z=$'\033[0m'
say(){  printf "%s==[ %s ]==%s\n" "$_G" "$*" "$_Z"; }
ok(){   printf "%s[OK]%s %s\n"    "$_G" "$_Z" "$*"; }
warn(){ printf "%s[WARN]%s %s\n"  "$_Y" "$_Z" "$*"; }
err(){  printf "%s[ERR]%s %s\n"   "$_R" "$_Z" "$*"; }

FAIL=0

ssh -p "${VPS_PORT}" "root@${VPS_HOST}" bash -se <<'REMOTE'
set -Eeuo pipefail
_G=$'\033[1;92m'; _Y=$'\033[1;93m'; _R=$'\033[1;91m'; _Z=$'\033[0m'
say(){  printf "%s==[ %s ]==%s\n" "$_G" "$*" "$_Z"; }
ok(){   printf "%s[OK]%s %s\n"    "$_G" "$_Z" "$*"; }
warn(){ printf "%s[WARN]%s %s\n"  "$_Y" "$_Z" "$*"; }
err(){  printf "%s[ERR]%s %s\n"   "$_R" "$_Z" "$*"; }

FAIL=0

say "PostgreSQL presence/version"
if command -v psql >/dev/null 2>&1; then
  v="$(psql -V | head -n1)"
  ok "$v"
else
  warn "psql not found (будет установлен инсталлером)"
fi

say "Port 5432 (should be loopback or free)"
if ss -ltnp '( sport = :5432 )' 2>/dev/null | grep -q LISTEN; then
  ss -ltnp '( sport = :5432 )' || true
  ok "5432 is listening"
else
  ok "5432 is free"
fi

say "Disk space (/ and /var/lib/postgresql)"
df -h / /var/lib/postgresql 2>/dev/null | sed -n '1,3p' || true

say "pg_hba.conf (path preview)"
if command -v psql >/dev/null 2>&1; then
  HBA="$(sudo -u postgres psql -Atqc "SHOW hba_file;" 2>/dev/null || true)"
  if [ -n "$HBA" ] && [ -r "$HBA" ]; then
    ok "hba_file: $HBA"
    head -n 8 "$HBA" || true
  else
    warn "cannot read hba_file (это не блокер, инсталлер добавит 127.0.0.1)"
  fi
else
  warn "psql отсутствует — пропускаю hba preview"
fi

say "Snapshot /etc/postgresql (config backup)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
if [ -d /etc/postgresql ]; then
  tar -C /etc -czf "/root/pgconf-${TS}.tgz" postgresql
  ls -l "/root/pgconf-${TS}.tgz"
  ok "snapshot created"
else
  warn "/etc/postgresql not found — возможно Postgres не установлен"
fi

exit "$FAIL"
REMOTE

# ретранслируем код выхода из ssh
exit $?
