# uuid: 2025-08-26T13:19:51+03:00-4073433978
# title: bootstrap_autorun (1).sh
# component: .
# updated_at: 2025-08-26T13:19:51+03:00

# Auto-launch: plate–profile linker
bash ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/linker_loop.sh &


# Автолог нестабильных VIN
python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/unstable_logger.py >> ~/storage/shared/Projects/wheelzone/bootstrap_tool/logs/unstable_logger_cron.log 2>&1 &