: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

#!/data/data/com.termux/files/usr/bin/bash
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ENV_FILE="$HOME/wheelzone-script-utils/configs/.env.notion"

declare -A IDS=(
	[PARENT_PAGE_ID_TASKS]="2282a47c88038052ae75dff60c3dd8bc"
	[PARENT_PAGE_ID_MAIN]="2282a47c88038090b3a4c5d38700e568"
	[PARENT_PAGE_ID_CI]="XXXXXXXX_CI_PLACEHOLDER"
	[PARENT_PAGE_ID_IDEAS]="YYYYYYYY_IDEAS_PLACEHOLDER"
)

# === Создаём файл если не существует ===
touch "$ENV_FILE"

for KEY in "${!IDS[@]}"; do
	VALUE="${IDS[$KEY]}"
	sed -i "/^$KEY=/d" "$ENV_FILE"
	echo "$KEY=$VALUE" >>"$ENV_FILE"
	echo "{\"level\":\"INFO\",\"key\":\"$KEY\",\"status\":\"written\",\"value\":\"$VALUE\"}"
done

echo '{"level":"INFO","status":"✅ All IDs written"}'
