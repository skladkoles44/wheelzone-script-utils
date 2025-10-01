#!/data/data/com.termux/files/usr/bin/bash
# WZ Artifact Header v1.0
# Registry: wheelzone://cli/profiles/dump/v0.1.0
# Fractal-UUID: PENDING-UUID
# Task-Class: idempotent
# Version: v0.1.0
# Owner: WheelZone
# Maintainer: WheelZone
# Created-At: 2025-09-25T00:00:00Z
# Updated-At: 2025-09-25T00:00:00Z
# Inputs: ~/.bashrc, ~/.profile, $PREFIX/etc/profile, *rc.d/*
# Outputs: ~/wzbuffer/logs/wz_shell_profiles_*.log, clipboard
# Side-Effects: чтение файлов rc
# Idempotency: Yes; State-Markers: отсутствуют
# Run-Mode: apply
# SLO/SLA: n/a; Observability: лог-файл
# Rollback: удалить сгенерированные логи
# Compatibility: Termux Bash/Zsh
# Integrity-Hash: auto

set -Eeuo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOGDIR="$HOME/wzbuffer/logs"
OUT="$LOGDIR/wz_shell_profiles_${TS}.log"
mkdir -p "$LOGDIR"

# Маскировка секретов (редакция чувствительных значений)
sanitize() {
  sed -E \
    -e 's/((AWS|GCP|AZURE|API|BEARER|PRIVATE|SECRET|TOKEN|KEY|PASS(WORD)?|COOKIE)[A-Z0-9_]*\s*[:=]\s*)([^#\r\n]+)/***REMOVED******REDACTED***/Ig' \
    -e 's/(Authorization\s*:\s*)([Bb]earer\s+[A-Za-z0-9._-]+)/***REMOVED******REDACTED***/g' \
    -e 's/(ssh-[rd]sa\s+)[A-Za-z0-9+\/=]+/***REMOVED******REDACTED***/g'
}

RAW=0
if [[ "${1:-}" == "--raw" ]]; then RAW=1; fi

# Набор файлов и папок профилей (профили запуска)
mapfile -t CANDIDATES <<EOF_FILES
$HOME/.bashrc
$HOME/.bash_profile
$HOME/.bash_login
$HOME/.profile
$HOME/.zshrc
$HOME/.mkshrc
$HOME/.config/fish/config.fish
$PREFIX/etc/profile
$PREFIX/etc/bash.bashrc
$PREFIX/etc/motd
$HOME/.termux/termux.properties
EOF_FILES

# Папки с включаемыми кусками (include-директории)
DIRS=(
  "$HOME/.bashrc.d"
  "$HOME/.bash_profile.d"
  "$HOME/.profile.d"
  "$PREFIX/etc/profile.d"
)

{
  echo "=== WheelZone: Shell Profiles Snapshot ==="
  echo "Timestamp (UTC): $TS"
  echo "Host: $(uname -a)"
  echo

  list_files() {
    local p="$1"
    if [[ -d "$p" ]]; then
      find "$p" -type f -maxdepth 1 2>/dev/null | LC_ALL=C sort
    elif [[ -f "$p" ]]; then
      printf "%s\n" "$p"
    fi
  }

  # Сводный список существующих файлов
  echo "== Files detected =="
  ALL=()
  for f in "${CANDIDATES[@]}"; do
    if [[ -f "$f" ]]; then
      ALL+=("$f")
      echo "$f"
    fi
  done
  for d in "${DIRS[@]}"; do
    if [[ -d "$d" ]]; then
      while IFS= read -r f; do
        ALL+=("$f")
        echo "$f"
      done < <(list_files "$d")
    fi
  done
  echo

  # Выгрузка содержимого с хешами
  for f in "${ALL[@]}"; do
    echo "-----8<----- FILE: $f -----"
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$f" | sed 's/^/SHA256: /'
    fi
    echo "SIZE: $(wc -c <"$f" 2>/dev/null || echo 0) bytes"
    echo "--- CONTENT START ---"
    if [[ "$RAW" -eq 1 ]]; then
      cat "$f"
    else
      sanitize < "$f"
    fi
    echo "--- CONTENT END ---"
    echo "-----8<----- END FILE: $f -----"
    echo
  done

} | tee "$OUT"

# Копирование в системный буфер обмена (клипборд)
if command -v termux-clipboard-set >/dev/null 2>&1; then
  termux-clipboard-set < "$OUT" || true
  echo "== Clipboard: copied via termux-clipboard-set =="
else
  echo "!! termux-clipboard-set не найден (termux-api не установлен). Установи: pkg install termux-api"
fi

echo "== Log saved: $OUT =="
