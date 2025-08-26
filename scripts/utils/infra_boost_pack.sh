#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:36+03:00-3062199524
# title: infra_boost_pack.sh
# component: .
# updated_at: 2025-08-26T13:19:36+03:00

# WheelZone Infra Boost Pack v1.6.3 (Production-Grade)
# License: Apache 2.0

set -euo pipefail
IFS=$'\n\t'
shopt -s nullglob dotglob

# ==================== CONFIGURATION ====================
: "${TMPDIR:=/data/data/com.termux/files/usr/tmp}"
: "${LOCK_TIMEOUT:=300}"
: "${CMD_TIMEOUT:=600}"
: "${MAX_LOG_SIZE:=10485760}"  # 10MB
: "${MAX_LOG_FILES:=5}"

readonly VERSION="1.6.3"
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR=$(dirname "$(realpath -m "$0")")
readonly LOG_DIR="$HOME/wzbuffer/logs"
readonly LOGFILE="$LOG_DIR/${SCRIPT_NAME%.*}.log"
readonly REPO_DIR="$HOME/wz-wiki"
readonly LOCKFILE="$TMPDIR/${SCRIPT_NAME}.lock"
readonly PIDFILE="$TMPDIR/${SCRIPT_NAME}.pid"
readonly CONFIG_FILE="$HOME/.config/wzbootstrap.conf"

# Security
readonly EXPECTED_SHA256="put-your-sha-here"
readonly REQUIRED_UMASK=0027
readonly ALLOWED_ROOT_CMDS=("git" "tmux" "flock")

# ==================== INITIALIZATION ====================
mkdir -p "$LOG_DIR" "$TMPDIR" || {
  echo "❌ Failed to create required directories" >&2
  exit 1
}

exec > >(tee -a "$LOGFILE") 2>&1

rotate_logs() {
  if [[ -f "$LOGFILE" && $(stat -c %s "$LOGFILE") -gt $MAX_LOG_SIZE ]]; then
    for i in $(seq "$MAX_LOG_FILES" -1 1); do
      [[ -f "${LOGFILE}.${i}" ]] && mv "${LOGFILE}.${i}" "${LOGFILE}.$((i+1))"
    done
    mv "$LOGFILE" "${LOGFILE}.1"
  fi
}

# ==================== SECURITY CHECKS ====================
validate_environment() {
  local actual_sha
  actual_sha=$(sha256sum "$0" | awk '{print $1}')
  if [[ "$EXPECTED_SHA256" != "$actual_sha" ]]; then
    echo "❌ Script integrity check failed!" >&2
    exit 1
  fi

  if [[ $(id -u) -eq 0 ]]; then
    echo "⚠️ Running as root - restricting execution scope" >&2
    readonly RESTRICT_ROOT=true
  else
    readonly RESTRICT_ROOT=false
  fi

  umask "$REQUIRED_UMASK" || {
    echo "❌ Failed to set secure umask" >&2
    exit 1
  }
}

# ==================== LOCKING MECHANISM ====================
acquire_lock() {
  local lock_acquired=false

  if command -v flock >/dev/null; then
    exec {LOCKFD}>"$LOCKFILE" || return 1
    if flock -w "$LOCK_TIMEOUT" -n "$LOCKFD"; then
      lock_acquired=true
    fi
  else
    if [[ ! -e "$LOCKFILE" ]] && ( set -o noclobber; echo $$ > "$LOCKFILE" ) 2>/dev/null; then
      lock_acquired=true
      trap 'rm -f "$LOCKFILE"; exit' EXIT
    elif [[ -e "$LOCKFILE" ]]; then
      if kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
        echo "🔒 Script already running (PID $(cat "$LOCKFILE"))" >&2
        exit 1
      else
        echo "⚠️ Removing stale lockfile" >&2
        rm -f "$LOCKFILE"
        echo $$ > "$LOCKFILE"
        trap 'rm -f "$LOCKFILE"; exit' EXIT
        lock_acquired=true
      fi
    fi
  fi

  if ! $lock_acquired; then
    echo "❌ Failed to acquire lock after $LOCK_TIMEOUT seconds" >&2
    exit 1
  fi

  echo $$ > "$PIDFILE"
}

# ==================== LOGGING SYSTEM ====================
log() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
  echo "[$timestamp] [$level] $message"
}

# ==================== COMMAND EXECUTION ====================
safe_exec() {
  local cmd=("$@")
  local attempt=0
  local max_attempts=3
  local delay=5
  local exit_code=0

  if $DRY_RUN; then
    log "INFO" "[DRY-RUN] ${cmd[*]}"
    return 0
  fi

  if $RESTRICT_ROOT && [[ $(id -u) -eq 0 ]]; then
    local cmd_base
    cmd_base=$(basename "${cmd[0]}")
    if ! printf '%s\n' "${ALLOWED_ROOT_CMDS[@]}" | grep -q "^${cmd_base}$"; then
      log "ERROR" "Root execution denied for: ${cmd[*]}"
      return 1
    fi
  fi

  log "DEBUG" "Executing: ${cmd[*]}"
  
  while (( attempt < max_attempts )); do
    (( attempt++ ))
    if timeout "$CMD_TIMEOUT" "${cmd[@]}"; then
      log "INFO" "✅ Success: ${cmd[*]}"
      return 0
    else
      exit_code=$?
      log "WARN" "Attempt $attempt failed: ${cmd[*]} (code $exit_code)"
      sleep "$delay"
    fi
  done

  log "ERROR" "❌ Command failed: ${cmd[*]}"
  return "$exit_code"
}

# ==================== GIT OPERATIONS ====================
has_git_changes() {
  git status --porcelain | grep -q .
}

git_safe_push() {
  local force_push="${1:-false}"
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  local remote="origin"

  if $force_push && [[ "$branch" == "main" || "$branch" == "master" ]]; then
    read -t 30 -p "⚠️ Force push to $branch? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || return 1
    safe_exec git push --force-with-lease "$remote" "$branch"
  else
    safe_exec git push "$remote" "$branch"
  fi
}

# ==================== MAIN LOGIC ====================
main() {
  rotate_logs
  validate_environment
  acquire_lock

  log "INFO" "🚀 Starting $SCRIPT_NAME v$VERSION"
  log "INFO" "Environment: $(uname -a)"
  log "INFO" "User: $(id)"
  log "INFO" "Args: $*"

  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

  if $REPAIR_MODE; then
    log "INFO" "🔧 Repair mode active"
    safe_exec git reset --hard HEAD
    safe_exec git clean -fd
  fi

  if has_git_changes; then
    safe_exec git add -A
    safe_exec git commit -m "Auto update by $SCRIPT_NAME"
    git_safe_push "$FORCE_PUSH"
  else
    log "INFO" "🟢 No changes to commit"
  fi

  if $RUN_CHATEND && [[ -x "$CHATEND_SCRIPT" ]]; then
    log "INFO" "▶️ Running ChatEnd script"
    safe_exec "$CHATEND_SCRIPT"
  fi

  log "INFO" "✅ Completed successfully"
}

# ==================== ARGUMENT PARSING ====================
declare DRY_RUN=false
declare SILENT=false
declare REPAIR_MODE=false
declare RUN_CHATEND=false
declare FORCE_PUSH=false
declare DEBUG=false
readonly CHATEND_SCRIPT="$HOME/wheelzone-script-utils/scripts/ci/wz_chatend.sh"

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      --silent) SILENT=true ;;
      --repair) REPAIR_MODE=true ;;
      --run-chatend) RUN_CHATEND=true ;;
      --force-push) FORCE_PUSH=true ;;
      --debug) DEBUG=true ;;
      --version) echo "$VERSION"; exit 0 ;;
      *) log "ERROR" "Unknown argument: $1"; exit 1 ;;
    esac
    shift
  done
}

parse_args "$@"
main "$@"

exit 0
