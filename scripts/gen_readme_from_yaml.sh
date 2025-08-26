#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:27+03:00-2808468477
# title: gen_readme_from_yaml.sh
# component: .
# updated_at: 2025-08-26T13:19:27+03:00

#!/data/data/com.termux/files/usr/bin/bash
# Автогенератор README.md на основе wz_ai_rule.yml

YAML=~/wheelzone-script-utils/docs/wz_ai_rule.yml
OUT=~/wheelzone-script-utils/scripts/README.md

command -v yq >/dev/null || pkg install -y yq >/dev/null 2>&1

version=$(yq '.version' "$YAML")
desc=$(yq '.description' "$YAML")
entry=$(yq '.entrypoint' "$YAML")

{
	echo "# $(basename "$entry") — WheelZone AI Rule Interface v$version"
	echo
	echo "$desc"
	echo
	echo "## 🚀 Команды"
	yq '.commands[]' "$YAML" | while read -r line; do
		[[ "$line" == "- name:"* ]] && cmd=${line#*: } && echo -e "\n### 🔹 $cmd"
		[[ "$line" == "  description:"* ]] && echo "- ${line#*: }"
		[[ "$line" == "  usage:"* ]] && echo "\`\`\`bash" && echo "${line#*: }" && echo "\`\`\`"
	done
	echo
	echo "## 🧰 Зависимости"
	yq '.dependencies' "$YAML" | sed 's/- /- /'
	echo
	echo "## 📁 Пути"
	yq '.paths' "$YAML" | sed 's/^/  /'
	echo
	echo "## 👤 Автор"
	yq '.author.name' "$YAML"
} >"$OUT"

echo "✅ README.md сгенерирован из YAML"
