from fastapi import APIRouter, HTTPException
from psycopg2.extras import RealDictCursor

from database import get_db_connection

router = APIRouter()


@router.post("/search")
def search_items(data: dict):
    model = data.get("model", "").strip()

    if not model:
        raise HTTPException(status_code=400, detail="model is required")

    query = """
    SELECT
        p.product_id,
        cm.model_name,
        b.brand_name,
        c.category_name,
        p.product_name,
        s.store_name,
        po.price,
        po.product_url,
        po.in_stock
    FROM clothing_models cm
    JOIN brands b ON b.brand_id = cm.brand_id
    JOIN categories c ON c.category_id = cm.category_id
    JOIN products p ON p.model_id = cm.model_id
    JOIN product_offers po ON po.product_id = p.product_id
    JOIN stores s ON s.store_id = po.store_id
    WHERE cm.model_name = %s;
    """

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(query, (model,))
        rows = cur.fetchall()
        cur.close()
        conn.close()

        result = []
        for row in rows:
            result.append({
                "product_id": row["product_id"],
                "store": row["store_name"],
                "price": float(row["price"]),
                "url": row["product_url"],
                "product_name": row["product_name"],
                "brand": row["brand_name"],
                "category": row["category_name"],
                "in_stock": row["in_stock"]
            })

        return result

    except Exception as e:
        print("DB SEARCH ERROR:", str(e))
        raise HTTPException(status_code=500, detail=f"DB search error: {str(e)}")