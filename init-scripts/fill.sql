INSERT INTO users (name, email, password_hash, role) VALUES
('Иван Иванов', '1', '1', 'user'),
('Петр Петров', '2', '2', 'admin');

INSERT INTO categories (category_name) VALUES ('Кроссовки'), ('Худи'), ('Джинсы');
INSERT INTO brands (brand_name) VALUES ('Nike'), ('Adidas'), ('Levis');
INSERT INTO stores (store_name, website, city) VALUES
('Wildberries', 'https://www.wildberries.ru', 'Москва'),
('Ozon', 'https://www.ozon.ru', 'Москва');

INSERT INTO clothing_models (brand_id, category_id, model_name, description) VALUES
(1, 1, 'Air Max 90', 'Кроссовки Nike'),
(2, 1, 'Superstar', 'Кроссовки Adidas'),
(2, 2, 'ENT22 HOODY Y', 'Худи Adidas'),
(3, 3, '501 Original', 'Джинсы Levis');

INSERT INTO products (model_id, product_name, color, size, description, image_url) VALUES
(1, 'Nike Air Max 90', 'Black', '42', 'Оригинальные кроссовки', ''),
(2, 'Adidas Superstar', 'White', '42', 'Классические кроссовки', ''),
(3, 'Adidas Hoodie ENT22', 'Black', 'M', 'Худи Adidas', ''),
(4, 'Levis 501 Jeans', 'Blue', '32', 'Джинсы Levis', '');

INSERT INTO product_offers (product_id, store_id, price, product_url, in_stock) VALUES
(1, 1, 12999, 'https://www.wildberries.ru/catalog/613286896/detail.aspx', TRUE),
(1, 2, 13999, 'https://www.ozon.ru/product/krossovki-nike-air-max-90-3436248243/', TRUE),
(2, 1, 8999, 'https://www.wildberries.ru/catalog/183985211/detail.aspx', TRUE),
(2, 2, 9499, 'https://www.ozon.ru/product/krossovki-superstar-1626674301/', TRUE),
(3, 1, 4999, 'https://www.wildberries.ru/catalog/394270025/detail.aspx', TRUE),
(3, 2, 5299, 'https://www.ozon.ru/product/hudi-adidas-ent22-hoody-y-420049272/', TRUE),
(4, 1, 7999, 'https://www.wildberries.ru/catalog/619960791/detail.aspx', TRUE),
(4, 2, 8499, 'https://www.ozon.ru/product/dzhinsy-levi-s-501-3531086311/', TRUE);