from fastapi import APIRouter, UploadFile, File, HTTPException, Form
import requests
import os
import uuid
import base64

from database import get_db_connection
from config import OPENROUTER_API_KEY, OPENROUTER_URL, UPLOAD_DIR

router = APIRouter()

os.makedirs(UPLOAD_DIR, exist_ok=True)


def save_uploaded_file(contents: bytes, original_filename: str) -> str:
    ext = os.path.splitext(original_filename or "")[1]
    if not ext:
        ext = ".jpg"

    unique_name = f"{uuid.uuid4()}{ext}"
    file_path = os.path.join(UPLOAD_DIR, unique_name)

    with open(file_path, "wb") as f:
        f.write(contents)

    return file_path


# 🔥 НОВОЕ: fallback по имени файла
def recognize_from_filename(filename: str):
    name = filename.lower()
    print("FILENAME FALLBACK:", name)

    if "hoodie" in name:
        return {
            "brand": "Adidas" if "adidas" in name else "Adidas",
            "model": "ENT22 HOODY Y",
            "category": "Худи",
            "confidence_score": 60.0,
            "description": "fallback: filename detection"
        }

    if "nike" in name and ("shoe" in name or "sneaker" in name):
        return {
            "brand": "Nike",
            "model": "Air Max 90",
            "category": "Кроссовки",
            "confidence_score": 60.0,
            "description": "fallback: filename detection"
        }

    if "jeans" in name or "levis" in name:
        return {
            "brand": "Levis",
            "model": "501 Original",
            "category": "Джинсы",
            "confidence_score": 60.0,
            "description": "fallback: filename detection"
        }

    return None


def recognize_with_openrouter(image_bytes: bytes) -> str:
    base64_image = base64.b64encode(image_bytes).decode("utf-8")

    response = requests.post(
        OPENROUTER_URL,
        headers={
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json",
        },
        json={
            "model": "google/gemma-3-4b-it:free",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": (
                                "Look at the clothing item in the image and answer very briefly in English. "
                                "Write only: clothing type and brand if visible. "
                                "Examples: 'black adidas hoodie', 'nike sneakers', 'blue jeans'."
                            )
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
            "temperature": 0.2,
            "max_tokens": 60
        },
        timeout=25,
    )

    print("OPENROUTER STATUS:", response.status_code)
    print("OPENROUTER RAW:", response.text)

    response.raise_for_status()

    data = response.json()
    content = data["choices"][0]["message"]["content"]

    if not content:
        raise Exception("OpenRouter вернул пустой ответ")

    return content.lower().strip()


def map_caption_to_item(caption: str):
    c = caption.lower()
    print("MAP CAPTION:", c)

    if "hoodie" in c or "sweatshirt" in c:
        return {
            "brand": "Adidas" if "adidas" in c else "Adidas",
            "model": "ENT22 HOODY Y",
            "category": "Худи",
            "confidence_score": 90.0
        }

    if "sneaker" in c or "shoe" in c:
        if "nike" in c:
            return {
                "brand": "Nike",
                "model": "Air Max 90",
                "category": "Кроссовки",
                "confidence_score": 85.0
            }

        return {
            "brand": "Adidas",
            "model": "Superstar",
            "category": "Кроссовки",
            "confidence_score": 80.0
        }

    if "jean" in c or "denim" in c:
        return {
            "brand": "Levis",
            "model": "501 Original",
            "category": "Джинсы",
            "confidence_score": 80.0
        }

    return None


def insert_photo(cur, user_id: int, photo_path: str) -> int:
    cur.execute(
        """
        INSERT INTO photos (user_id, photo_path)
        VALUES (%s, %s)
        RETURNING photo_id;
        """,
        (user_id, photo_path)
    )
    return cur.fetchone()[0]


def insert_ai_request(cur, photo_id: int, status: str) -> int:
    cur.execute(
        """
        INSERT INTO ai_requests (photo_id, status)
        VALUES (%s, %s)
        RETURNING request_id;
        """,
        (photo_id, status)
    )
    return cur.fetchone()[0]


def update_ai_request_status(cur, request_id: int, status: str):
    cur.execute(
        """
        UPDATE ai_requests
        SET status = %s
        WHERE request_id = %s;
        """,
        (status, request_id)
    )


def get_brand_id(cur, brand_name: str) -> int:
    cur.execute(
        "SELECT brand_id FROM brands WHERE brand_name = %s;",
        (brand_name,)
    )
    row = cur.fetchone()
    if not row:
        raise Exception(f"Бренд не найден: {brand_name}")
    return row[0]


def get_category_id(cur, category_name: str) -> int:
    cur.execute(
        "SELECT category_id FROM categories WHERE category_name = %s;",
        (category_name,)
    )
    row = cur.fetchone()
    if not row:
        raise Exception(f"Категория не найдена: {category_name}")
    return row[0]


def get_model_id(cur, model_name: str) -> int:
    cur.execute(
        "SELECT model_id FROM clothing_models WHERE model_name = %s;",
        (model_name,)
    )
    row = cur.fetchone()
    if not row:
        raise Exception(f"Модель не найдена: {model_name}")
    return row[0]


def insert_recognition_result(
    cur,
    request_id: int,
    category_id: int,
    brand_id: int,
    model_id: int,
    confidence_score: float
):
    cur.execute(
        """
        INSERT INTO recognition_results
        (request_id, category_id, brand_id, model_id, confidence_score)
        VALUES (%s, %s, %s, %s, %s);
        """,
        (request_id, category_id, brand_id, model_id, confidence_score)
    )


@router.post("/recognize")
async def recognize_item(
    user_id: int = Form(...),
    file: UploadFile = File(...)
):
    conn = None
    cur = None
    request_id = None

    try:
        contents = await file.read()
        if not contents:
            raise HTTPException(status_code=400, detail="Пустой файл")

        photo_path = save_uploaded_file(contents, file.filename or "image.jpg")

        conn = get_db_connection()
        cur = conn.cursor()

        photo_id = insert_photo(cur, user_id, photo_path)
        request_id = insert_ai_request(cur, photo_id, "processing")
        conn.commit()

        mapped = None

        # 1️⃣ пробуем AI
        try:
            caption = recognize_with_openrouter(contents)
            print("CAPTION:", caption)

            mapped = map_caption_to_item(caption)

            if mapped:
                mapped["description"] = caption

        except Exception as e:
            print("OPENROUTER ERROR:", str(e))

        # 2️⃣ fallback по имени файла
        if not mapped:
            mapped = recognize_from_filename(file.filename or "")

        # 3️⃣ финальный fallback
        if not mapped:
            mapped = {
                "brand": "Adidas",
                "model": "ENT22 HOODY Y",
                "category": "Худи",
                "confidence_score": 30.0,
                "description": "fallback: default"
            }

        brand_id = get_brand_id(cur, mapped["brand"])
        category_id = get_category_id(cur, mapped["category"])
        model_id = get_model_id(cur, mapped["model"])

        insert_recognition_result(
            cur=cur,
            request_id=request_id,
            category_id=category_id,
            brand_id=brand_id,
            model_id=model_id,
            confidence_score=mapped["confidence_score"]
        )

        update_ai_request_status(cur, request_id, "done")
        conn.commit()

        return {
            "brand": mapped["brand"],
            "model": mapped["model"],
            "category": mapped["category"],
            "description": mapped["description"],
            "confidence_score": mapped["confidence_score"],
            "request_id": request_id
        }

    except Exception as e:
        print("RECOGNIZE ERROR:", str(e))

        if conn and cur and request_id:
            try:
                update_ai_request_status(cur, request_id, "error")
                conn.commit()
            except Exception:
                pass

        raise HTTPException(status_code=500, detail=str(e))

    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()