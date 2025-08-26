# uuid: 2025-08-26T13:20:00+03:00-1841188316
# title: git_commit_H_architecture.sh
# component: .
# updated_at: 2025-08-26T13:20:00+03:00

cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add H/WZ_H_Architecture_2025-05-06.md H/WZ_H_Architecture_2025-05-06.txt
git commit -m "DOCS | Архитектура системы H зафиксирована (2025-05-06)"
git push