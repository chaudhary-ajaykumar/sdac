USE erp_import_export;

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INT DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    seller_port_id VARCHAR(50),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);

-- triiger so that quantity cannot be updated if its less that zero

DELIMITER $$

CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.quantity < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock quantity cannot be negative';
    END IF;
END $$

DELIMITER 


-- add new product and updated the detail

DELIMITER $$

CREATE PROCEDURE add_or_update_product (
    IN p_product_id INT,
    IN p_product_name VARCHAR(100),
    IN p_quantity INT,
    IN p_price DECIMAL(10,2),
    IN p_seller_port_id VARCHAR(50)
)
BEGIN
    IF p_product_id IS NOT NULL AND 
       EXISTS (SELECT 1 FROM products WHERE product_id = p_product_id AND seller_port_id = p_seller_port_id) THEN
       
        UPDATE products
        SET product_name = p_product_name,
            quantity = p_quantity,
            price = p_price
        WHERE product_id = p_product_id;
        
    ELSE
        INSERT INTO products (product_name, quantity, price, seller_port_id)
        VALUES (p_product_name, p_quantity, p_price, p_seller_port_id);
        
    END IF;
END $$

DELIMITER ;

-- delete product

DELIMITER $$

CREATE PROCEDURE delete_product (
    IN p_product_id INT,
    IN p_seller_port_id VARCHAR(50)
)
BEGIN
    DELETE FROM products
    WHERE product_id = p_product_id AND seller_port_id = p_seller_port_id;
END $$

DELIMITER ;



-- return stocl of a particular project
DELIMITER $$

CREATE FUNCTION get_product_stock (
    p_product_id INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE available_stock INT;

    SELECT quantity INTO available_stock
    FROM products
    WHERE product_id = p_product_id;

    RETURN available_stock;
END $$

DELIMITER ;


