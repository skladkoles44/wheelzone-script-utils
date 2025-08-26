#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:02+03:00-2709273
# title: git_push_WZ_all (14).sh
# component: .
# updated_at: 2025-08-26T13:20:02+03:00

cd ~/wheelzone/auto-framework || exit 1
git add .
git commit -m "AutoPush: $(date +%F_%T)"
git pull --rebase
git push