#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:25+03:00-2642290190
# title: setup_git_credentials.sh
# component: .
# updated_at: 2025-08-26T13:19:25+03:00

#!/data/data/com.termux/files/usr/bin/bash

# 🔐 Setup GitHub credentials using .netrc and optionally ~/.wz_secrets/github_token.txt
# Version: 1.1 | Termux/Unix-ready | WheelZone WBP

echo "🔧 Настройка GitHub авторизации через .netrc"

read -p "👤 GitHub логин: " GIT_USER

TOKEN_FILE="$HOME/.wz_secrets/github_token.txt"

if [[ -f "$TOKEN_FILE" ]]; then
	GIT_TOKEN=$(cat "$TOKEN_FILE")
	echo "🧬 Токен подставлен из ~/.wz_secrets/github_token.txt"
else
	read -p "🔑 Введите GitHub токен (Personal Access Token): " GIT_TOKEN
fi

cat >~/.netrc <<EOCONF
machine github.com
login $GIT_USER
password $GIT_TOKEN
EOCONF

chmod 600 ~/.netrc

echo "✅ .netrc создан и защищён (chmod 600)"
echo "📦 Проверка доступа к GitHub..."

if git ls-remote https://github.com/$GIT_USER/wz-wiki.git &>/dev/null; then
	echo "🟢 Доступ подтверждён — можно пушить без логина"
else
	echo "🔴 Не удалось подключиться — проверь логин или токен"
fi
