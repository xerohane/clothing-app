from fastapi import APIRouter, HTTPException
from psycopg2.extras import RealDictCursor

from database import get_db_connection

router = APIRouter()


@router.get("/history/{user_id}")
def get_recognition_history(user_id: int):
    query = """
    SELECT
        ar.request_id,
        ar.request_date,
        ar.status,
        p.photo_path,
        rr.confidence_score,
        b.brand_name,
        c.category_name,
        cm.model_name
    FROM ai_requests ar
    JOIN photos p ON p.photo_id = ar.photo_id
    LEFT JOIN recognition_results rr ON rr.request_id = ar.request_id
    LEFT JOIN brands b ON b.brand_id = rr.brand_id
    LEFT JOIN categories c ON c.category_id = rr.category_id
    LEFT JOIN clothing_models cm ON cm.model_id = rr.model_id
    WHERE p.user_id = %s
    ORDER BY ar.request_date DESC;
    """

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute(query, (user_id,))
        rows = cur.fetchall()

        cur.close()
        conn.close()

        result = []
        for row in rows:
            result.append({
                "request_id": row["request_id"],
                "request_date": str(row["request_date"]),
                "status": row["status"],
                "photo_path": row["photo_path"],
                "brand": row["brand_name"],
                "category": row["category_name"],
                "model": row["model_name"],
                "confidence_score": float(row["confidence_score"])
                if row["confidence_score"] is not None
                else None,
            })

        return result

    except Exception as e:
        print("HISTORY ERROR:", str(e))
        raise HTTPException(
            status_code=500,
            detail=f"History read error: {str(e)}"
        )


@router.delete("/history/{user_id}")
def clear_recognition_history(user_id: int):
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            """
            DELETE FROM photos
            WHERE user_id = %s;
            """,
            (user_id,)
        )

        deleted_count = cur.rowcount
        conn.commit()

        cur.close()
        conn.close()

        return {
            "message": "История очищена",
            "deleted_photos": deleted_count
        }

    except Exception as e:
        print("HISTORY CLEAR ERROR:", str(e))
        raise HTTPException(
            status_code=500,
            detail=f"History clear error: {str(e)}"
        )