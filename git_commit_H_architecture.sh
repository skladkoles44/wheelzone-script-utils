cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add H/WZ_H_Architecture_2025-05-06.md H/WZ_H_Architecture_2025-05-06.txt
git commit -m "DOCS | Архитектура системы H зафиксирована (2025-05-06)"
git push