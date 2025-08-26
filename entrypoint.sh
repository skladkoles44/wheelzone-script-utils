#!/bin/bash
# uuid: 2025-08-26T13:19:58+03:00-2888392723
# title: entrypoint.sh
# component: .
# updated_at: 2025-08-26T13:19:58+03:00


flask db upgrade
exec gunicorn -b 0.0.0.0:5000 'app:create_app()'