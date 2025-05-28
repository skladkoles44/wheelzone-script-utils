# Auto-launch: plate–profile linker
bash ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/linker_loop.sh &


# Подключение аналитических модулей

python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/vin_pattern_analyzer.py >> logs/vin_pattern_analyzer_cron.log 2>&1 &
python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/dom_heatmap_builder.py >> logs/dom_heatmap_builder_cron.log 2>&1 &
python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/auto_penalty_tracker.py >> logs/auto_penalty_tracker_cron.log 2>&1 &
python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/dom_instability_watchdog.py >> logs/dom_instability_watchdog_cron.log 2>&1 &

# Автозапуск аналитических фаз

python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/linked_profiles_validator.py >> logs/linked_profiles_validator_cron.log 2>&1 &
python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/plate_retry_manager.py >> logs/plate_retry_manager_cron.log 2>&1 &
python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/fingerprint_rotator.py >> logs/fingerprint_rotator_cron.log 2>&1 &
python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/dom_fragment_indexer.py >> logs/dom_fragment_indexer_cron.log 2>&1 &
python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/personality_history_tracker.py >> logs/personality_history_tracker_cron.log 2>&1 &