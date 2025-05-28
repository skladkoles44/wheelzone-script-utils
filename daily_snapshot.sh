#!/data/data/com.termux/files/usr/bin/bash
export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets:$PATH

cd ~/wheelzone/bootstrap_tool/

DATE=$(date +%Y-%m-%d_%H-%M)
SNAPSHOT=ALL/gpt_profile_snapshot_$DATE.json

cp ALL/account_converted/gpt_profile_snapshot.json "$SNAPSHOT"

git add "$SNAPSHOT"
git commit -m "Автобэкап GPT-профиля на $DATE"
git push origin main
