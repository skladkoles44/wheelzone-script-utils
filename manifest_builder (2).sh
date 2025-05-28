#!/data/data/com.termux/files/usr/bin/bash
MANIFEST=~/storage/downloads/project_44/MetaSystem/control_manifest.md
echo "# WheelZone Control Manifest" > "$MANIFEST"
echo "" >> "$MANIFEST"
FILES=(
  "~/bin/wzfinal.sh"
  "~/bin/wzlogger.sh"
  "~/bin/wzproof.sh"
  "~/bin/wzcheck.sh"
  "~/bin/wzaudit.sh"
  "~/storage/downloads/project_44/MetaSystem/GPT_state.json"
  "~/storage/downloads/project_44/MetaSystem/Logs/wz_command_history.jsonl"
)
for f in "${FILES[@]}"; do
  eval path=$f
  if [ -f "$path" ]; then
    HASH=$(sha256sum "$path" | cut -d ' ' -f 1)
    echo "- \`${f##*/}\`: OK — \`$HASH\`" >> "$MANIFEST"
  else
    echo "- \`${f##*/}\`: MISSING" >> "$MANIFEST"
  fi
done
echo "[manifest_builder] Сформирован $MANIFEST"
