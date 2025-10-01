#!/usr/bin/env bash
# WZ Artifact: wz_ports_audit.sh
# WZ-Fractal-UUID: TBD
# WZ-Registry-Link: wz-wiki/registry/ports_map.yaml
# Role: One-shot аудит конфликтов портов по карте ~/wzbuffer/ports_map.yaml и последнему снапшоту.
# Exit codes: 0=OK/only WARN, 1=ERR detected, 2=missing map, 3=no ss

set -euo pipefail

# ===== JSON logger =====
log_ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
j() { printf '%s\t{"lvl":"%s","msg":%s%s}\n' "$(log_ts)" "$1" "$2" "${3:-}"; }
info(){ j INFO  "$1" "$2"; }
warn(){ j WARN  "$1" "$2"; }
err(){  j ERROR "$1" "$2"; }

# ===== Args / Env =====
NODE="${1:-${WZ_NODE:-}}"
MAP_FILE="${WZ_MAP_FILE:-$HOME/wzbuffer/ports_map.yaml}"
SNAP_DIR="${WZ_SNAP_DIR:-$HOME/wzbuffer/ports_snapshots}"

# ===== Helpers =====
trim(){ sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//'; }

is_public_bind() {
  # 0.0.0.0:PORT или [::]:PORT
  case "$1" in
    0.0.0.0:*) return 0 ;;
    "[::]:"*)  return 0 ;;
    *)         return 1 ;;
  esac
}
is_local_bind() {
  # 127.0.0.1:PORT или [::1]:PORT
  case "$1" in
    127.0.0.1:*) return 0 ;;
    "[::1]:"*)   return 0 ;;
    *)           return 1 ;;
  esac
}

# Узел
if [[ -z "$NODE" ]]; then
  HN="$({ command -v hostname >/dev/null 2>&1 && hostname; } || uname -n)"
  case "$HN" in
    *vps2*|*holm*) NODE="vps2" ;;
    *xbc*|*cream*) NODE="xbc" ;;
    *termux*|*android*) NODE="termux" ;;
    * ) NODE="vps2" ;;
  esac
  warn "\"node not specified; heuristic applied\"" ",\"node\":\"$NODE\",\"hostname\":\"$HN\""
else
  info "\"node provided\"" ",\"node\":\"$NODE\""
fi

# Предусловия
if [[ ! -f "$MAP_FILE" ]]; then err "\"ports_map.yaml not found\"" ",\"path\":\"$MAP_FILE\""; exit 2; fi
if ! command -v ss >/dev/null 2>&1; then err "\"ss not found (install iproute2)\"" ""; exit 3; fi

# reserved ranges: "LO-HI"
readarray -t RESERVED < <(awk '
  BEGIN{in=0}
  /^policy:/ {in=1; next}
  in==1 && /^\s*reserved_ranges:/ {in=2; next}
  in==2 {
    if ($0 ~ /^\S/ && $0 !~ /^-/) exit
    if ($0 ~ /- range:/) { gsub(/"/,""); sub(/.*range:\s*/,""); print }
  }' "$MAP_FILE" | trim)

# services: name|on_node|port|exposed
readarray -t SERVICES < <(awk '
  BEGIN{in=0; name=node=port=exp=""}
  /^services:/ {in=1; next}
  in==1 {
    if ($0 ~ /^[^[:space:]]/ && $0 !~ /^-/) exit
    if ($0 ~ /^\s*-\s*name:/) {
      if (name!="") printf("%s|%s|%s|%s\n",name,node,port,exp)
      name=node=port=exp=""
      t=$0; sub(/.*name:\s*/,"",t); gsub(/"/,"",t); name=t
    } else if ($0 ~ /^\s*on_node:/) { t=$0; sub(/.*on_node:\s*/,"",t); gsub(/"/,"",t); node=t }
      else if ($0 ~ /^\s*port:/)   { t=$0; sub(/.*port:\s*/,"",t); gsub(/"/,"",t); port=t }
      else if ($0 ~ /^\s*exposed:/){ t=$0; sub(/.*exposed:\s*/,"",t); gsub(/"/,"",t); exp=t }
  }
  END{ if (name!="") printf("%s|%s|%s|%s\n",name,node,port,exp) }' "$MAP_FILE" | trim)

# last snapshot path (optional)
SNAP_FILE_REL="$(awk '
  /^last_snapshot:/ {in=1; next}
  in==1 && /^\s*file:/ { gsub(/"/,""); sub(/.*file:\s*/,""); print; exit }' "$MAP_FILE" | trim)"
SNAP_PATH="$SNAP_DIR/$SNAP_FILE_REL"

# open ports from snapshot (preferred)
OPEN_FROM_SNAP=()
if [[ -f "$SNAP_PATH" ]]; then
  while IFS= read -r line; do OPEN_FROM_SNAP+=("$line"); done < <(awk '
    BEGIN{in=0; p=b=e=""}
    /^open_ports:/ {in=1; next}
    in==1 {
      if ($0 ~ /^[^[:space:]]/ && $0 !~ /^-/) exit
      if ($0 ~ /- port:/) { t=$0; sub(/.*port:\s*/,"",t); gsub(/"/,"",t); p=t }
      else if ($0 ~ /^\s*bind:/) { t=$0; sub(/.*bind:\s*/,"",t); gsub(/"/,"",t); b=t }
      else if ($0 ~ /^\s*exposed_guess:/) { t=$0; sub(/.*exposed_guess:\s*/,"",t); gsub(/"/,"",t); e=t; printf("%s|%s|%s\n",p,b,e); p=b=e="" }
    }' "$SNAP_PATH" | trim)
fi

# live ports fallback
readarray -t OPEN_LIVE < <(
  ss -ltnp 2>/dev/null \
    | awk 'NR>1 {print $4}' \
    | sed -E 's/.*:([0-9]+)$/***REMOVED***|\0/' \
    | awk -F"|" '{port=$1; bind=$2;
                  exp="private_or_specific";
                  if (bind ~ /(^|\[)::1\]?:/ || bind ~ /127\.0\.0\.1:/) exp="localhost";
                  else if (bind ~ /(^|\[)::\]?:/ || bind ~ /0\.0\.0\.0:/) exp="public_or_all";
                  print port "|" bind "|" exp; }' \
    | sort -u
)

OPEN_PORTS=("${OPEN_FROM_SNAP[@]:-${OPEN_LIVE[@]}}")
if [[ ${#OPEN_FROM_SNAP[@]} -gt 0 ]]; then info "\"using snapshot ports\"" ",\"file\":\"$SNAP_PATH\""; else info "\"using live ports\"" ""; fi

# maps
declare -A SVC_PORT_TO_META OPEN_PORT_TO_META
declare -i ERR=0 WARN=0

# индексируем declared сервисы текущего узла
for s in "${SERVICES[@]}"; do
  IFS='|' read -r nm nd pt ex <<<"$s"
  [[ "$nd" != "$NODE" ]] && continue
  [[ "$pt" =~ ^[0-9]+$ ]] || continue
  if [[ -n "${SVC_PORT_TO_META[$pt]+x}" ]]; then
    err "\"duplicate service port on node\"" ",\"node\":\"$NODE\",\"port\":$pt,\"existing\":\"${SVC_PORT_TO_META[$pt]}\",\"new\":\"$nm\""; ERR+=1
  else
    SVC_PORT_TO_META[$pt]="${nm}|${ex}"
  fi
done

# reserved ranges → массив "lo-hi"
RANGES=()
for r in "${RESERVED[@]}"; do
  rg="$(echo "$r" | tr -d '"' | trim)"
  [[ "$rg" =~ ^[0-9]+-[0-9]+$ ]] && RANGES+=("$rg")
done

# индекс открытых портов
for o in "${OPEN_PORTS[@]}"; do
  IFS='|' read -r p b e <<<"$o"
  [[ "$p" =~ ^[0-9]+$ ]] || continue
  OPEN_PORT_TO_META["$p"]="$b|$e"
done

# 2) reserved occupied by unknown
for p in "${!OPEN_PORT_TO_META[@]}"; do
  inr=0; rg_hit=""
  for rg in "${RANGES[@]}"; do
    lo="${rg%-*}"; hi="${rg#*-}"
    if (( p>=lo && p<=hi )); then inr=1; rg_hit="$rg"; break; fi
  done
  if (( inr==1 )) && [[ -z "${SVC_PORT_TO_META[$p]+x}" ]]; then
    IFS='|' read -r bind exp <<<"${OPEN_PORT_TO_META[$p]}"
    err "\"reserved range occupied by unknown listener\"" \
        ",\"node\":\"$NODE\",\"port\":$p,\"bind\":\"$bind\",\"guess\":\"$exp\",\"range\":\"$rg_hit\""
    ERR+=1
  fi
done

# 3/4/5) exposure mismatches + declared-but-not-listening
for pt in "${!SVC_PORT_TO_META[@]}"; do
  be="${OPEN_PORT_TO_META[$pt]:-}"
  IFS='|' read -r svc_name svc_exp <<<"${SVC_PORT_TO_META[$pt]}"
  if [[ -z "$be" ]]; then
    warn "\"declared port not listening\"" ",\"node\":\"$NODE\",\"port\":$pt,\"service\":\"$svc_name\""; WARN+=1; continue
  fi
  IFS='|' read -r bind _guess <<<"$be"

  # нормализуем ожидание
  exp_norm="private"; case "$svc_exp" in public) exp_norm="public";; localhost) exp_norm="localhost";; esac

  if is_public_bind "$bind" && [[ "$exp_norm" != "public" ]]; then
    err "\"public bind but declared non-public\"" ",\"node\":\"$NODE\",\"port\":$pt,\"service\":\"$svc_name\",\"declared\":\"$svc_exp\",\"bind\":\"$bind\""
    ERR+=1
  fi
  if is_local_bind "$bind" && [[ "$exp_norm" == "public" ]]; then
    warn "\"localhost bind but declared public\"" ",\"node\":\"$NODE\",\"port\":$pt,\"service\":\"$svc_name\",\"bind\":\"$bind\""
    WARN+=1
  fi
done

info "\"summary\"" ",\"node\":\"$NODE\",\"errors\":$ERR,\"warnings\":$WARN,\"services_checked\":${#SVC_PORT_TO_META[@]},\"open_ports_seen\":${#OPEN_PORT_TO_META[@]}"
(( ERR>0 )) && exit 1 || exit 0
