#!/data/data/com.termux/files/usr/bin/python3
import requests
import os
import json

token = "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"
parent_page_id = "a5c318e78a7a48ae8c7e3322cfa12e9e"

headers = {
    "Authorization": f"Bearer {token}",
    "Notion-Version": "2022-06-28",
    "Content-Type": "application/json",
}

data = {
    "parent": { "type": "page_id", "page_id": parent_page_id },
    "title": [{ "type": "text", "text": { "content": "WZ Test DB" } }],
    "properties": {
        "name": { "title": {} },
        "status": {
            "select": {
                "options": [
                    {"name": "pending", "color": "yellow"},
                    {"name": "ok", "color": "green"},
                    {"name": "fail", "color": "red"},
                ]
            }
        },
        "event": { "rich_text": {} },
        "source": { "rich_text": {} },
        "timestamp": { "date": {} }
    }
}

res = requests.post("https://api.notion.com/v1/databases", headers=headers, data=json.dumps(data))
print("Status:", res.status_code)
print(res.text)
