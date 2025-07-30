from fastapi import FastAPI
from app.routes import rules

app = FastAPI()
app.include_router(rules.router)
