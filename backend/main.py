from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import get_db_connection
from routers.recognition import router as recognition_router
from routers.search import router as search_router
from routers.favorites import router as favorites_router
from routers.auth import router as auth_router
from routers.history import router as history_router

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1):\d+",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {"message": "Backend работает"}


@app.get("/db-check")
def db_check():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1;")
        cur.fetchone()
        cur.close()
        conn.close()
        return {"message": "DB работает"}
    except Exception as e:
        return {"error": str(e)}


app.include_router(auth_router)
app.include_router(recognition_router)
app.include_router(search_router)
app.include_router(favorites_router)
app.include_router(history_router)