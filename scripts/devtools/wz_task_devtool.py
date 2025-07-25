#!/data/data/com.termux/files/usr/bin/env python3
"""
WZ Task DevTool CLI — v1.0.1 (pg8000-native, Termux-compatible)
Автоматизация: SSH-туннель, init-db, seed, show, всё через pure Python
"""

import argparse
import logging
import os
import subprocess
import sys
from datetime import datetime
from uuid import uuid4
import pg8000.native as pg

# === Константы ===
DEFAULT_PORT = 5433
ENV_PATH = os.path.expanduser("~/.env.wzpg")

# === Логгер ===
logging.basicConfig(
    level=logging.INFO,
    format='{"time": "%(asctime)s", "level": "%(levelname)s", "msg": "%(message)s"}',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger("wz_devtool")

# === ENV loader ===
def load_env():
    if not os.path.isfile(ENV_PATH):
        logger.error("❌ .env.wzpg не найден")
        sys.exit(1)
    with open(ENV_PATH) as f:
        for line in f:
            if "=" in line:
                k, v = line.strip().split("=", 1)
                os.environ[k] = v.strip('"').strip("'")

# === SSH tunnel ===
def setup_tunnel():
    port = os.getenv("DB_PORT", str(DEFAULT_PORT))
    host = os.getenv("VPS_HOST")
    user = os.getenv("VPS_USER")
    key = os.path.expanduser(os.getenv("SSH_KEY", "~/.ssh/id_rsa"))

    if not host or not user:
        logger.error("❌ VPS_HOST и VPS_USER не заданы в .env.wzpg")
        return

    check = subprocess.run(f"pgrep -f 'ssh -fN -L {port}'", shell=True)
    if check.returncode != 0:
        cmd = f"ssh -fN -L {port}:localhost:5432 -i {key} {user}@{host}"
        logger.info(f"🚀 SSH-туннель: {cmd}")
        subprocess.run(cmd, shell=True, check=True)
    else:
        logger.info("🔁 SSH-туннель уже активен")

# === PG connect ===
def pg_conn():
    return pg.Connection(
        host="127.0.0.1",
        port=int(os.getenv("DB_PORT", DEFAULT_PORT)),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASS"),
        database=os.getenv("DB_NAME", "core_test")
    )

# === Schema init ===
def init_schema():
    logger.info("🛠 Создание wz.tasks")
    conn = pg_conn()
    conn.run("""
    CREATE TABLE IF NOT EXISTS wz.tasks (
        id UUID PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'todo',
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP
    );
    CREATE OR REPLACE FUNCTION update_task_timestamp()
    RETURNS TRIGGER AS $$
    BEGIN NEW.updated_at = now(); RETURN NEW; END;
    $$ LANGUAGE plpgsql;
    DROP TRIGGER IF EXISTS trg_upd ON wz.tasks;
    CREATE TRIGGER trg_upd BEFORE UPDATE ON wz.tasks
    FOR EACH ROW EXECUTE FUNCTION update_task_timestamp();
    """)
    logger.info("✅ Таблица создана")

# === Seed ===
def seed_tasks():
    logger.info("🌱 Добавление тестовых задач")
    conn = pg_conn()
    tasks = [
        (str(uuid4()), "Задача: настроить ядро", "Подключение ядра WZ", "todo"),
        (str(uuid4()), "CI скрипт", "Интеграция в Drone", "in_progress"),
        (str(uuid4()), "Тест CLI", "Проверка интерфейса", "done")
    ]
    for t in tasks:
        conn.run("INSERT INTO wz.tasks (id, title, description, status) VALUES (:id, :title, :desc, :status)", {
            "id": t[0], "title": t[1], "desc": t[2], "status": t[3]
        })
    logger.info("✅ Тестовые задачи добавлены")

# === Show ===
def show_tasks():
    conn = pg_conn()
    rows = conn.run("SELECT id, title, status, created_at FROM wz.tasks ORDER BY created_at")
    logger.info("📋 Список задач:")
    for row in rows:
        print(f"• [{row[2]}] {row[1]} ({row[3]})\n  ↪ ID: {row[0]}")

# === main ===
def main():
    parser = argparse.ArgumentParser(description="WZ Task DevTool (pg8000/native)")
    parser.add_argument("--tunnel", action="store_true", help="Установить SSH-туннель")
    parser.add_argument("--init-db", action="store_true", help="Создать таблицу wz.tasks")
    parser.add_argument("--seed", action="store_true", help="Добавить тестовые задачи")
    parser.add_argument("--show", action="store_true", help="Показать задачи")

    args = parser.parse_args()
    load_env()

    if args.tunnel:
        setup_tunnel()
    if args.init_db:
        init_schema()
    if args.seed:
        seed_tasks()
    if args.show:
        show_tasks()

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.error(f"💥 Ошибка: {e}")
        sys.exit(1)
