from fastapi import APIRouter, HTTPException
from psycopg2.extras import RealDictCursor

from database import get_db_connection

router = APIRouter()


@router.post("/register")
def register_user(data: dict):
    name = data.get("name", "").strip()
    email = data.get("email", "").strip().lower()
    password = data.get("password", "").strip()

    if not name or not email or not password:
        raise HTTPException(
            status_code=400,
            detail="name, email and password are required"
        )

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Проверяем, есть ли уже пользователь с таким email
        cur.execute(
            """
            SELECT user_id
            FROM users
            WHERE email = %s;
            """,
            (email,)
        )
        existing_user = cur.fetchone()

        if existing_user:
            cur.close()
            conn.close()
            raise HTTPException(
                status_code=400,
                detail="Пользователь с таким email уже существует"
            )

        # Создаем нового пользователя
        cur.execute(
            """
            INSERT INTO users (name, email, password_hash)
            VALUES (%s, %s, %s)
            RETURNING user_id, name, email, created_at;
            """,
            (name, email, password)
        )

        new_user = cur.fetchone()
        conn.commit()

        cur.close()
        conn.close()

        return {
            "message": "Регистрация успешна",
            "user": {
                "user_id": new_user["user_id"],
                "name": new_user["name"],
                "email": new_user["email"],
                "created_at": str(new_user["created_at"])
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка регистрации: {str(e)}"
        )

@router.post("/login")
def login_user(data: dict):
    email = data.get("email", "").strip().lower()
    password = data.get("password", "").strip()

    if not email or not password:
        raise HTTPException(
            status_code=400,
            detail="email and password are required"
        )

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute(
            """
            SELECT user_id, name, email, password_hash
            FROM users
            WHERE email = %s;
            """,
            (email,)
        )

        user = cur.fetchone()

        cur.close()
        conn.close()

        if not user:
            raise HTTPException(
                status_code=401,
                detail="Неверный email или пароль"
            )

        if user["password_hash"] != password:
            raise HTTPException(
                status_code=401,
                detail="Неверный email или пароль"
            )

        return {
            "message": "Вход выполнен",
            "user": {
                "user_id": user["user_id"],
                "name": user["name"],
                "email": user["email"]
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка входа: {str(e)}"
        )
