#!/usr/bin/env bash
# WZ :: Host Check Menu — всё через меню + показ пути логов
# Version: 1.2.0
SCRIPT="$HOME/wheelzone-script-utils/scripts/utils/wz_check_host.sh"
LOG_DIR="/storage/emulated/0/Download/project_44/Logs"

show_last_logs() {
  echo
  echo "— Папка логов: $LOG_DIR"
  [ -d "$LOG_DIR" ] || { echo "[WARN] каталога нет"; return; }

  SUM="$(ls -t "$LOG_DIR"/wz_check_summary_*.log 2>/dev/null | head -n1)"
  LAST="$(ls -t "$LOG_DIR"/wz_check_*.log 2>/dev/null | head -n3)"

  if [ -n "$SUM" ]; then
    echo "Последний summary: $SUM"
  else
    echo "Summary-логов пока нет."
  fi

  if [ -n "$LAST" ]; then
    echo "Последние host-логи:"
    echo "$LAST" | sed 's/^/  • /'
  else
    echo "Host-логов пока нет."
  fi

  # Предложить открыть последний файл (если есть termux-open и есть файл)
  if command -v termux-open >/dev/null 2>&1; then
    if [ -n "$SUM" ]; then
      read -rp "Открыть summary в системном вьювере? [y/N] " A
      case "$A" in
        y|Y) termux-open "$SUM" >/dev/null 2>&1 || echo "[WARN] не удалось открыть";;
      esac
    fi
  fi
}

while true; do
  clear
  echo "=== WZ Host Check Menu === (IP и порты уже зашиты)"
  echo "1) Только Ping по всем хостам"
  echo "2) Проверка только портов"
  echo "3) Полная проверка (Ping + Порты, verbose)"
  echo "4) Полная + SSH-глубокая (если порт доступен)"
  echo "5) Показать путь и последние логи"
  echo "0) Выход"
  echo "=========================="
  read -rp "Выбор: " CH
  case "$CH" in
    0) echo "Выход."; exit 0 ;;
    1) "$SCRIPT" >/dev/null; show_last_logs; read -rp "Enter..." _;;
    2) "$SCRIPT" >/dev/null; show_last_logs; read -rp "Enter..." _;;
    3) "$SCRIPT" -v; show_last_logs; read -rp "Enter..." _;;
    4) "$SCRIPT" -v -r; show_last_logs; read -rp "Enter..." _;;
    5) show_last_logs; read -rp "Enter..." _;;
    *) echo "[ERR] неизвестный выбор"; sleep 1 ;;
  esac
done
