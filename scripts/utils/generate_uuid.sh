#!/data/data/com.termux/files/usr/bin/bash
# generate_uuid.sh v4.2.0 — WZ Unified UUID Generator (Fractal-Safe)

set -eo pipefail
shopt -s nocasematch

VERSION="4.2.0"
DEFAULT_FORMAT="fractal"
SCRIPT_NAME="${0##*/}"

log() { echo -e "\033[1;32m[+]\033[0m $1"; }
err() { echo -e "\033[1;31m[ERR]\033[0m $1" >&2; exit 1; }
warn() { echo -e "\033[1;33m[!]\033[0m $1"; }

usage() {
  cat <<EOF
$SCRIPT_NAME v$VERSION — Генератор UUID + slug для WheelZone (Fractal-safe)

Usage:
  $SCRIPT_NAME                  # UUID + slug auto
  $SCRIPT_NAME --slug foo-bar  # Только slug (валидируется)
  $SCRIPT_NAME --help          # Показать справку
  $SCRIPT_NAME --version       # Версия

Slug правила:
  - Только строчные буквы, цифры и дефисы (a-z0-9-)
  - Без пробелов, подчёркиваний, спецсимволов
