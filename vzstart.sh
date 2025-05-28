#!/bin/bash
# Запуск VPS через REG.RU API
curl -s -X POST "https://api.reg.ru/api/regru2/vps/service/start" \
  -d "username=info@skladkoles44.ru" \
  -d "password=wzAPI_2025!" \
  -d "service_id=4769594" | jq .
