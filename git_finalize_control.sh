#!/bin/bash

REPO_DIR="$HOME/wheelzone/auto-framework"
LOG_DIR="$HOME/wheelzone/auto-framework/logs/git"
mkdir -p "$LOG_DIR"

cd "$REPO_DIR" || exit 1

DATE_STR=$(date '+%Y-%m-%d_%H-%M')
BRANCH=$(git rev-parse --abbrev-ref HEAD)
CHANGES=$(git status --porcelain)

LOG_SUCCESS="$LOG_DIR/push_success_$DATE_STR.log"
LOG_SKIPPED="$LOG_DIR/push_skipped_$DATE_STR.log"
LOG_CONFLICT="$LOG_DIR/push_conflict_$DATE_STR.log"

if [ -z "$CHANGES" ]; then
  echo "❌ No changes to commit — skipping push." | tee "$LOG_SKIPPED"
  exit 0
fi

git add .
git commit -m "autopush: изменения от $DATE_STR" 2>&1 | tee "$LOG_SUCCESS"

git pull --rebase origin "$BRANCH" 2>&1 | tee -a "$LOG_SUCCESS"
PULL_STATUS=$?

if [ "$PULL_STATUS" -ne 0 ]; then
  echo "⚠️ Conflict or pull failed, skipping push." | tee "$LOG_CONFLICT"
  exit 1
fi

git push origin "$BRANCH" 2>&1 | tee -a "$LOG_SUCCESS"
