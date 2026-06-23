CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stores (
    store_id SERIAL PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    website VARCHAR(255),
    city VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS brands (
    brand_id SERIAL PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS clothing_models (
    model_id SERIAL PRIMARY KEY,
    brand_id INT NOT NULL REFERENCES brands(brand_id) ON DELETE CASCADE,
    category_id INT NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    model_name VARCHAR(150) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    model_id INT NOT NULL REFERENCES clothing_models(model_id) ON DELETE CASCADE,
    product_name VARCHAR(150) NOT NULL,
    color VARCHAR(50),
    size VARCHAR(20),
    description TEXT,
    image_url VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS product_offers (
    offer_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    store_id INT NOT NULL REFERENCES stores(store_id) ON DELETE CASCADE,
    price NUMERIC(10,2) NOT NULL,
    product_url VARCHAR(255) NOT NULL,
    in_stock BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS photos (
    photo_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    photo_path VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ai_requests (
    request_id SERIAL PRIMARY KEY,
    photo_id INT NOT NULL REFERENCES photos(photo_id) ON DELETE CASCADE,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS recognition_results (
    result_id SERIAL PRIMARY KEY,
    request_id INT NOT NULL REFERENCES ai_requests(request_id) ON DELETE CASCADE,
    category_id INT NOT NULL REFERENCES categories(category_id),
    brand_id INT NOT NULL REFERENCES brands(brand_id),
    model_id INT NOT NULL REFERENCES clothing_models(model_id),
    confidence_score NUMERIC(5,2)
);

CREATE TABLE IF NOT EXISTS favorites (
    favorite_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, product_id)
);