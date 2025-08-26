#!/bin/bash
# uuid: 2025-08-26T13:19:03+03:00-1658937478
# title: start.sh
# component: .
# updated_at: 2025-08-26T13:19:03+03:00

cd "$(dirname "$0")"
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
