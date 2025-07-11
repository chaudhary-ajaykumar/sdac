USE erp_import_export;

CREATE TABLE consumer_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    location VARCHAR(100),
    role VARCHAR(20) DEFAULT 'Consumer'
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

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INT DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    seller_port_id VARCHAR(50),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);


-- when order is placed quantity get less
DELIMITER $$

CREATE TRIGGER trg_reduce_stock_after_order
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    UPDATE products
    SET quantity = quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END $$

DELIMITER ;

-- check if the available quantity is available and insert the record into order and trigger automaticalluy handle stock deducation


DELIMITER $$

CREATE PROCEDURE place_order (
    IN p_product_id INT,
    IN p_consumer_port_id VARCHAR(50),
    IN p_quantity INT,
    IN p_order_date DATE
)
BEGIN
    DECLARE available_stock INT;

    SELECT quantity INTO available_stock
    FROM products
    WHERE product_id = p_product_id;

    IF available_stock >= p_quantity THEN
        INSERT INTO orders (
            product_id, consumer_port_id, quantity, order_date,
            order_placed, shipped, out_for_delivery, delivered
        )
        VALUES (
            p_product_id, p_consumer_port_id, p_quantity, p_order_date,
            TRUE, FALSE, FALSE, FALSE
        );
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough stock available to fulfill this order';
    END IF;
END $$

DELIMITER ;


-- used to update the order progress

DELIMITER $$

CREATE PROCEDURE update_order_status (
    IN p_order_id INT,
    IN p_stage VARCHAR(20)
)
BEGIN
    IF p_stage = 'shipped' THEN
        UPDATE orders
        SET shipped = TRUE
        WHERE order_id = p_order_id;

    ELSEIF p_stage = 'out_for_delivery' THEN
        UPDATE orders
        SET out_for_delivery = TRUE
        WHERE order_id = p_order_id;

    ELSEIF p_stage = 'delivered' THEN
        UPDATE orders
        SET delivered = TRUE
        WHERE order_id = p_order_id;

    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status stage';
    END IF;
END $$


-- get order_ status

DELIMITER $$

CREATE FUNCTION get_order_status (
    p_order_id INT
)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE status VARCHAR(50);
    DECLARE o_placed, o_shipped, o_out, o_delivered BOOLEAN;

    SELECT order_placed, shipped, out_for_delivery, delivered
    INTO o_placed, o_shipped, o_out, o_delivered
    FROM orders
    WHERE order_id = p_order_id;

    IF o_delivered THEN
        SET status = 'Delivered';
    ELSEIF o_out THEN
        SET status = 'Out for Delivery';
    ELSEIF o_shipped THEN
        SET status = 'Shipped';
    ELSEIF o_placed THEN
        SET status = 'Order Placed';
    ELSE
        SET status = 'Unknown';
    END IF;

    RETURN status;
END $$

DELIMITER ;

