from fastapi import APIRouter
from ..db import get_connection

router = APIRouter()

@router.get("/rules")
def get_rules():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT slug, content FROM wz.rules ORDER BY created_at DESC LIMIT 10")
            return [{"slug": slug, "content": content} for slug, content in cur]
