#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:16+03:00-2901671739
# title: system_probe.sh
# component: .
# updated_at: 2025-08-26T13:20:16+03:00


mkdir -p ~/storage/shared/Downloads/project_44/Termux/output/

termux-wifi-connectioninfo > ~/storage/shared/Downloads/project_44/Termux/output/wifi_info.json
termux-telephony-deviceinfo > ~/storage/shared/Downloads/project_44/Termux/output/telephony_device.json
termux-telephony-cellinfo > ~/storage/shared/Downloads/project_44/Termux/output/telephony_cell.json
termux-battery-status > ~/storage/shared/Downloads/project_44/Termux/output/battery_status.json
termux-location > ~/storage/shared/Downloads/project_44/Termux/output/location.json
termux-storage-get > ~/storage/shared/Downloads/project_44/Termux/output/storage_get.json
termux-wifi-scaninfo > ~/storage/shared/Downloads/project_44/Termux/output/wifi_scan.json
ip a > ~/storage/shared/Downloads/project_44/Termux/output/ip_info.txt
termux-info > ~/storage/shared/Downloads/project_44/Termux/output/system_info.json
