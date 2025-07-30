import psycopg2
import os
import contextlib

@contextlib.contextmanager
def get_connection():
    conn = psycopg2.connect(
        dbname="core_test",
        user="admin",
        password=os.getenv("PGPASSWORD", ""),
        host="localhost",
        port=5432
    )
    try:
        yield conn
    finally:
        conn.close()
