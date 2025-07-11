-- 🎯 DATABASE INITIALIZATION

CREATE DATABASE IF NOT EXISTS ImportExport;
USE ImportExport;


--  TABLE DEFINITIONS

-- Consumer Table
CREATE TABLE IF NOT EXISTS consumer_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    location VARCHAR(100),
    role VARCHAR(20) DEFAULT 'Consumer'
);

-- Seller Table
CREATE TABLE IF NOT EXISTS seller_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    location VARCHAR(100),
    role VARCHAR(20) DEFAULT 'Seller'
);

-- Products Table
CREATE TABLE IF NOT EXISTS products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) Unique NOT NULL,
    quantity INT DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    seller_port_id VARCHAR(50),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);
select * from products having quantity < 0; 


CREATE TABLE IF NOT EXISTS products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) Uniproductsque NOT NULL,
    quantity INT DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    seller_port_id VARCHAR(50),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);


-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    consumer_port_id VARCHAR(50),
    seller_port_id VARCHAR(50),
    quantity INT NOT NULL,
    order_date DATE,
    order_placed BOOLEAN DEFAULT TRUE,
    shipped BOOLEAN DEFAULT FALSE,
    out_for_delivery BOOLEAN DEFAULT FALSE,
    delivered BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (consumer_port_id) REFERENCES consumer_port(port_id),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);

-- Reported Products Table
CREATE TABLE IF NOT EXISTS reported_products (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    consumer_port_id VARCHAR(50),
    seller_port_id VARCHAR(50),
    product_id INT,
    issue_type ENUM('Damage', 'Wrong Product', 'Delayed', 'Still Not Received', 'Missing'),
    status ENUM('Solved', 'Pending...') DEFAULT 'Pending...',
    action_taken ENUM(
        'Yes', 'No', 'Send Replacement', 'Initiate Return', 'Apologize and Expedite',
        'Investigate Logistics', 'Check Packaging', 'Pending Review'
    ) DEFAULT 'Pending Review',
    report_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consumer_port_id) REFERENCES consumer_port(port_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);



-- STORED PROCEDURES

DELIMITER $$

-- Add a Product
CREATE PROCEDURE add_product (
    IN p_product_name VARCHAR(100),
    IN p_quantity INT,
    IN p_price DECIMAL(10, 2),
    IN p_seller_port_id VARCHAR(50)
)
BEGIN
    INSERT INTO products (product_name, quantity, price, seller_port_id)
    VALUES (p_product_name, p_quantity, p_price, p_seller_port_id);
    SELECT 'Product inserted successfully' AS message;
END$$

-- Update Product Name
CREATE PROCEDURE update_product_name (
    IN p_product_id INT,
    IN p_product_name VARCHAR(100)
)
BEGIN
    UPDATE products
    SET product_name = p_product_name
    WHERE product_id = p_product_id;
    SELECT 'Product name updated successfully' AS message;
END$$

-- Update Product Price
CREATE PROCEDURE update_product_price (
    IN p_product_id INT,
    IN p_price DECIMAL(10,2)
)
BEGIN
    UPDATE products
    SET price = p_price
    WHERE product_id = p_product_id;
    SELECT 'Product price updated successfully' AS message;
END$$

-- Restock Product

CREATE PROCEDURE restock_product (
    IN p_product_id INT,
    IN p_add_quantity INT
)
BEGIN
    UPDATE products
    SET quantity = quantity + p_add_quantity
    WHERE product_id = p_product_id;

    IF (SELECT quantity FROM products WHERE product_id = p_product_id) < 10 THEN
        SELECT CONCAT(' Quantity is still low. Current: ', quantity) AS message
        FROM products
        WHERE product_id = p_product_id;
    ELSE
        SELECT ' Restocked successfully' AS message;
    END IF;
END$$



-- Delete Product (only if no orders)
CREATE PROCEDURE delete_product (
    IN p_product_id INT
)
BEGIN
    DECLARE order_count INT;
    SELECT COUNT(*) INTO order_count FROM orders WHERE product_id = p_product_id;

    IF order_count = 0 THEN
        DELETE FROM products WHERE product_id = p_product_id;
        SELECT 'Product deleted successfully' AS message;
    ELSE
       select 'Cannot delete product with existing orders.' as message;
    END IF;
END$$

-- View Seller's Products + Sales Summary (Search Option)

CREATE PROCEDURE view_seller_products_with_sales (
    IN p_seller_port_id VARCHAR(50),
    IN p_search_name VARCHAR(100),
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    -- Default value logic
    IF p_limit IS NULL OR p_limit = 0 THEN
        SET p_limit = 20;
    END IF;

    IF p_offset IS NULL THEN
        SET p_offset = 0;
    END IF;

    SELECT 
        p.product_id,
        p.product_name,
        p.quantity AS current_stock,
        p.price,
        IFNULL(SUM(o.quantity), 0) AS total_units_sold,
        IFNULL(SUM(o.quantity * p.price), 0) AS total_revenue
    FROM products p
    LEFT JOIN orders o ON p.product_id = o.product_id
    WHERE p.seller_port_id = p_seller_port_id
      AND (p.product_name LIKE CONCAT('%', p_search_name, '%') OR p_search_name IS NULL OR p_search_name = '')
    GROUP BY p.product_id, p.product_name, p.quantity, p.price
    ORDER BY total_units_sold DESC
    LIMIT p_limit OFFSET p_offset;
END$$



-- Prevent Negative Stock Quantity
delimiter $$
CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.quantity < 0 THEN
        select 'Stock cannot be negative' AS message;
    END IF;
END$$

DELIMITER ;


CREATE TABLE IF NOT EXISTS products_backup (
    backup_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(100),
    quantity INT,
    price DECIMAL(10,2),
    seller_port_id VARCHAR(50),
    backup_action ENUM('INSERT', 'UPDATE', 'DELETE'),
    backup_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER trg_backup_product_insert
AFTER INSERT ON products
FOR EACH ROW
BEGIN
    INSERT INTO products_backup (product_id, product_name, quantity, price, seller_port_id, backup_action)
    VALUES (NEW.product_id, NEW.product_name, NEW.quantity, NEW.price, NEW.seller_port_id, 'INSERT');
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_backup_product_update
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    INSERT INTO products_backup (product_id, product_name, quantity, price, seller_port_id, backup_action)
    VALUES (NEW.product_id, NEW.product_name, NEW.quantity, NEW.price, NEW.seller_port_id, 'UPDATE');
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_backup_product_delete
AFTER DELETE ON products
FOR EACH ROW
BEGIN
    INSERT INTO products_backup (product_id, product_name, quantity, price, seller_port_id, backup_action)
    VALUES (OLD.product_id, OLD.product_name, OLD.quantity, OLD.price, OLD.seller_port_id, 'DELETE');
END$$
DELIMITER ;

