: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

#!/data/data/com.termux/files/usr/bin/bash
#!/data/data/com.termux/files/usr/bin/bash
set -o errexit -o nounset -o pipefail

LOCK_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
PARALLEL_JOBS=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)

process_file() {
	local file="$1"
	local header
	header=$(head -n1 "$file" 2>/dev/null || echo "")

	case "$header" in
	*id,title,goal,status,due_date,owner*)
		echo "1,Launch Notion,Finish setup,In Progress,2025-07-10,GPT" >>"$file"
		;;
	*id,name,email,phone,company,notes*)
		echo "1,Alice,alice@example.com,123456789,Acme Inc,VIP client" >>"$file"
		;;
	*id,url,title,description,tags*)
		echo "1,https://notion.so,Notion Home,Docs platform,productivity" >>"$file"
		;;
	*id,name,description,status,owner*)
		echo "1,CRM,Track clients,Active,GPT" >>"$file"
		;;
	*id,date,source,amount,notes*)
		echo "1,2025-07-09,Stripe,1500,Monthly payment" >>"$file"
		;;
	*id,client,date,due,amount,status*)
		echo "1,Acme,2025-07-01,2025-07-10,2500,Paid" >>"$file"
		;;
	*id,title,status,priority,project,due_date*)
		echo "1,Fix login bug,Open,High,Mobile App,2025-07-12" >>"$file"
		;;
	*id,habit,frequency,status,last_checked*)
		echo "1,Read,Daily,Ongoing,2025-07-08" >>"$file"
		;;
	*id,summary,status,severity,assigned_to*)
		echo "1,Crash in v1.2,Open,Critical,DevTeam" >>"$file"
		;;
	*id,date,amount,category,description*)
		echo "1,2025-07-01,100,Marketing,Instagram ads" >>"$file"
		;;
	*id,title,content,tags,created_at*)
		echo "1,First Note,Check this out,tag1;tag2,2025-07-09" >>"$file"
		;;
	*id,order_id,date,status,comments*)
		echo "1,ORD123,2025-07-05,Delivered,No issues" >>"$file"
		;;
	*id,date,time,topic,participants*)
		echo "1,2025-07-10,14:00,Weekly Sync,GPT,Client" >>"$file"
		;;
	*id,idea,category,value,author*)
		echo "1,AI summary,UX,High,GPT" >>"$file"
		;;
	*id,name,email,phone,company*)
		echo "1,Bob,bob@corp.com,987654321,Corp Ltd" >>"$file"
		;;
	*id,timestamp,level,message,module*)
		echo "1,2025-07-08T12:00:00Z,INFO,Started service,backend" >>"$file"
		;;
	*id,date,event,location,notes*)
		echo "1,2025-07-10,Release Day,Remote,Version 1.0" >>"$file"
		;;
	*id,topic,summary,source,date*)
		echo "1,Security,Updated protocols,Audit,2025-07-07" >>"$file"
		;;
	*id,name,due_date,progress,responsible*)
		echo "1,Setup billing,2025-07-12,80%,GPT" >>"$file"
		;;
	*term,definition,category*)
		echo "Agile,Iterative dev approach,Methodology" >>"$file"
		;;
	*key,value,description*)
		echo "api_key,ntn_xxxx,Notion integration key" >>"$file"
		;;
	esac
}

export -f process_file

find ~/storage/shared/Notion_Templates/ -maxdepth 1 -name '*.csv' -print0 |
	xargs -0 -P"$PARALLEL_JOBS" -n1 bash -c 'process_file "$0"'
