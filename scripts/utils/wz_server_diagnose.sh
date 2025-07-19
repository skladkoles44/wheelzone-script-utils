#!/bin/bash
# WheelZone Server Diagnostic PROD v2.1
# License: Apache-2.0

set -eo pipefail
export LC_ALL=C

### CONFIG ###
LOG_DIR="/var/log/wz_diagnostics"
MAX_LOGS=30
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CURRENT_LOG="$LOG_DIR/diag_$TIMESTAMP.log"
JSON_LOG="$LOG_DIR/diag_$TIMESTAMP.json"
LOCKFILE="/tmp/wz_diag.lock"

### INIT ###
mkdir -p "$LOG_DIR"
find "$LOG_DIR" -name "diag_*.log" -type f | sort -r | tail -n +$((MAX_LOGS+1)) | xargs rm -f --

### LOCK MECHANISM ###
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  echo "[$(date)] Diagnostic already running. Exiting." >> "$LOG_DIR/wz_diag.cron.log"
  exit 1
fi

### LOGGER FUNCTION ###
log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$CURRENT_LOG"
}

### MAIN DIAGNOSTICS ###
{
  log "=== 🚀 WHEELZONE SERVER DIAGNOSTIC STARTED ==="

  log "\n=== 🖥️ SYSTEM ==="
  log "Hostname: $(hostname -f)"
  log "OS: $(source /etc/os-release; echo "$PRETTY_NAME")"
  log "Kernel: $(uname -r) ($(uname -m))"
  log "Uptime: $(uptime -p)"
  log "Load: $(cut -d' ' -f1-3 /proc/loadavg)"

  log "\n=== 📊 RESOURCES ==="
  log "CPU: $(nproc) cores $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
  free -h | awk '/^Mem:/ {printf "Memory: %s/%s (%.1f%%)\n", $3, $2, $3/$2*100}' | log
  df -hT / | awk 'NR>1 {printf "Disk: %s (%s) %s/%s (%s)\n", $1,$2,$4,$3,$6}' | log

  log "\n=== 📦 PACKAGES ==="
  log "Manual installs:"
  comm -23 <(apt-mark showmanual | sort) <(gzip -dc /var/log/installer/initial-status.gz 2>/dev/null | sed -n 's/^Package: //p' | sort) | column | tee -a "$CURRENT_LOG"

  log "\n=== 🌐 NETWORK ==="
  ip -br addr show | grep -v "lo" | log
  log "Public IP: $(curl -4 -s ifconfig.co || echo 'N/A')"
  log "Open ports:"
  ss -tulnp | awk '{print $1,$5,$7}' | column -t | log

  log "\n=== 🔒 SECURITY ==="
  log "SUID files:"
  find / -xdev \( -path /proc -o -path /sys \) -prune -o -type f -perm -4000 -exec ls -lh {} \; 2>/dev/null | head -n 5 | log
  log "Failed logins:"
  journalctl -u sshd --since "24 hours ago" | grep "Failed" | tail -n 5 | log

  log "\n=== ⚙️ SERVICES ==="
  systemctl list-units --type=service --state=running --no-pager --no-legend | awk '{print $1}' | column | log

  log "\n=== ✅ DIAGNOSTIC COMPLETED ==="
} | tee "$CURRENT_LOG"

### JSON EXPORT ###
jq -n \
  --arg timestamp "$TIMESTAMP" \
  --arg hostname "$(hostname)" \
  --arg os "$(source /etc/os-release; echo "$PRETTY_NAME")" \
  --arg uptime "$(uptime -p)" \
  --arg load "$(cut -d' ' -f1-3 /proc/loadavg)" \
  --argjson cpu "$(nproc)" \
  --arg memory "$(free -m | awk '/^Mem:/ {print $3}')" \
  --arg disk "$(df -h / | awk 'NR>1 {print $5}')" \
  --arg ip "$(hostname -I | cut -d' ' -f1)" \
  '{timestamp: $timestamp, hostname: $hostname, os: $os, uptime: $uptime, load: $load, cpu: $cpu, memory: $memory, disk: $disk, ip: $ip}' > "$JSON_LOG"

### CLEANUP ###
flock -u 9
rm -f "$LOCKFILE"

### NOTIFICATION ###
curl -s -X POST "https://api.wheelzone.io/v1/telemetry" \
  -H "Authorization: Bearer $(cat /etc/wz/api.key)" \
  -H "Content-Type: application/json" \
  -d @"$JSON_LOG" >/dev/null 2>&1 || true
