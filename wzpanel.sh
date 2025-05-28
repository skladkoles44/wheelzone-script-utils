#!/data/data/com.termux/files/usr/bin/bash

while true; do
  clear
  echo "=== WheelZone Command Panel ==="
  echo "1) gptsync — Синхронизация файла"
  echo "2) Запустить auto-framework"
  echo "3) Резервная копия системы"
  echo "4) Проверка VPN/IP"
  echo "5) Запуск системы H"
  echo "6) Аудит GPT-памяти"
  echo "7) Выход"
  echo "==============================="
  read -p "Выберите действие [1-7]: " choice

  case $choice in
    1)
      echo "Введите путь к файлу для gptsync:"
      read filepath
      if [ -f "$filepath" ]; then
        cp "$filepath" /mnt/data/
        echo "Файл синхронизирован: $filepath"
      else
        echo "Файл не найден!"
      fi
      read -n 1 -s -r -p "Нажмите любую клавишу..."
      ;;
    2)
      echo "Запуск auto-framework..."
      bash ~/wheelzone/auto-framework/start.sh
      read -n 1 -s -r -p "Нажмите любую клавишу..."
      ;;
    3)
      echo "Запуск резервного копирования..."
      bash ~/storage/downloads/project_44/Termux/Script/full_backup.sh
      read -n 1 -s -r -p "Нажмите любую клавишу..."
      ;;
    4)
      echo "IP и геолокация:"
      curl ifconfig.me
      echo
      termux-location
      read -n 1 -s -r -p "Нажмите любую клавишу..."
      ;;
    5)
      echo "Запуск системы H..."
      bash ~/wheelzone/H/start_H_cycle.sh
      read -n 1 -s -r -p "Нажмите любую клавишу..."
      ;;
    6)
      echo "Аудит памяти GPT..."
      bash ~/storage/downloads/project_44/Termux/Script/memory_audit.sh
      read -n 1 -s -r -p "Нажмите любую клавишу..."
      ;;
    7)
      echo "Выход из панели."
      break
      ;;
    *)
      echo "Неверный выбор. Попробуйте снова."
      read -n 1 -s -r -p "Нажмите любую клавишу..."
      ;;
  esac
done
