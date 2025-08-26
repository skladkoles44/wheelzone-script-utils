#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:55+03:00-2219302243
# title: daily_snapshot (1).sh
# component: .
# updated_at: 2025-08-26T13:19:55+03:00

cd ~/wheelzone/bootstrap_tool/
git pull --rebase origin main

DATE=$(date +"%Y-%m-%d_%H-%M")
SNAPSHOT=ALL/gpt_profile_snapshot_${DATE}.json
mkdir -p ALL
echo '{ "snapshot": "данные профиля будут здесь" }' > "$SNAPSHOT"

git add "$SNAPSHOT"
git commit -m "Автобэкап GPT-профиля на ${DATE}"
git push
