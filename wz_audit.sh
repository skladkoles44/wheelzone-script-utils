#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:17+03:00-3424901815
# title: wz_audit.sh
# component: .
# updated_at: 2025-08-26T13:20:17+03:00

echo "[AUDIT] Запуск аудита WheelZone..."
cd ~/storage/downloads/project_44/MetaSystem/
echo "[+] Проверка file_versions_index.json:"
cat file_versions_index.json | wc -l

echo "[+] Проверка version_map.json:"
cat version_map.json | wc -l

echo "[+] Проверка актуальности Meta-файлов:"
ls -l | grep '.json\|.md\|.sh'

echo "[+] Проверка наличия gatekeeper:"
test -x release_gatekeeper.sh && echo "GATEKEEPER OK" || echo "GATEKEEPER MISSING"

echo "[AUDIT COMPLETE]"
