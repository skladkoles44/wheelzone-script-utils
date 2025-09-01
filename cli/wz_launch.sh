#!/usr/bin/env bash
set -Eeuo pipefail

SSH_OPTS="-o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new"

echo "=== WheelZone :: Launch Mode ==="
echo "[2] vps2   (root@79.174.85.106:2222)  # Sapphire Holmium"
echo "[C] cream  (root@89.104.66.210:2222)"
echo "[L] Local (default)"
echo "[Q] Quit"
read -r -t 5 -p "Select in 5s > " choice || choice="L"

case "$choice" in
  2|vps2|VPS2)
    echo "[WZ] Connecting to vps2 (Sapphire Holmium)..."
    exec ssh $SSH_OPTS -p 2222 root@79.174.85.106
    ;;
  C|c|cream|CREAM)
    echo "[WZ] Connecting to cream..."
    exec ssh $SSH_OPTS -p 2222 root@89.104.66.210
    ;;
  L|l)
    echo "[WZ] Staying local."
    ;;
  Q|q)
    echo "[WZ] Quit."
    ;;
  *)
    echo "[WZ] Unknown choice → staying local."
    ;;
esac
