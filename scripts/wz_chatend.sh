#!/data/data/com.termux/files/usr/bin/bash
#!/data/data/com.termux/files/usr/bin/bash
# WheelZone ChatEnd Generator v1.4.3 (Android 15 HyperOS Optimized)
set -eo pipefail
shopt -s nullglob failglob nocasematch

# === Конфигурация ===
readonly DEFAULT_OUTPUT_DIR="${HOME}/wz-wiki/WZChatEnds"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S-%3N)"
readonly UUID="$(
	{
		cat /proc/sys/kernel/random/uuid 2>/dev/null ||
			uuidgen 2>/dev/null ||
			python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null ||
			od -An -tx8 -N16 /dev/urandom | tr -d ' ' | fold -w32 | head -n1
	} | tr '[:upper:]' '[:lower:]' | head -c36
)"
readonly SLUG="chatend_${TIMESTAMP}_${UUID:0:8}"

# === Безопасный парсинг ===
declare -A ARGS=(
	[input]=""
	[output_dir]="$DEFAULT_OUTPUT_DIR"
	[auto]=false
	[git]=false
)

while (($#)); do
	case "${1,,}" in
	--from-markdown | --input)
		[[ -z "${2:-}" ]] && {
			echo >&2 "[ERRO] Пустой --from-markdown"
			exit 1
		}
		ARGS[input]="$(realpath -e -- "$2" 2>/dev/null || {
			echo >&2 "[ERRO] Неверный путь: $2"
			exit 1
		})"
		shift 2
		;;
	--output-dir | --out)
		[[ -z "${2:-}" ]] && {
			echo >&2 "[ERRO] Пустой --output-dir"
			exit 1
		}
		ARGS[output_dir]="$(realpath -m -- "$2")"
		shift 2
		;;
	--auto)
		ARGS[auto]=true
		shift
		;;
	--git)
		ARGS[git]=true
		shift
		;;
	--)
		shift
		break
		;;
	*)
		echo >&2 "[ERRO] Неизвестный аргумент: $1"
		exit 1
		;;
	esac
done

# === Валидация ===
[[ -z "${ARGS[input]}" ]] && {
	echo >&2 "[ERRO] Требуется --from-markdown"
	exit 1
}
[[ -r "${ARGS[input]}" ]] || {
	echo >&2 "[ERRO] Нет доступа: ${ARGS[input]}"
	exit 1
}
mkdir -p "${ARGS[output_dir]}" || {
	echo >&2 "[ERRO] Ошибка создания ${ARGS[output_dir]}"
	exit 1
}

# === Атомарная запись ===
TEMP_OUT="${ARGS[output_dir]}/${SLUG}.md.tmp"
FINAL_OUT="${ARGS[output_dir]}/${SLUG}.md"

{
	printf -- "---\nuuid: %s\nslug: %s\ntimestamp: %s\nsource: %s\nauto: %s\n---\n\n" \
		"$UUID" "$SLUG" "$TIMESTAMP" "${ARGS[input]}" "${ARGS[auto]}"
	dd if="${ARGS[input]}" bs=64K 2>/dev/null
} >"$TEMP_OUT" &&
	mv -f "$TEMP_OUT" "$FINAL_OUT"

echo "[INFO] Сохранено: $FINAL_OUT" >&2

# === Git для HyperOS ===
if "${ARGS[git]}"; then
	if ! command -v git >/dev/null; then
		echo >&2 "[WARN] Git не найден"
		exit 0
	fi

	(
		cd "${ARGS[output_dir]}/.." || exit 1
		if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
			echo >&2 "[ERRO] Не git-репозиторий"
			exit 1
		fi

		git -c core.sshCommand="ssh -o BatchMode=yes" \
			-c commit.gpgsign=false \
			add -- "$(basename -- "${ARGS[output_dir]}")" &&
			git commit -m "chatend: $SLUG" &&
			{ git config remote.origin.url &>/dev/null && git pull --rebase --autostash || :; } &&
			git push
	) || {
		echo >&2 "[ERRO] Ошибка git"
		exit 1
	}
fi
