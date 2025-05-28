#!/data/data/com.termux/files/usr/bin/bash
cd ~/wheelzone/bootstrap_tool/
git pull --rebase origin main

DATE=$(date +"%Y-%m-%d_%H-%M")
SNAPSHOT=ALL/gpt_profile_snapshot_${DATE}.json
mkdir -p ALL
echo '{ "snapshot": "данные профиля будут здесь" }' > "$SNAPSHOT"

git add "$SNAPSHOT"
git commit -m "Автобэкап GPT-профиля на ${DATE}"
git push
