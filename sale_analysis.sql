USE erp_import_export;

CREATE TABLE seller_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'Seller'
);

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INT DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    seller_port_id VARCHAR(50),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);


CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    consumer_port_id VARCHAR(50),
    quantity INT NOT NULL,
    order_date DATE,
    order_placed BOOLEAN DEFAULT TRUE,
    shipped BOOLEAN DEFAULT FALSE,
    out_for_delivery BOOLEAN DEFAULT FALSE,
    delivered BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (consumer_port_id) REFERENCES consumer_port(port_id)
);


-- montly report

DELIMITER $$

CREATE PROCEDURE monthly_sales_report (
    IN p_seller_port_id VARCHAR(50),
    IN p_month INT,     -- e.g., 6 for June
    IN p_year INT       -- e.g., 2025
)
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        SUM(o.quantity) AS total_units_sold,
        SUM(o.quantity * p.price) AS total_revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    WHERE p.seller_port_id = p_seller_port_id
      AND MONTH(o.order_date) = p_month
      AND YEAR(o.order_date) = p_year
    GROUP BY p.product_id, p.product_name;
END $$

DELIMITER ;

-- yearly report

DELIMITER $$

CREATE PROCEDURE yearly_sales_report (
    IN p_seller_port_id VARCHAR(50),
    IN p_year INT
)
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        SUM(o.quantity) AS total_units_sold,
        SUM(o.quantity * p.price) AS total_revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    WHERE p.seller_port_id = p_seller_port_id
      AND YEAR(o.order_date) = p_year
    GROUP BY p.product_id, p.product_name;
END $$

DELIMITER ;


-- get total sale return
DELIMITER $$

CREATE FUNCTION get_total_revenue (
    p_seller_port_id VARCHAR(50)
)
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(15,2);

    SELECT SUM(o.quantity * p.price)
    INTO total
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    WHERE p.seller_port_id = p_seller_port_id;

    RETURN IFNULL(total, 0.00);
END $$

-- top seelling [roduct

Seller (get_top_product)
DELIMITER $$

CREATE FUNCTION get_top_product (
    p_seller_port_id VARCHAR(50)
)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE top_product VARCHAR(100);

    SELECT p.product_name
    INTO top_product
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    WHERE p.seller_port_id = p_seller_port_id
    GROUP BY p.product_id
    ORDER BY SUM(o.quantity) DESC
    LIMIT 1;

    RETURN top_product;
END $$

DELIMITER ;

