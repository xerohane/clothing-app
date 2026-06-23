from fastapi import APIRouter, HTTPException, Query
from psycopg2.extras import RealDictCursor

from database import get_db_connection

router = APIRouter()


def get_user(cur, user_id: int):
    cur.execute(
        """
        SELECT user_id, name, email, role, created_at, is_active
        FROM users
        WHERE user_id = %s;
        """,
        (user_id,)
    )
    return cur.fetchone()


def get_user_by_email(cur, email: str):
    cur.execute(
        """
        SELECT user_id, name, email, password_hash, role, is_active
        FROM users
        WHERE email = %s;
        """,
        (email,)
    )
    return cur.fetchone()


def ensure_admin(cur, admin_id: int):
    admin_user = get_user(cur, admin_id)
    if not admin_user:
        raise HTTPException(status_code=404, detail="Администратор не найден")
    if admin_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Требуется права администратора")
    return admin_user


def log_admin_action(cur, admin_id: int, action: str, target_type: str = None, target_id: int = None, details: str = None):
    cur.execute(
        """
        INSERT INTO audit_logs (admin_id, action, target_type, target_id, details)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING audit_id;
        """,
        (admin_id, action, target_type, target_id, details)
    )
    return cur.fetchone()["audit_id"]


def to_dict_list(rows, keys):
    return [
        {key: row[key] for key in keys}
        for row in rows
    ]


def fetch_admin_lists(cur):
    cur.execute("SELECT brand_id, brand_name FROM brands ORDER BY brand_name;")
    brands = cur.fetchall()

    cur.execute("SELECT category_id, category_name FROM categories ORDER BY category_name;")
    categories = cur.fetchall()

    cur.execute("SELECT store_id, store_name FROM stores ORDER BY store_name;")
    stores = cur.fetchall()

    cur.execute(
        """
        SELECT model_id, model_name, brand_id, category_id
        FROM clothing_models
        ORDER BY model_name;
        """
    )
    models = cur.fetchall()

    return {
        "brands": to_dict_list(brands, ["brand_id", "brand_name"]),
        "categories": to_dict_list(categories, ["category_id", "category_name"]),
        "stores": to_dict_list(stores, ["store_id", "store_name"]),
        "models": to_dict_list(models, ["model_id", "model_name", "brand_id", "category_id"]),
    }


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

        cur.execute(
            """
            INSERT INTO users (name, email, password_hash, role)
            VALUES (%s, %s, %s, %s)
            RETURNING user_id, name, email, role, created_at;
            """,
            (name, email, password, "user")
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
                "role": new_user["role"],
                "created_at": str(new_user["created_at"]),
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

        user = get_user_by_email(cur, email)
        cur.close()
        conn.close()

        if not user or user["password_hash"] != password:
            raise HTTPException(
                status_code=401,
                detail="Неверный email или пароль"
            )

        if not user.get("is_active", True):
            raise HTTPException(
                status_code=403,
                detail="Ваш аккаунт заблокирован. Свяжитесь с администратором"
            )

        return {
            "message": "Вход выполнен",
            "user": {
                "user_id": user["user_id"],
                "name": user["name"],
                "email": user["email"],
                "role": user["role"],
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка входа: {str(e)}"
        )


@router.get("/admin/users")
def get_all_users(admin_id: int = Query(..., alias="admin_id")):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        ensure_admin(cur, admin_id)

        cur.execute(
            """
            SELECT user_id, name, email, role, created_at
            FROM users
            ORDER BY created_at DESC;
            """
        )
        users = cur.fetchall()

        cur.close()
        conn.close()

        return [
            {
                "user_id": row["user_id"],
                "name": row["name"],
                "email": row["email"],
                "role": row["role"],
                "created_at": str(row["created_at"]),
            }
            for row in users
        ]

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Admin users read error: {str(e)}"
        )


@router.put("/admin/users/{user_id}")
def update_user_role(user_id: int, data: dict):
    admin_id = data.get("admin_id")
    role = data.get("role", "").strip().lower()

    if not admin_id or role not in ["user", "admin"]:
        raise HTTPException(
            status_code=400,
            detail="admin_id and valid role are required"
        )

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        ensure_admin(cur, int(admin_id))

        if int(admin_id) == user_id and role != "admin":
            raise HTTPException(
                status_code=400,
                detail="Нельзя понижать себя"
            )

        cur.execute(
            "SELECT user_id FROM users WHERE user_id = %s;",
            (user_id,)
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Пользователь не найден")

        cur.execute(
            """
            UPDATE users
            SET role = %s
            WHERE user_id = %s
            RETURNING user_id, name, email, role, created_at;
            """,
            (role, user_id)
        )
        updated_user = cur.fetchone()

        log_admin_action(
            cur,
            int(admin_id),
            f"Изменена роль пользователя",
            "user",
            user_id,
            f"role={role}"
        )

        conn.commit()
        cur.close()
        conn.close()

        return {
            "user_id": updated_user["user_id"],
            "name": updated_user["name"],
            "email": updated_user["email"],
            "role": updated_user["role"],
            "is_active": updated_user.get("is_active", True),
            "created_at": str(updated_user["created_at"]),
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Update user role error: {str(e)}"
        )


@router.put("/admin/users/{user_id}/block")
def toggle_user_block(user_id: int, data: dict):
    """Заблокировать или разблокировать пользователя"""
    admin_id = data.get("admin_id")
    is_active = data.get("is_active", True)

    if not admin_id:
        raise HTTPException(status_code=400, detail="admin_id is required")

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        ensure_admin(cur, int(admin_id))

        if int(admin_id) == user_id:
            raise HTTPException(status_code=400, detail="Нельзя блокировать себя")

        # Проверяем, существует ли поле is_active, если нет - добавляем его
        cur.execute("""
            SELECT column_name FROM information_schema.columns 
            WHERE table_name='users' AND column_name='is_active'
        """)
        if not cur.fetchone():
            cur.execute("ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT TRUE;")
            conn.commit()

        cur.execute(
            "SELECT user_id FROM users WHERE user_id = %s;",
            (user_id,)
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Пользователь не найден")

        cur.execute(
            """
            UPDATE users
            SET is_active = %s
            WHERE user_id = %s
            RETURNING user_id, name, email, role, is_active, created_at;
            """,
            (is_active, user_id)
        )
        updated_user = cur.fetchone()

        action = "разблокирован" if is_active else "заблокирован"
        log_admin_action(
            cur,
            int(admin_id),
            f"Пользователь {action}",
            "user",
            user_id,
            f"is_active={is_active}"
        )

        conn.commit()
        cur.close()
        conn.close()

        return {
            "user_id": updated_user["user_id"],
            "name": updated_user["name"],
            "email": updated_user["email"],
            "role": updated_user["role"],
            "is_active": updated_user.get("is_active", True),
            "created_at": str(updated_user["created_at"]),
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Toggle user block error: {str(e)}"
        )


@router.get("/admin/stats")
def get_admin_stats(admin_id: int = Query(..., alias="admin_id")):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        ensure_admin(cur, admin_id)

        cur.execute("SELECT COUNT(*) AS total_users FROM users;")
        total_users = cur.fetchone()["total_users"]

        cur.execute("SELECT COUNT(*) AS total_photos FROM photos;")
        total_photos = cur.fetchone()["total_photos"]

        cur.execute("SELECT COUNT(*) AS total_requests FROM ai_requests;")
        total_requests = cur.fetchone()["total_requests"]

        cur.close()
        conn.close()

        return {
            "total_users": total_users,
            "total_photos": total_photos,
            "total_requests": total_requests,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Admin stats read error: {str(e)}"
        )


@router.get("/admin/metadata")
def get_admin_metadata(admin_id: int = Query(..., alias="admin_id")):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        ensure_admin(cur, admin_id)

        cur.execute(
            """
            SELECT user_id, name, email, role, created_at, is_active
            FROM users
            ORDER BY created_at DESC;
            """
        )
        users = cur.fetchall()

        cur.execute("SELECT COUNT(*) AS total_users FROM users;")
        total_users = cur.fetchone()["total_users"]

        cur.execute("SELECT COUNT(*) AS total_photos FROM photos;")
        total_photos = cur.fetchone()["total_photos"]

        cur.execute("SELECT COUNT(*) AS total_requests FROM ai_requests;")
        total_requests = cur.fetchone()["total_requests"]

        lists = fetch_admin_lists(cur)

        cur.execute(
            """
            SELECT al.audit_id,
                   al.admin_id,
                   u.name AS admin_name,
                   al.action,
                   al.target_type,
                   al.target_id,
                   al.details,
                   al.created_at
            FROM audit_logs al
            LEFT JOIN users u ON u.user_id = al.admin_id
            ORDER BY al.created_at DESC
            LIMIT 20;
            """
        )
        audit_rows = cur.fetchall()

        cur.execute(
            """
            SELECT
                ar.request_id,
                ar.request_date,
                ar.status,
                p.photo_path,
                p.user_id,
                u.email AS user_email,
                rr.confidence_score,
                b.brand_name,
                c.category_name,
                cm.model_name
            FROM ai_requests ar
            JOIN photos p ON p.photo_id = ar.photo_id
            LEFT JOIN users u ON u.user_id = p.user_id
            LEFT JOIN recognition_results rr ON rr.request_id = ar.request_id
            LEFT JOIN brands b ON b.brand_id = rr.brand_id
            LEFT JOIN categories c ON c.category_id = rr.category_id
            LEFT JOIN clothing_models cm ON cm.model_id = rr.model_id
            ORDER BY ar.request_date DESC
            LIMIT 40;
            """
        )
        recognition_rows = cur.fetchall()

        cur.close()
        conn.close()

        return {
            "users": [
                {
                    "user_id": row["user_id"],
                    "name": row["name"],
                    "email": row["email"],
                    "role": row["role"],
                    "is_active": row.get("is_active", True),
                    "created_at": str(row["created_at"]),
                }
                for row in users
            ],
            "stats": {
                "total_users": total_users,
                "total_photos": total_photos,
                "total_requests": total_requests,
            },
            "audit_logs": [
                {
                    "audit_id": row["audit_id"],
                    "admin_id": row["admin_id"],
                    "admin_name": row["admin_name"],
                    "action": row["action"],
                    "target_type": row["target_type"],
                    "target_id": row["target_id"],
                    "details": row["details"],
                    "created_at": str(row["created_at"]),
                }
                for row in audit_rows
            ],
            "recognition_logs": [
                {
                    "request_id": row["request_id"],
                    "request_date": str(row["request_date"]),
                    "status": row["status"],
                    "photo_path": row["photo_path"],
                    "user_id": row["user_id"],
                    "user_email": row["user_email"],
                    "confidence_score": float(row["confidence_score"]) if row["confidence_score"] is not None else None,
                    "brand": row["brand_name"],
                    "category": row["category_name"],
                    "model": row["model_name"],
                }
                for row in recognition_rows
            ],
            **lists,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Admin metadata read error: {str(e)}"
        )


@router.post("/admin/brands")
def create_brand(data: dict):
    admin_id = data.get("admin_id")
    brand_name = data.get("brand_name", "").strip()

    if not admin_id or not brand_name:
        raise HTTPException(status_code=400, detail="admin_id and brand_name are required")

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        ensure_admin(cur, int(admin_id))

        cur.execute(
            "SELECT brand_id FROM brands WHERE brand_name = %s;",
            (brand_name,)
        )
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Бренд уже существует")

        cur.execute(
            "INSERT INTO brands (brand_name) VALUES (%s) RETURNING brand_id, brand_name;",
            (brand_name,)
        )
        new_brand = cur.fetchone()

        log_admin_action(
            cur,
            int(admin_id),
            "Добавлен бренд",
            "brand",
            new_brand["brand_id"],
            f"brand_name={brand_name}"
        )

        conn.commit()
        cur.close()
        conn.close()

        return {
            "brand_id": new_brand["brand_id"],
            "brand_name": new_brand["brand_name"],
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Create brand error: {str(e)}")


@router.post("/admin/models")
def create_model(data: dict):
    admin_id = data.get("admin_id")
    model_name = data.get("model_name", "").strip()
    brand_id = data.get("brand_id")
    category_id = data.get("category_id")

    if not admin_id or not model_name or not brand_id or not category_id:
        raise HTTPException(status_code=400, detail="admin_id, model_name, brand_id и category_id обязательны")

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        ensure_admin(cur, int(admin_id))

        cur.execute(
            "SELECT model_id FROM clothing_models WHERE model_name = %s AND brand_id = %s AND category_id = %s;",
            (model_name, brand_id, category_id)
        )
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Модель уже существует")

        cur.execute(
            "INSERT INTO clothing_models (model_name, brand_id, category_id) VALUES (%s, %s, %s) RETURNING model_id, model_name;",
            (model_name, brand_id, category_id)
        )
        new_model = cur.fetchone()

        log_admin_action(
            cur,
            int(admin_id),
            "Добавлена модель",
            "model",
            new_model["model_id"],
            f"model_name={model_name}, brand_id={brand_id}, category_id={category_id}"
        )

        conn.commit()
        cur.close()
        conn.close()

        return {
            "model_id": new_model["model_id"],
            "model_name": new_model["model_name"],
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Create model error: {str(e)}")


@router.post("/admin/offers")
def create_product_offer(data: dict):
    admin_id = data.get("admin_id")
    model_id = data.get("model_id")
    product_name = data.get("product_name", "").strip()
    color = data.get("color", "").strip()
    size = data.get("size", "").strip()
    description = data.get("description", "").strip()
    image_url = data.get("image_url", "").strip()
    store_id = data.get("store_id")
    price = data.get("price")
    product_url = data.get("product_url", "").strip()
    in_stock = data.get("in_stock")

    if not admin_id or not model_id or not product_name or not store_id or price is None or not product_url:
        raise HTTPException(
            status_code=400,
            detail="admin_id, model_id, product_name, store_id, price и product_url обязательны"
        )

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        ensure_admin(cur, int(admin_id))

        cur.execute(
            "SELECT product_id FROM products WHERE model_id = %s AND product_name = %s;",
            (model_id, product_name)
        )
        existing = cur.fetchone()
        if existing:
            product_id = existing["product_id"]
            cur.execute(
                """
                UPDATE products
                SET
                    color = COALESCE(NULLIF(%s, ''), color),
                    size = COALESCE(NULLIF(%s, ''), size),
                    description = COALESCE(NULLIF(%s, ''), description),
                    image_url = COALESCE(NULLIF(%s, ''), image_url)
                WHERE product_id = %s;
                """,
                (color, size, description, image_url, product_id)
            )
        else:
            cur.execute(
                """
                INSERT INTO products (model_id, product_name, color, size, description, image_url)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING product_id;
                """,
                (model_id, product_name, color or None, size or None, description or None, image_url or None)
            )
            product_id = cur.fetchone()["product_id"]

        cur.execute(
            "INSERT INTO product_offers (product_id, store_id, price, product_url, in_stock) VALUES (%s, %s, %s, %s, %s) RETURNING offer_id;",
            (product_id, store_id, price, product_url, bool(in_stock))
        )
        offer_id = cur.fetchone()["offer_id"]

        log_admin_action(
            cur,
            int(admin_id),
            "Добавлено торговое предложение",
            "product_offer",
            offer_id,
            f"product_id={product_id}, store_id={store_id}, price={price}"
        )

        conn.commit()
        cur.close()
        conn.close()

        return {
            "product_id": product_id,
            "offer_id": offer_id,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Create product offer error: {str(e)}")
