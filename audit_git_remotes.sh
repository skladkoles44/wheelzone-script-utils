#!/data/data/com.termux/files/usr/bin/bash
echo "🔍 Аудит git-репозиториев:"
find ~/wheelzone -type d -name ".git" | while read -r gitdir; do
  repodir=$(dirname "$gitdir")
  echo -e "\n📁 Репозиторий: $repodir"
  cd "$repodir" && git remote -v
done
