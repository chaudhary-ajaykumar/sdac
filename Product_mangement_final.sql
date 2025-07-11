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
    product_name VARCHAR(100) NOT NULL,
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

-- View Ordered Products (for Seller)

CREATE PROCEDURE view_reported_products (
    IN p_seller_port_id VARCHAR(50)
)
BEGIN
    SELECT report_id, product_id, issue_type, status, action_taken, report_date, consumer_port_id
    FROM reported_products
    WHERE seller_port_id = p_seller_port_id;
END$$


-- Update Order Status (Shipped, Out for Delivery, Delivered)
CREATE PROCEDURE update_order_status_by_seller (
    IN p_order_id INT,
    IN p_stage VARCHAR(30)
)
BEGIN
    DECLARE placed BOOLEAN;
    DECLARE shipped_flag BOOLEAN;
    DECLARE out_flag BOOLEAN;
    DECLARE delivered_flag BOOLEAN;

    SELECT order_placed, shipped, out_for_delivery, delivered
    INTO placed, shipped_flag, out_flag, delivered_flag
    FROM orders
    WHERE order_id = p_order_id;

    IF placed = 0 THEN
       select 'Order must be placed before updating status' as message;

    ELSEIF p_stage = 'shipped' THEN
        IF shipped_flag = 0 THEN
            UPDATE orders SET shipped = TRUE WHERE order_id = p_order_id;
            SELECT ' Order marked as shipped' AS message;
        ELSE
            select 'Order already marked as shipped' as message;
        END IF;

    ELSEIF p_stage = 'out_for_delivery' THEN
        IF shipped_flag = 1 AND out_flag = 0 THEN
            UPDATE orders SET out_for_delivery = TRUE WHERE order_id = p_order_id;
            SELECT ' Order marked as out for delivery' AS message;
        ELSEIF shipped_flag = 0 THEN
            select 'Cannot mark out for delivery before shipping' as message;
        ELSE
            select 'Order already marked as out for delivery '  as message;
        END IF;

    ELSEIF p_stage = 'delivered' THEN
        IF out_flag = 1 AND delivered_flag = 0 THEN
            UPDATE orders SET delivered = TRUE WHERE order_id = p_order_id;
            SELECT 'Order marked as delivered' AS message;
        ELSEIF out_flag = 0 THEN
              select  'Cannot mark delivered before out for delivery' AS message;
        ELSE
              select 'Order already marked as delivered' AS message;
        END IF;

    ELSE
        select 'Invalid stage. Use: shipped, out_for_delivery, delivered' AS message;
    END IF;
END$$

-- View Reported Products (by Seller)
CREATE PROCEDURE view_reported_products (
    IN p_seller_port_id VARCHAR(50)
)
BEGIN
    SELECT rp.report_id, rp.product_id, p.product_name, rp.issue_type, rp.solution, rp.report_date,
           rp.consumer_port_id
    FROM reported_products rp
    JOIN products p ON rp.product_id = p.product_id
    WHERE p.seller_port_id = p_seller_port_id;
END$$

-- Mark Report as Solved

CREATE PROCEDURE solve_reported_product (
    IN p_report_id INT,
    IN p_seller_port_id VARCHAR(50)
)
BEGIN
    UPDATE reported_products
    SET status = 'Solved'
    WHERE report_id = p_report_id AND seller_port_id = p_seller_port_id;

    IF ROW_COUNT() = 0 THEN -- count the no of row effected built in finction
       SELECT 'Report ID is invalid or does not belong to this seller.' AS message;
    ELSE
        SELECT 'Report marked as solved' AS message;
    END IF;
END$$



-- TRIGGERS


-- Auto Suggest Action Based on Issue Type
CREATE TRIGGER trg_suggest_action
BEFORE INSERT ON reported_products
FOR EACH ROW
BEGIN
    CASE NEW.issue_type
        WHEN 'Damage' THEN
            SET NEW.action_taken = 'Send Replacement';
        WHEN 'Wrong Product' THEN
            SET NEW.action_taken = 'Initiate Return';
        WHEN 'Delayed' THEN
            SET NEW.action_taken = 'Apologize and Expedite';
        WHEN 'Still Not Received' THEN
            SET NEW.action_taken = 'Investigate Logistics';
        WHEN 'Missing' THEN
            SET NEW.action_taken = 'Check Packaging';
        ELSE
            SET NEW.action_taken = 'Pending Review';
    END CASE;
END$$

-- Prevent Negative Stock Quantity
CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.quantity < 0 THEN
        select 'Stock cannot be negative' AS message;
    END IF;
END$$

DELIMITER ;



-- test case
/*
CALL add_product('Test Widget', 100, 49.99, 'SELLER001');

INSERT INTO seller_port (port_id, password, location)
VALUES ('SELLER001', 'test@123', 'Mumbai');

SELECT * FROM seller_port WHERE port_id = 'SELLER001';


CALL add_product('Eco Bottle', 50, 129.99, 'SELLER001');

SELECT product_id FROM products WHERE product_name = 'Eco Bottle';

CALL update_product_name(3, 'Eco Flask');
CALL update_product_price(3, 200);
CALL restock_product(3, 20);
CALL delete_product(3);

SELECT * FROM products WHERE product_id = 3;


CALL add_product('Cargo Box', 10, 499.00, 'SELLER001');
SELECT product_id FROM products WHERE product_name = 'Cargo Box';

INSERT INTO consumer_port (port_id, password, location) 
VALUES ('CONSUMER001', 'pass123', 'Chennai');

INSERT INTO orders (
    product_id, consumer_port_id, seller_port_id, quantity, order_date
) VALUES (
    4, 'CONSUMER001', 'SELLER001', 1, CURDATE()
);

CALL delete_product(4);



CALL view_seller_products_with_sales('SELLER001', '');


CALL add_product('Iron Pipes', 100, 79.99, 'SELLER001');
CALL add_product('Plastic Sheets', 200, 59.50, 'SELLER001');
CALL add_product('Wooden Planks', 150, 120.00, 'SELLER001');

SELECT product_id, product_name FROM products WHERE seller_port_id = 'SELLER001';


-- Assuming product_id = 5 for Iron Pipes
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date)
VALUES (5, 'CONSUMER001', 'SELLER001', 10, CURDATE());

-- product_id = 6 for Plastic Sheets
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date)
VALUES (6, 'CONSUMER001', 'SELLER001', 5, CURDATE());

-- product_id = 7 for Wooden Planks
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date)
VALUES (7, 'CONSUMER001', 'SELLER001', 2, CURDATE());


CALL view_seller_products_with_sales('SELLER001', '');
CALL view_seller_products_with_sales('SELLER001', 'Plastic');
CALL view_seller_products_with_sales('SELLER001', NULL);

-- Insert a new product (no order yet)
CALL add_product('Aluminum Rods', 70, 150.00, 'SELLER001');

-- Then call:
CALL view_seller_products_with_sales('SELLER001', 'Aluminum');

-- Create a dummy seller
INSERT INTO seller_port (port_id, password, location);


CALL view_seller_products_with_sales('INVALID_ID', '');

VALUES ('SELLER002', 'test123', 'Pune');

-- Now run:
CALL view_seller_products_with_sales('SELLER002', '');


CALL view_seller_products_with_sales('SELLER001', '');
CALL view_seller_products_with_sales('SELLER001', 'Plastic');
CALL view_seller_products_with_sales('SELLER001', NULL);

INSERT INTO seller_port (port_id, password, location)
VALUES ('SELLER003', 'test123', 'Kolkata');
CALL view_seller_products_with_sales('SELLER002', '');


CALL add_product('Glass Panels', 30, 199.99, 'SELLER001');
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date)
VALUES (/* use product_id for Glass Panels , 'CONSUMER001', 'SELLER001', 2, CURDATE());
CALL view_seller_products_with_sales('SELLER001', '');

select * from orders;
CALL update_order_status_by_seller(1, 'shipped');

CALL update_order_status_by_seller(2, 'out_for_delivery');seller_port
CALL update_order_status_by_seller(1, 'delivered');

INSERT INTO reported_products (
    consumer_port_id,
    seller_port_id,
    product_id,
    issue_type
) VALUES (
    'CONSUMER001',
    'SELLER001',
    1,
    'Damage'
);
select * from ;
SELECT * FROM reported_products;
CALL view_reported_products('SELLER001');
CALL solve_reported_product(4, 'SELLER001');
SELECT * FROM reported_products WHERE report_id = 2;

*/
