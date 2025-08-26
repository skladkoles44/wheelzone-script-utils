#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:58+03:00-1691595586
# title: extract_chat_archives.sh
# component: .
# updated_at: 2025-08-26T13:19:58+03:00


# Создание директорий
mkdir -p ~/storage/downloads/project_44/Termux/AccountMemory/zips
mkdir -p ~/storage/downloads/project_44/Termux/AccountMemory/AllChatsUnzipped

# Переход в папку с zip-архивами
cd ~/storage/downloads/project_44/Termux/AccountMemory/zips

# Скачивание обоих архивов
rclone copy "gdrive:41da5efefd4ed1b0bf0c3e393da92fdea885dd6e774e347cb16446fbb1dcc0b0-2025-05-05-09-55-07-70bfcc64eede4a2a906c7e8e5816d247.zip" .
rclone copy "gdrive:WheelZoneSync/CHATGPT_EXPORTS/41da5efefd4ed1b0bf0c3e393da92fdea885dd6e774e347cb16446fbb1dcc0b0-2025-05-02-19-35-09-7cad7bd67eb3471e87805827251c0f84.zip" .

# Распаковка
for f in *.zip; do
  unzip -o "$f" -d ../AllChatsUnzipped/
done

echo "✅ Архивы распакованы в AllChatsUnzipped"
