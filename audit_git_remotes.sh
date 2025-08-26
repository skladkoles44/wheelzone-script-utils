#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:48+03:00-2622854083
# title: audit_git_remotes.sh
# component: .
# updated_at: 2025-08-26T13:19:48+03:00

echo "🔍 Аудит git-репозиториев:"
find ~/wheelzone -type d -name ".git" | while read -r gitdir; do
  repodir=$(dirname "$gitdir")
  echo -e "\n📁 Репозиторий: $repodir"
  cd "$repodir" && git remote -v
done
