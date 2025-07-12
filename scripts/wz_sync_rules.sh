#!/data/data/com.termux/files/usr/bin/bash
#!/data/data/com.termux/files/usr/bin/bash
REPO="$HOME/wz-knowledge"
RULES_DIR="$REPO/rules"
REGISTRY="$REPO/registry.yaml"
BRANCH="main"
generate_uuid() { command -v uuidgen >/dev/null && uuidgen | cut -d'-' -f1 || python3 -c "import uuid; print(str(uuid.uuid4())[:8])"; }
timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
create_rule() {
	local title="$1" uuid created file
	uuid=$(generate_uuid)
	created=$(timestamp)
	file="$RULES_DIR/rule_${uuid}.md"
	[[ -d "$RULES_DIR" ]] || mkdir -p "$RULES_DIR"
	printf -- "# %s\nUUID: %s\nCreated: %s\n\nContent: %s\n" "$title" "$uuid" "$created" "$title" -- >"$file"
	echo "[WZ] Правило создано: $file"
}
update_registry() {
	local rule_file uuid created tags name
	[[ -f "$REGISTRY" ]] || : >"$REGISTRY"
	{
		printf -- "# 📘 Реестр правил WZ\ngenerated: %s\nrules:\n" "$(date +%F)" --
		find "$RULES_DIR" -maxdepth 1 -name 'rule_*.md' -print0 | sort -z | while IFS= read -r -d '' rule_file; do
			uuid=$(awk -F': ' '/^UUID:/{print $2}' "$rule_file")
			created=$(awk -F': ' '/^Created:/{print $2}' "$rule_file")
			tags=$(awk -F': ' '/^Tags:/{print $2}' "$rule_file" 2>/dev/null || echo "")
			name=$(basename "$rule_file")
			printf -- "  - file: %s\n    uuid: %s\n    created: %s\n    tags: [%s]\n" "$name" "$uuid" "$created" "$tags" --
		done
	} >"$REGISTRY"
	echo "[✓] Синхронизация завершена → registry.yaml обновлён"
}
git_push() {
	local msg="${1:-rule: обновлён реестр}"
	(cd "$REPO" && git add rules/ registry.yaml &&
		git commit -m "$msg" &&
		git push origin "$BRANCH") || {
		echo "[ERR] Git push не удался"
		exit 1
	}
}
main() {
	[[ -d "$REPO" ]] || {
		echo "[ERR] Репозиторий $REPO не найден"
		exit 1
	}
	case "${1:-}" in
	--create)
		[[ -n "${2:-}" ]] || {
			echo "[ERR] Укажите название правила"
			exit 1
		}
		create_rule "$2"
		;;
	--sync | "")
		update_registry
		;;
	--commit)
		git_push "${2:-rule: обновлён реестр}"
		;;
	*)
		echo "📘 Использование:"
		echo "  $0 --create \"Название правила\""
		echo "  $0 --sync"
		echo "  $0 --commit \"Комментарий\""
		exit 1
		;;
	esac
}
main "$@"
