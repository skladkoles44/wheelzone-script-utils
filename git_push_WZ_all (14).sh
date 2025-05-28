#!/data/data/com.termux/files/usr/bin/bash
cd ~/wheelzone/auto-framework || exit 1
git add .
git commit -m "AutoPush: $(date +%F_%T)"
git pull --rebase
git push