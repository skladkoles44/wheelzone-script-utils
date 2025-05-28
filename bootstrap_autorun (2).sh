# Auto-launch: plate–profile linker
bash ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/linker_loop.sh &


# Автолог нестабильных VIN
python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/unstable_logger.py >> ~/storage/shared/Projects/wheelzone/bootstrap_tool/logs/unstable_logger_cron.log 2>&1 &