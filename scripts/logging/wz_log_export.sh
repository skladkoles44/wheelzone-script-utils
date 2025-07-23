#!/data/data/com.termux/files/usr/bin/bash
# WZ Log Exporter v1.1 — YAML to CSV

set -euo pipefail
IFS=$'\n\t'

LOG_YAML="$HOME/wz-wiki/logs/events.yaml"
CSV_OUT="$HOME/wz-wiki/logs/events.csv"

[ ! -f "$LOG_YAML" ] && echo "No events.yaml found" && exit 1

echo "id,timestamp,type,severity,title,message" > "$CSV_OUT"
awk '/^- id: /{id=$3}
     /timestamp: /{ts=$2}
     /type: /{ty=$2}
     /severity: /{sev=$2}
     /title: /{sub(/^ +title: "/,""); sub(/"$/,""); ti=$0}
     /message: /{sub(/^ +message: "/,""); sub(/"$/,""); msg=$0; print id "," ts "," ty "," sev ",\"" ti "\",\"" msg "\"" }
' "$LOG_YAML" >> "$CSV_OUT"

echo "[✔] Exported to $CSV_OUT"
