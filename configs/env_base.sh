#!/usr/bin/env bash
# WZ Artifact Header v1.0
# Registry: wheelzone://configs/env_base.sh/v1.0.0
# Fractal-UUID: PENDING-UUID
# Task-Class: idempotent
# Version: v0.1.0
# Owner: WheelZone Core
# Maintainer: WheelZone Core
# Created-At: 2025-10-03T00:00:00Z
# Updated-At: 2025-10-03T00:00:00Z
# Inputs: none
# Outputs: environment variables
# Side-Effects: none
# Idempotency: Yes
# Run-Mode: apply
# SLO/SLA: N/A
# Rollback: replace file from git
# Compatibility: POSIX shell
# Integrity-Hash: PENDING-SHA256

# === Base environment for WheelZone ===

: "${HOME:=$HOME}"
: "${WZ_ROOT:=$HOME/wz-git-backup}"
: "${WZ_BUFFER:=$HOME/wzbuffer}"
: "${WZ_LOGS:=$WZ_BUFFER/logs}"
: "${WZ_REPORTS:=$WZ_BUFFER/reports}"
: "${GDRIVE_REMOTE:=gdrive}"

export HOME WZ_ROOT WZ_BUFFER WZ_LOGS WZ_REPORTS GDRIVE_REMOTE
