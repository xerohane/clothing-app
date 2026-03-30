from fastapi import APIRouter, HTTPException
from psycopg2.extras import RealDictCursor

from database import get_db_connection

router = APIRouter()


@router.post("/favorites/add")
def add_to_favorites(data: dict):
    user_id = data.get("user_id")
    product_id = data.get("product_id")

    if not user_id or not product_id:
        raise HTTPException(status_code=400, detail="user_id and product_id are required")

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            """
            INSERT INTO favorites (user_id, product_id)
            VALUES (%s, %s)
            ON CONFLICT (user_id, product_id) DO NOTHING;
            """,
            (user_id, product_id)
        )

        conn.commit()
        cur.close()
        conn.close()

        return {"message": "Товар добавлен в избранное"}

    except Exception as e:
        print("FAVORITES ADD ERROR:", str(e))
        raise HTTPException(status_code=500, detail=f"Favorites error: {str(e)}")


@router.get("/favorites/{user_id}")
def get_favorites(user_id: int):
    query = """
    SELECT
        f.favorite_id,
        f.added_at,
        p.product_id,
        p.product_name,
        b.brand_name,
        c.category_name,
        cm.model_name,
        s.store_name,
        po.price,
        po.product_url,
        po.in_stock
    FROM favorites f
    JOIN products p ON p.product_id = f.product_id
    JOIN clothing_models cm ON cm.model_id = p.model_id
    JOIN brands b ON b.brand_id = cm.brand_id
    JOIN categories c ON c.category_id = cm.category_id
    LEFT JOIN product_offers po ON po.product_id = p.product_id
    LEFT JOIN stores s ON s.store_id = po.store_id
    WHERE f.user_id = %s
    ORDER BY f.added_at DESC, p.product_id, s.store_name;
    """

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(query, (user_id,))
        rows = cur.fetchall()
        cur.close()
        conn.close()

        grouped = {}

        for row in rows:
            product_id = row["product_id"]

            if product_id not in grouped:
                grouped[product_id] = {
                    "favorite_id": row["favorite_id"],
                    "product_id": row["product_id"],
                    "product_name": row["product_name"],
                    "brand": row["brand_name"],
                    "category": row["category_name"],
                    "model": row["model_name"],
                    "added_at": str(row["added_at"]),
                    "offers": []
                }

            if row["store_name"] is not None:
                grouped[product_id]["offers"].append({
                    "store": row["store_name"],
                    "price": float(row["price"]) if row["price"] is not None else None,
                    "url": row["product_url"],
                    "in_stock": row["in_stock"]
                })

        return list(grouped.values())

    except Exception as e:
        print("FAVORITES GET ERROR:", str(e))
        raise HTTPException(status_code=500, detail=f"Favorites read error: {str(e)}")


@router.post("/favorites/remove")
def remove_from_favorites(data: dict):
    user_id = data.get("user_id")
    product_id = data.get("product_id")

    if not user_id or not product_id:
        raise HTTPException(status_code=400, detail="user_id and product_id are required")

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            """
            DELETE FROM favorites
            WHERE user_id = %s AND product_id = %s;
            """,
            (user_id, product_id)
        )

        conn.commit()
        cur.close()
        conn.close()

        return {"message": "Товар удален из избранного"}

    except Exception as e:
        print("FAVORITES REMOVE ERROR:", str(e))
        raise HTTPException(status_code=500, detail=f"Favorites remove error: {str(e)}")