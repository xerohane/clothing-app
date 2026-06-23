import psycopg2
import os
from config import DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD

def get_db_connection():
    # Если переменные есть в окружении (их передает Docker), берем их.
    # Если нет (локальный запуск), берем дефолтные значения из config.py
    host = os.getenv("DB_HOST", DB_HOST)
    user = os.getenv("DB_USER", DB_USER)
    password = os.getenv("DB_PASSWORD", DB_PASSWORD)
    dbname = os.getenv("DB_NAME", DB_NAME)
    port = os.getenv("DB_PORT", DB_PORT)

    conn = psycopg2.connect(
        host=host,
        port=port,
        dbname=dbname,
        user=user,
        password=password
    )
    
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS audit_logs (
            audit_id SERIAL PRIMARY KEY,
            admin_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
            action VARCHAR(100) NOT NULL,
            target_type VARCHAR(50),
            target_id INTEGER,
            details TEXT,
            created_at TIMESTAMP DEFAULT NOW()
        );
        """
    )
    conn.commit()
    cur.close()
    return conn