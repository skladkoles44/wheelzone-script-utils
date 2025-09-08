#!/usr/bin/env bash
# WheelZone :: Host Deep Check (multi-host, preconfigured)
# Version: 1.5.0
# Logs -> /storage/emulated/0/Download/project_44/Logs
set -Eeuo pipefail
IFS=$'\n\t'

# ====== НАСТРОЙКИ (жёстко прописаны) ======
HOSTS=("89.111.171.170" "79.174.85.106")   # два сервера
PORTS_CSV="22,2222,2223"                   # порты для проверки
SSH_USER="root"                             # пользователь для ssh-проверок
TIMEOUT=5                                   # таймаут на подключение (сек)
# ==========================================

VERBOSE=0
DO_REMOTE=0

while getopts "vr" opt; do
  case "$opt" in
    v) VERBOSE=1 ;;
    r) DO_REMOTE=1 ;;
  esac
done

TS_GLOBAL="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="/storage/emulated/0/Download/project_44/Logs"
mkdir -p "$LOG_DIR"
SUMMARY_LOG="$LOG_DIR/wz_check_summary_${TS_GLOBAL}.log"

say(){ printf '%s %s\n' "$1" "$2" | tee -a "$LOG"; }
hdr(){ printf '==[ %s ]== %s\n' "$1" "$2" | tee -a "$LOG"; }
say_sum(){ printf '%s %s\n' "$1" "$2" | tee -a "$SUMMARY_LOG"; }
run(){
  if [[ $VERBOSE -eq 1 ]]; then
    echo "+ $*" | tee -a "$LOG"
  fi
  ( eval "$@" ) 2>&1 | tee -a "$LOG"
}
have(){ command -v "$1" >/dev/null 2>&1; }
tcp_probe_nc(){ nc -z -w "$TIMEOUT" "$1" "$2"; }
tcp_probe_bash(){ (exec 3<>"/dev/tcp/$1/$2") >/dev/null 2>&1; }
ssh_exec(){
  local host="$1" port="$2" cmd="$3"
  ssh -p "$port" -o BatchMode=yes -o ConnectTimeout="$TIMEOUT" \
      -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null \
      "$SSH_USER@$host" "$cmd"
}

say_sum "[TARGETS]" "hosts=${HOSTS[*]} ports=${PORTS_CSV} user=${SSH_USER} timeout=${TIMEOUT}s remote=${DO_REMOTE} verbose=${VERBOSE}"
say_sum "[SUMMARY_LOG]" "$SUMMARY_LOG"

IFS=',' read -r -a PORTS <<<"$PORTS_CSV"

for HOST in "${HOSTS[@]}"; do
  SAN_HOST="${HOST//[^A-Za-z0-9_.-]/_}"
  TS="$(date +%Y%m%d_%H%M%S)"
  LOG="$LOG_DIR/wz_check_${SAN_HOST}_${TS}.log"
  echo "" >>"$SUMMARY_LOG"
  say_sum "==[ HOST ]==" "$HOST  (log: $LOG)"

  printf '==[ TARGET ]== HOST=%s PORTS=%s USER=%s TIMEOUT=%ss REMOTE=%s VERBOSE=%s\n' \
    "$HOST" "$PORTS_CSV" "$SSH_USER" "$TIMEOUT" "$DO_REMOTE" "$VERBOSE" | tee -a "$LOG"
  printf '[LOG] %s\n' "$LOG" | tee -a "$LOG"

  # PING
  printf '==[ PING ]== ICMP\n' | tee -a "$LOG"
  if have ping; then
    if ping -c 2 -W "$TIMEOUT" "$HOST" >/dev/null 2>&1; then
      echo "[OK] ping reachable" | tee -a "$LOG" | tee -a "$SUMMARY_LOG" >/dev/null
    else
      echo "[WARN] ping failed" | tee -a "$LOG" | tee -a "$SUMMARY_LOG" >/dev/null
    fi
    ping -c 4 -W "$TIMEOUT" "$HOST" 2>&1 | tee -a "$LOG" >/dev/null || true
  else
    echo "[WARN] ping not found" | tee -a "$LOG"
  fi

  # PORTS
  printf '==[ PORTS ]== TCP probe\n' | tee -a "$LOG"
  REACHABLE_PORT=""
  for P in "${PORTS[@]}"; do
    P="${P//[[:space:]]/}"
    [[ -z "$P" ]] && continue
    RESULT=""
    if have nc; then
      if tcp_probe_nc "$HOST" "$P"; then RESULT="OPEN(nc)"; else RESULT="CLOSED(nc)"; fi
    fi
    if [[ "$RESULT" != OPEN* ]]; then
      if tcp_probe_bash "$HOST" "$P"; then RESULT="OPEN(/dev/tcp)"; else RESULT="${RESULT:-CLOSED(/dev/tcp)}"; fi
    fi
    printf '[%s] tcp/%s %s\n' "$HOST" "$P" "$RESULT" | tee -a "$LOG"
    if [[ "$RESULT" == OPEN* && -z "$REACHABLE_PORT" ]]; then REACHABLE_PORT="$P"; fi
  done
  if [[ -n "$REACHABLE_PORT" ]]; then
    say_sum "[PORT]" "$HOST first open: tcp/$REACHABLE_PORT"
  else
    say_sum "[PORT]" "$HOST no open ports among: $PORTS_CSV"
  fi

  # REMOTE
  if [[ $DO_REMOTE -eq 1 && -n "$REACHABLE_PORT" ]]; then
    printf '==[ REMOTE ]== SSH deep checks via tcp/%s\n' "$REACHABLE_PORT" | tee -a "$LOG"
    ssh_exec "$HOST" "$REACHABLE_PORT" 'whoami; uname -a || true' 2>&1 | tee -a "$LOG" || true

    printf '==[ REMOTE ]== listening sockets\n' | tee -a "$LOG"
    ssh_exec "$HOST" "$REACHABLE_PORT" "command -v ss >/dev/null 2>&1 && ss -ltnp || (command -v netstat >/dev/null 2>&1 && netstat -ltnp) || echo 'no ss/netstat'" 2>&1 | tee -a "$LOG" || true

    printf '==[ REMOTE ]== sshd status\n' | tee -a "$LOG"
    ssh_exec "$HOST" "$REACHABLE_PORT" "(command -v systemctl >/dev/null 2>&1 && systemctl status ssh sshd --no-pager 2>/dev/null) || ps -ef | grep -i '[s]shd' || echo 'no systemd'" 2>&1 | tee -a "$LOG" || true

    printf '==[ REMOTE ]== firewall snapshot\n' | tee -a "$LOG"
    ssh_exec "$HOST" "$REACHABLE_PORT" "(command -v ufw >/dev/null 2>&1 && ufw status || true); (command -v iptables >/dev/null 2>&1 && iptables -S | sed -n '1,120p' || true); (command -v nft >/dev/null 2>&1 && nft list ruleset 2>/dev/null | sed -n '1,200p' || true)" 2>&1 | tee -a "$LOG" || true

    printf '==[ REMOTE ]== auth logs tail\n' | tee -a "$LOG"
    ssh_exec "$HOST" "$REACHABLE_PORT" "(test -f /var/log/auth.log && tail -n 50 /var/log/auth.log) || (journalctl -u ssh -n 50 --no-pager 2>/dev/null) || echo 'no auth log access'" 2>&1 | tee -a "$LOG" || true
  fi

  printf '==[ DONE ]== saved: %s\n' "$LOG" | tee -a "$LOG"
done

echo "==[ SUMMARY DONE ]== $(date +%F' '%T)  file: $SUMMARY_LOG"
exit 0
