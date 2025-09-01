#!/usr/bin/env bash
# title: WZ :: Startup Audit (Termux)
# version: 1.1.0
# desc: Снимок того, что уже подключается на старте Termux + трассировка старта bash
set -Eeuo pipefail; IFS=$'\n\t'

say(){ printf "[WZ] %s\n" "$*"; }
hr(){ printf -- "────────────────────────────────────────────────────────\n"; }

TS="$(date +%Y%m%d_%H%M%S)"
OUTDIR="${1:-$HOME/wzbuffer/startup_audit/$TS}"
mkdir -p "$OUTDIR"

FILES=(
  "$HOME/.bashrc"
  "$HOME/.profile"
  "$HOME/.bash_profile"
  "$HOME/.zshrc"
  "$HOME/.zprofile"
)

say "Startup Audit → $OUTDIR"
hr
say "SHELL: ${SHELL:-unknown} | TERMUX: ${PREFIX:-unset}"

# Снимок файлов
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    sz=$(wc -c <"$f" || echo 0)
    mt=$(date -r "$f" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "n/a")
    say "FOUND: ${f##$HOME/} | size=${sz}B | mtime=$mt"
    # Метки и ключевые вставки
    {
      echo "# === ${f} ==="
      echo "## grep: ключевые маркеры"
      (grep -nE 'WZ|wz_.*\.sh|gpt_push_memorylog\.sh|wz_sync_push_daemon\.sh' "$f" || true)
      echo
      echo "## HEAD (первые 20 строк)"
      sed -n '1,20p' "$f"
      echo
      echo "## TAIL (последние 20 строк)"
      tac "$f" | sed -n '1,20p' | tac
      echo
    } >> "$OUTDIR/filesnap.txt"
  else
    say "MISS : ${f##$HOME/} (нет файла)"
  fi
done
hr

# Быстрая оценка: что именно подключается в текущей интерактивной сессии bash
# Трассировка отдельного интерактивного старта:
TRACE="$OUTDIR/bash_trace.log"
say "Tracing interactive bash startup → $TRACE"
# -i (interactive), -x (trace). Не login, как в Termux обычно.
# Фильтруем шум, но сохраняем полный лог.
bash -xi -c 'exit' >"$TRACE" 2>&1 || true

# Сводка по трассе
SUM="$OUTDIR/summary.txt"
{
  echo "=== SUMMARY @ $(date -Iseconds) ==="
  echo "trace file: $TRACE"
  echo
  echo "Hits by file:"
  for f in "${FILES[@]}"; do
    [ -f "$f" ] || continue
    bn="$(basename "$f")"
    cnt=$(grep -cF "$bn" "$TRACE" || true)
    printf "%-16s : %d\n" "$bn" "$cnt"
  done
  echo
  echo "WZ-lines in .bashrc:"
  [ -f "$HOME/.bashrc" ] && (grep -nE 'WZ|wz_.*\.sh' "$HOME/.bashrc" || echo "(no WZ markers)") || echo "(no .bashrc)"
  echo
  echo "Heuristic verdict:"
  if grep -qF ".bashrc" "$TRACE"; then
    echo "- .bashrc: ДОСТОВЕРНО подключается в интерактивной сессии"
  else
    echo "- .bashrc: не видно в трассе (возможно shell не bash, либо .bashrc не загружается)"
  fi
  if grep -qF ".profile" "$TRACE"; then
    echo "- .profile: подключается (обычно для login-сессий)"
  else
    echo "- .profile: не видно в трассе (для Termux это нормально)"
  fi
} > "$SUM"

# Экранный вывод (короткий вердикт)
say "Готово: filesnap.txt, bash_trace.log, summary.txt"
say "Ключевое:"
hr
awk 'NR<=200{print} NR==200{print "... (см. summary.txt)"}' "$SUM" || cat "$SUM"
hr

# Быстрый чек важных хуков (по памяти проекта)
say "Hooks quick-check:"
for hook in \
  "wz_sync_push_daemon.sh" \
  "gpt_push_memorylog.sh" \
  "wz_login_host_probe.sh" \
  ; do
  if grep -qF "$hook" "$HOME/.bashrc" 2>/dev/null; then
    say "OK  : $hook упомянут в .bashrc"
  else
    say "MISS: $hook не найден в .bashrc"
  fi
done
