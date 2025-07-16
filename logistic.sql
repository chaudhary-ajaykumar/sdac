create DATABASE Logistics;
USE Logistics;

-- Consumer Table
CREATE TABLE consumer_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    location VARCHAR(100),
    role VARCHAR(20) DEFAULT 'Consumer'
);

select * from products;
select * from orders;
UPDATE seller_port
SET password = SHA2('123456789', 256)
WHERE port_id = 'seller1';

SELECT * FROM orders WHERE seller_port_id = 'seller1';
SELECT * FROM orders WHERE consumer_port_id = 'user1';

-- Seller Table
CREATE TABLE seller_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    location VARCHAR(100),
    role VARCHAR(20) DEFAULT 'Selproductsler'
);

-- Products Table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INT DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    seller_port_id VARCHAR(50),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);

-- Orders Table
CREATE TABLE orders (
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
CREATE TABLE reported_products (    
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    consumer_port_id VARCHAR(50),
    seller_port_id VARCHAR(50),
    product_id INT,
    issue_type ENUM('Damage', 'Wrong Product', 'Delayed', 'Still Not Received', 'Missing'),
    status ENUM('Pending', 'Resolved') DEFAULT 'Pending',
    action_taken ENUM('Replacement' , 'Compensation', 'Resend'),
    report_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consumer_port_id) REFERENCES consumer_port(port_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);

-- Ensure port_id is unique across both consumer and seller
DELIMITER $$
CREATE FUNCTION is_port_id_unique(p_id VARCHAR(50))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE exists_count INT;
    SELECT 
        (SELECT COUNT(*) FROM consumer_port WHERE port_id = p_id) +
        (SELECT COUNT(*) FROM seller_port WHERE port_id = p_id)
    INTO exists_count;
    RETURN (exists_count = 0);
END$$
DELIMITER ;


-- Prevent duplicate port_id in consumer_port
DELIMITER $$
CREATE TRIGGER trg_consumer_port_unique
BEFORE INSERT ON consumer_port
FOR EACH ROW
BEGIN
    IF NOT is_port_id_unique(NEW.port_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'port_id already exists in either consumer_port or seller_port';
    END IF;
END$$
DELIMITER ;

-- Prevent duplicate port_id in seller_port
DELIMITER $$
CREATE TRIGGER trg_seller_port_unique
BEFORE INSERT ON seller_port
FOR EACH ROW
BEGIN
    IF NOT is_port_id_unique(NEW.port_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'port_id already exists in either seller_port or consumer_port';
    END IF;
END$$
DELIMITER ;


-- REGISTRATION PAGE
DELIMITER $$
CREATE PROCEDURE register_user (
    IN p_port_id VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_confirm_password VARCHAR(255),
    IN p_location VARCHAR(100),
    IN p_role VARCHAR(20)
)
BEGIN
    -- Check password and confirm password match
    IF p_password != p_confirm_password THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passwords do not match';
    END IF;

    -- Optional: Validate password length
    IF LENGTH(p_password) <= 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password must be at least 8 characters long';
    END IF;

    -- Insert based on role
    IF p_role = 'Consumer' THEN
        INSERT INTO consumer_port (port_id, password, location, role)
        VALUES (p_port_id, SHA2(p_password, 256), p_location, p_role);
    ELSEIF p_role = 'Seller' THEN
        INSERT INTO seller_port (port_id, password, location, role)
        VALUES (p_port_id, SHA2(p_password, 256), p_location, p_role);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid role. Must be Consumer or Seller';
    END IF;
END$$
DELIMITER ;

-- testconsumer_portconsumer_port
CALL register_user('user1', '123456789','123456789', 'Mumbai', 'Consumer');
CALL register_user('seller1', '123456789','123456789', 'Mumbai', 'Seller');

-- LOGIN PAGE
DELIMITER $$
CREATE FUNCTION verify_login (
    p_port_id VARCHAR(50),
    p_password VARCHAR(255),
    p_role VARCHAR(20)
)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE login_message VARCHAR(100);

    IF p_role = 'Consumer' THEN
        IF EXISTS (
            SELECT 1 FROM consumer_port
            WHERE port_id = p_port_id AND password = SHA2(p_password, 256) AND role = 'Consumer'
        ) THEN
            SET login_message = 'Consumer Login Success: Redirect to Consumer Dashboard';
        ELSE
            SET login_message = 'Login Failed: Invalid Consumer Credentials';
        END IF;

    ELSEIF p_role = 'Seller' THEN
        IF EXISTS (
            SELECT 1 FROM seller_port
            WHERE port_id = p_port_id AND password = SHA2(p_password, 256) AND role = 'Seller'
        ) THEN
            SET login_message = 'Seller Login Success: Redirect to Seller Dashboard';
        ELSE
            SET login_message = 'Login Failed: Invalid Seller Credentials';
        END IF;

    ELSE
        SET login_message = 'Login Failed: Unknown Role';
    END IF;

    RETURN login_message;
END$$
DELIMITER ;

--  EDIT PROFILE (Common for Consumer & Seller)
DELIMITER $$
CREATE PROCEDURE edit_profile (
    IN p_port_id VARCHAR(50),
    IN p_role VARCHAR(20),
    IN new_password VARCHAR(255),
    IN new_location VARCHAR(100),
    IN update_password_flag BOOLEAN,
    IN update_location_flag BOOLEAN,
    IN delete_flag BOOLEAN
)
BEGIN
    IF p_role = 'Consumer' THEN
        IF delete_flag THEN
            DELETE FROM consumer_port WHERE port_id = p_port_id;
        ELSE
            IF update_password_flag THEN
    UPDATE consumer_port
    SET password = SHA2(new_password, 256)
    WHERE port_id = p_port_id;
END IF;

            IF update_location_flag THEN
                UPDATE consumer_port SET location = new_location WHERE port_id = p_port_id;
            END IF;
        END IF;
    ELSEIF p_role = 'Seller' THEN
        IF delete_flag THEN
            CALL seller_delete_account_safe(p_port_id);
        ELSE
            IF update_password_flag THEN
    UPDATE seller_port
    SET password = SHA2(new_password, 256)
    WHERE port_id = p_port_id;
END IF;

            IF update_location_flag THEN
                UPDATE seller_port SET location = new_location WHERE port_id = p_port_id;
            END IF;
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid role. Must be Consumer or Seller';
    END IF;
END$$
DELIMITER ;

-- VIEW SELLER ACC

DELIMITER $$

CREATE PROCEDURE view_seller_account (
    IN p_port_id VARCHAR(50)
)
BEGIN
    SELECT
        port_id,
        location,
        role
    FROM seller_port
    WHERE port_id = p_port_id;
END$$

DELIMITER ;


-- Safely delete seller account
DELIMITER $$
CREATE PROCEDURE seller_delete_account_safe(IN p_seller VARCHAR(50))
BEGIN
    DECLARE prod_count INT;
    SELECT COUNT(*) INTO prod_count
    FROM products
    WHERE seller_port_id = p_seller;

    IF prod_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete seller: please remove all products first.';
    ELSE
        DELETE FROM seller_port WHERE port_id = p_seller;
    END IF;
END$$
DELIMITER ;
-- Test:
CALL seller_delete_account_safe('seller1');

DELIMITER $$

-- VIEW CONSUMER ACC

DELIMITER $$

CREATE PROCEDURE view_consumer_account (
    IN p_port_id VARCHAR(50)
)
BEGIN
    SELECT
        port_id,
        location,
        role
    FROM consumer_port
    WHERE port_id = p_port_id;
END$$

DELIMITER ;

-- DELETE CONSUMER ACC
DELIMITER $$

CREATE PROCEDURE delete_consumer_account (
    IN p_port_id VARCHAR(50)
)
BEGIN
    DECLARE order_count INT DEFAULT 0;

    -- Count the consumer's orders
    SELECT COUNT(*) INTO order_count
    FROM orders
    WHERE consumer_port_id = p_port_id;

    -- If no orders, delete
    IF order_count = 0 THEN
        DELETE FROM consumer_port
        WHERE port_id = p_port_id;
    ELSE
        -- If orders exist, raise an error with a clear message
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete consumer account: Delete or receive orders before deletion.';
    END IF;
END$$

DELIMITER ;


-- Test:
CALL edit_profile('consumer1', 'Consumer', 'newpass456', 'Bangalore Port', TRUE, TRUE, FALSE);
CALL edit_profile('seller1', 'Seller', 'newpass789', 'Hyderabad Port', TRUE, TRUE, FALSE);


-- CONSUMER DASHBOARD

-- when order is placed quantity get less
-- check is products is available or not 
DELIMITER &&
create trigger check_if_product_is_available
after insert on orders
for each row
begin 
update products set quantity =quantity - new.quantity where product_id = new.product_id;
end &&
delimiter ;

-- if product available then place order or update table orders
DELIMITER &&
create procedure order_product(p_product_id int , p_consumer_port_id int ,p_quantity int , p_seller_port_id int )
begin  
declare pro_quantity int;
 select quantity into pro_quantity from products where product_id=p_product_id ;
 if pro_quantity > 0 and p_quantity <= pro_quantity  then
   insert into orders (product_id,consumer_port_id,quantity ,order_date,seller_port_id) values(p_product_id  , p_consumer_port_id  ,p_quantity  ,curdate(),p_seller_port_id);
else 
    select 'order less quantity ' as message ;
end if;
end && 
delimiter ;

-- dashboard query to show order sumary

SELECT 
    o.product_id,
    p.product_name,
    o.quantity,
    o.consumer_port_id,
    cp.location AS consumer_port_location,
    o.order_date
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN consumer_port cp ON o.consumer_port_id = cp.port_id;


-- Update order quantity and adjust product stock
DELIMITER $$
CREATE PROCEDURE UpdateOrderQuantity (
    IN p_order_id INT,
    IN p_new_quantity INT
)
BEGIN
    DECLARE current_quantity INT;
    DECLARE product_id INT;
    DECLARE available_quantity INT;
    DECLARE quantity_difference INT;

    -- Get current quantity and product ID
    SELECT quantity, product_id INTO current_quantity, product_id
    FROM orders
    WHERE order_id = p_order_id;

    -- Calculate difference
    SET quantity_difference = p_new_quantity - current_quantity;
    IF quantity_difference > 0 THEN
        -- If increasing, check available stock
        SELECT quantity INTO available_quantity
        FROM products
        WHERE product_id = product_id;

        IF available_quantity >= quantity_difference THEN
            -- Reduce stock
            UPDATE products
            SET quantity = quantity - quantity_difference
            WHERE product_id = product_id;
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Not enough stock available.';
        END IF;

    ELSEIF quantity_difference < 0 THEN
        -- If decreasing, return stock
        UPDATE products
        SET quantity = quantity + ABS(quantity_difference)
        WHERE product_id = product_id;
    END IF;

    -- Update order quantity
    UPDATE orders
    SET quantity = p_new_quantity
    WHERE order_id = p_order_id;
END$$
DELIMITER ;

-- Update consumer ID for an order
DELIMITER $$
CREATE PROCEDURE UpdateOrderConsumer (
    IN p_order_id INT,
    IN p_new_consumer_port_id VARCHAR(50)
)
BEGIN
    UPDATE orders
    SET consumer_port_id = p_new_consumer_port_id
    WHERE order_id = p_order_id;
END$$
DELIMITER ;

-- 3️⃣ Update consumer location (address)
DELIMITER $$
CREATE PROCEDURE UpdateConsumerLocation (
    IN p_consumer_port_id VARCHAR(50),
    IN p_new_location VARCHAR(255)
)
BEGIN
    UPDATE consumer_port
    SET location = p_new_location
    WHERE port_id = p_consumer_port_id;
END$$
DELIMITER ;

-- Delete an order and restore product quantity
DELIMITER $$
CREATE PROCEDURE DeleteOrder (
    IN p_order_id INT
)
BEGIN
    DECLARE order_quantity INT;
    DECLARE v_product_id INT;

    -- Get quantity and product ID
    SELECT quantity, product_id INTO order_quantity, v_product_id
    FROM orders
    WHERE order_id = p_order_id;

    -- Restore quantity to stock
    UPDATE products
    SET quantity = quantity + order_quantity
    WHERE product_id = v_product_id;

    -- Delete the order
    DELETE FROM orders
    WHERE order_id = p_order_id;
END$$
DELIMITER ;

-- track order
DELIMITER $$
CREATE PROCEDURE get_order_status (
    IN p_order_id INT
)
BEGIN
    SELECT
        o.order_id,
        o.order_date,
        o.product_id,
        p.product_name,
        o.quantity,
        o.consumer_port_id,
        c.location AS consumer_port_location,
        o.seller_port_id,
        s.location AS seller_port_location,
        o.order_placed,
        o.shipped,
        o.out_for_delivery,
        o.delivered
    FROM orders o
    JOIN products p
        ON p.product_id = o.product_id
    JOIN consumer_port c
        ON c.port_id = o.consumer_port_id
    JOIN seller_port s
        ON s.port_id = o.seller_port_id
    WHERE o.order_id = p_order_id;
END$$
DELIMITER ;


-- update order status flag 
delimiter &&
create procedure order_flag( p_order_id int ,
    p_shipped BOOLEAN ,
    p_out_for_delivery BOOLEAN ,
    p_delivered BOOLEAN )
begin 
  declare placed,ship,out_deli,deli boolean;
  select order_placed,shipped,out_for_delivery,delivered into placed,ship,out_deli,deli from orders where order_id= p_order_id;
  if placed = 1  then 
    if ship =0 then
       update orders set shipped=ship where order_id= p_order_id;
	elseif out_deli =0 then
         update orders set out_for_delivery=p_out_for_delivery where order_id= p_order_id;
	elseif deli =0 then 
       update orders set delivered=p_delivered where order_id= p_order_id;
    end if ;
  else 
    select 'place order 1st ' as message ;
  end if ;
  end &&
  delimiter ;


-- more correct logic for order status as it alterDELIMITER $$
delimiter &&
CREATE PROCEDURE update_order_flag (
    IN p_order_id INT,
    IN p_stage VARCHAR(30)
)
BEGIN
    DECLARE placed BOOLEAN;
    DECLARE shipped_flag BOOLEAN;
    DECLARE out_flag BOOLEAN;
    DECLARE delivered_flag BOOLEAN;

    -- Get current status flags
    SELECT order_placed, shipped, out_for_delivery, delivered
    INTO placed, shipped_flag, out_flag, delivered_flag
    FROM orders
    WHERE order_id = p_order_id;

    -- Validate order placed
    IF placed = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order must be placed before updating status';    
    ELSEIF p_stage = 'shipped' THEN
        IF shipped_flag = 0 THEN
            UPDATE orders SET shipped = TRUE WHERE order_id = p_order_id;
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order already marked as shipped';
        END IF;
    ELSEIF p_stage = 'out_for_delivery' THEN
        IF shipped_flag = 1 AND out_flag = 0 THEN
            UPDATE orders SET out_for_delivery = TRUE WHERE order_id = p_order_id;
        ELSEIF shipped_flag = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot mark out for delivery before shipping';
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order already marked as out for delivery';
        END IF;
    ELSEIF p_stage = 'delivered' THEN
        IF out_flag = 1 AND delivered_flag = 0 THEN
            UPDATE orders SET delivered = TRUE WHERE order_id = p_order_id;
        ELSEIF out_flag = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot mark delivered before out for delivery';
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order already marked as delivered';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid stage provided. Use: shipped, out_for_delivery, or delivered';
    END IF;
END &&
DELIMITER ;


-- ordered products

delimiter &&
create procedure get_orders()
begin
select * from orders;
end&&
delimiter ;
call get_orders();
delimiter &&
create function count_orders()
returns int
deterministic
begin
    declare total int;
    select COUNT(*) INTO total FROM orders;
    return total;
end&&
delimiter ;


-- sellers dashboard

--  Products Management: view, add, update, delete

-- VIEW SELLER PRODUCTS


DELIMITER $$

CREATE PROCEDURE ViewSellerProducts (
    IN p_seller_port_id INT
)
BEGIN
    SELECT 
        product_id,
        product_name,
        quantity,
        price
    FROM 
        products
    WHERE 
        seller_port_id = p_seller_port_id;
END$$

DELIMITER ;

DELIMITER $$
CREATE PROCEDURE seller_add_product(
  IN p_seller VARCHAR(50),
  IN p_name VARCHAR(100),
  IN p_price DECIMAL(10,2),
  IN p_quantity INT
)
BEGIN
  INSERT INTO products (seller_port_id, product_name, price, quantity)
  VALUES (p_seller, p_name, p_price, p_quantity);
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE seller_update_product_name (
  IN p_pid INT,
  IN p_seller VARCHAR(50),
  IN p_name VARCHAR(100)
)
BEGIN
  IF p_name IS NULL OR p_name = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product name cannot be empty.';
  END IF;
  UPDATE products
    SET product_name = p_name
  WHERE product_id = p_pid
    AND seller_port_id = p_seller;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Product not found or does not belong to this seller.';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE seller_update_product_price (
  IN p_pid INT,
  IN p_seller VARCHAR(50),
  IN p_price DECIMAL(10,2)
)
BEGIN
  IF p_price IS NULL OR p_price <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Price must be greater than 0.';
  END IF;
  UPDATE products
    SET price = p_price
  WHERE product_id = p_pid
    AND seller_port_id = p_seller;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Product not found or does not belong to this seller.';
  END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE seller_update_product_quantity (
  IN p_pid INT,
  IN p_seller VARCHAR(50),
  IN p_quantity INT
)
BEGIN
  IF p_quantity IS NULL OR p_quantity < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity cannot be negative.';
  END IF;
  UPDATE products
    SET quantity = p_quantity
  WHERE product_id = p_pid
    AND seller_port_id = p_seller;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Product not found or does not belong to this seller.';
  END IF;
END$$
DELIMITER ;
DELIMITER $$

CREATE PROCEDURE seller_delete_product(
  IN p_pid INT,
  IN p_seller VARCHAR(50)
)
BEGIN
  DECLARE prod_exists INT DEFAULT 0;
  DECLARE order_count INT DEFAULT 0;

  -- Check if the product exists for this seller
  SELECT COUNT(*) INTO prod_exists
  FROM products
  WHERE product_id = p_pid
    AND seller_port_id = p_seller;

  IF prod_exists = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Product does not exist or does not belong to this seller.';
  ELSE
    -- Check if there are orders for this product
    SELECT COUNT(*) INTO order_count
    FROM orders
    WHERE product_id = p_pid;

    IF order_count > 0 THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cannot delete product: Existing orders found for this product.';
    ELSE
      -- Safe to delete
      DELETE FROM products
      WHERE product_id = p_pid
        AND seller_port_id = p_seller;
    END IF;
  END IF;
END$$

DELIMITER ;


--  Ordered Products Data: view orders for this seller
DELIMITER $$
CREATE PROCEDURE seller_view_orders(IN p_seller VARCHAR(50))
BEGIN
  SELECT o.order_id,
         o.product_id,
         p.product_name,
         o.consumer_port_id,
         o.quantity,
         o.order_date,
         get_order_status(o.order_id) AS status
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
   WHERE p.seller_port_id = p_seller;
END$$
DELIMITER ;

-- 🔹 Sales Analysis: monthly and annual revenue for seller
DELIMITER &&
CREATE PROCEDURE seller_monthly_sales(
  IN p_seller VARCHAR(50),
  IN p_year INT
)
BEGIN
  SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS sale_month,
    SUM(o.quantity * p.price) AS total_revenue
  FROM orders o
  JOIN products p ON o.product_id = p.product_id
  WHERE p.seller_port_id = p_seller
    AND YEAR(o.order_date) = p_year
  GROUP BY sale_month
  ORDER BY sale_month
END$$
DELIMITER ;
 
DELIMITER $$
CREATE PROCEDURE seller_annual_sales(IN p_seller VARCHAR(50))
BEGIN
  SELECT
    YEAR(o.order_date) AS sale_year,
    SUM(o.quantity * p.price) AS total_revenue
  FROM orders o
  JOIN products p ON o.product_id = p.product_id
  WHERE p.seller_port_id = p_seller
  GROUP BY sale_year
  ORDER BY sale_year;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE seller_total_revenue(IN p_seller VARCHAR(50))
BEGIN
  SELECT
    SUM(o.quantity * p.price) AS total_revenue
  FROM orders o
  JOIN products p ON o.product_id = p.product_id
  WHERE p.seller_port_id = p_seller;
END$$
DELIMITER ;
-- test
CALL seller_total_revenue('seller1');


-- REPORTED PRODUCTS PROCEDURES

-- Add reported product

DELIMITER $$
CREATE PROCEDURE add_reported_product (
    IN p_consumer_port_id VARCHAR(50),
    IN p_seller_id INT,
    IN p_product_id INT,
    IN p_issue_type ENUM('Damage', 'Wrong Product', 'Delayed', 'Still Not Received', 'Missing')
)
BEGIN
    INSERT INTO reported_products (
        consumer_port_id,
		seller_port_id,
        product_id,
        issue_type,
        status
    )
    VALUES (
        p_consumer_port_id,
        p_seller_id,
        p_product_id,
        p_issue_type,
        'Pending...'
    );
END$$
DELIMITER ;
-- Test:
CALL add_reported_product('consumer1', 2, 'Damage');
SELECT * FROM reported_products;


-- Update reported product
DELIMITER $$
CREATE PROCEDURE update_reported_product (
    IN p_report_id INT,
    IN p_new_status ENUM('Solved','Pending...'),
    IN p_new_action_taken ENUM('Replacement' , 'Compensation', 'Resend'),
    IN p_new_issue_type ENUM('Damage', 'Wrong Product', 'Delayed', 'Still Not Received', 'Missing')
)
BEGIN
    DECLARE v_exists INT;
    SELECT COUNT(*) INTO v_exists FROM reported_products WHERE report_id = p_report_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reported product not found.';
    END IF;

    UPDATE reported_products
    SET status = p_new_status,
        action_taken = p_new_action_taken,
        issue_type = p_new_issue_type
    WHERE report_id = p_report_id;
END$$
DELIMITER ;
-- Test:
CALL update_reported_product(5, 'Solved', 'Replacement', 'Damage');
SELECT LAST_INSERT_ID();
SELECT * FROM reported_products ORDER BY report_id DESC LIMIT 1;

-- Delete reported product
DELIMITER $$
CREATE PROCEDURE delete_reported_product (IN p_report_id INT)
BEGIN
    DELETE FROM reported_products
    WHERE report_id = p_report_id;
END$$
DELIMITER ;
-- Test:
CALL delete_reported_product(1);

-- seller side reported  products

DELIMITER $$
CREATE PROCEDURE get_reported_issues_by_consumer (
    IN p_consumer_id VARCHAR(50)            
)
BEGIN
    SELECT *
    FROM   reported_products
    WHERE  consumer_port_id = p_consumer_id;
END$$

CREATE PROCEDURE update_report_status (
    IN p_report_id  INT,
    IN p_new_status ENUM('Pending','Resolved'),
    IN p_action_taken ENUM('Replacement','Resend','Compensation')
)
BEGIN
    IF NOT EXISTS (SELECT 1
                   FROM   reported_products
                   WHERE  report_id = p_report_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Report ID not found';
    END IF;

   
    UPDATE reported_products
       SET status   = p_new_status,
           action_taken = p_action_taken
     WHERE report_id = p_report_id;
END$$


CREATE TRIGGER auto_report_date
BEFORE INSERT ON reported_products
FOR EACH ROW
BEGIN
    IF NEW.report_date IS NULL THEN
        SET NEW.report_date = NOW();
    END IF;
END$$
DELIMITER ;
CALL get_reported_issues_by_consumer(782);

select * from reported_products;
CALL update_report_status(3,'Resolved','compensation');
SELECT * FROM reported_products ORDER BY report_id;

--  trigger that automatically sets action for reported products
DELIMITER $$
CREATE TRIGGER trg_before_insert_reported_product
BEFORE INSERT ON reported_products
FOR EACH ROW
BEGIN
    IF NEW.issue_type IN ('Damage', 'Wrong Product') THEN
        SET NEW.action_taken = 'Replacement';
    ELSEIF NEW.issue_type = 'Still Not Received' THEN
        SET NEW.action_taken = 'Resend';
    ELSEIF NEW.issue_type IN ('Missing', 'Delayed') THEN
        SET NEW.action_taken = 'Compensation';
    ELSE
        SET NEW.action_taken = 'No';
    END IF;
END$$
DELIMITER ;
-- test
CALL add_reported_product('consumer1', 2, 'Still Not Received');
SELECT * FROM reported_products ORDER BY report_id DESC LIMIT 1;



-- Trigger to prevent negative stock
-- Prevent negative quantity on UPDATE
DELIMITER $$
CREATE TRIGGER trg_no_negative_stock
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.quantity < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock quantity cannot be negative.';
    END IF;
END$$
DELIMITER ;

-- Prevent negative quantity on INSERT
DELIMITER $$
CREATE TRIGGER trg_no_negative_stock_insert
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.quantity < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Initial stock quantity cannot be negative.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$

CREATE PROCEDURE increment_product_quantity (
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    -- Check for negative increment
    IF p_quantity < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity increment cannot be negative.';
    END IF;

    -- Update product quantity
    UPDATE products
    SET quantity = quantity + p_quantity
    WHERE product_id = p_product_id;

    -- Optional: Check if product exists
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE get_reports_by_seller (
    IN p_seller_port_id VARCHAR(50)
)
BEGIN
    SELECT *
    FROM reported_products
    WHERE seller_port_id = p_seller_port_id;
END$$

DELIMITER ;

-- CREATE PROCEDURE forgot_password_reset (     IN p_port_id VARCHAR(50),     IN p_role VARCHAR(20),     IN p_new_password VARCHAR(255) ) BEGIN     -- Password length check     IF LENGTH(p_new_password) < 8 THEN         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password must be at least 8 characters long';     END IF;          IF EXISTS (SELECT 1 FROM consumer_port WHERE port_id = p_port_id) THEN             UPDATE consumer_port             SET password = SHA2(p_new_password, 256)             WHERE port_id = p_port_id;         ELSE             SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Consumer not found';         END IF;     ELSEIF p_role = 'Seller' THEN         IF EXISTS (SELECT 1 FROM seller_port WHERE port_id = p_port_id) THEN             UPDATE seller_port             SET password = SHA2(p_new_password, 256)             WHERE port_id = p_port_id;         ELSE             SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seller not found';         END IF;     ELSE         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid role. Must be Consumer or Seller';     END IF; END

INSERT INTO products (product_name, quantity, price, seller_port_id)
VALUES
  ('Plastic Sheets', 50, 59.50, 'seller1'),
  ('Wooden Planks', 30, 120.00, 'seller1'),
  ('Aluminum Rods', 40, 150.00, 'seller1'),
  ('Steel Beams', 20, 200.00, 'seller1'),
  ('Copper Wires', 100, 75.00, 'seller1'),
  ('PVC Pipes', 60, 45.00, 'seller1'),
  ('Glass Panels', 25, 180.00, 'seller1'),
  ('Iron Nails', 500, 0.50, 'seller1'),
  ('Concrete Bags', 80, 95.00, 'seller1'),
  ('Ceramic Tiles', 150, 22.00, 'seller1'),
  ('Brick Blocks', 200, 12.00, 'seller1'),
  ('Paint Buckets', 35, 65.00, 'seller1'),
  ('Adhesive Glue', 45, 25.00, 'seller1'),
  ('Roofing Sheets', 70, 110.00, 'seller1'),
  ('Insulation Rolls', 55, 85.00, 'seller1'),
  ('Metal Screws', 1000, 0.10, 'seller1'),
  ('Sand Bags', 90, 35.00, 'seller1'),
  ('Timber Logs', 15, 250.00, 'seller1'),
  ('Gravel Packs', 120, 20.00, 'seller1'),
  ('Cement Blocks', 160, 15.00, 'seller1'),
  ('Wire Mesh', 40, 60.00, 'seller1'),
  ('Fiber Boards', 50, 70.00, 'seller1'),
  ('MDF Sheets', 45, 55.00, 'seller1'),
  ('Laminates', 65, 40.00, 'seller1'),
  ('Vinyl Flooring', 75, 90.00, 'seller1'),
  ('Rubber Sheets', 80, 35.00, 'seller1'),
  ('Paint Brushes', 200, 5.00, 'seller1'),
  ('Putty Powder', 85, 30.00, 'seller1'),
  ('Sealant Tubes', 95, 18.00, 'seller1'),
  ('Drywall Sheets', 60, 48.00, 'seller1'),
  ('Stone Slabs', 20, 300.00, 'seller1'),
  ('Plaster Bags', 100, 25.00, 'seller1'),
  ('Concrete Blocks', 130, 16.00, 'seller1'),
  ('Metal Pipes', 50, 110.00, 'seller1'),
  ('Angle Irons', 35, 95.00, 'seller1'),
  ('Channel Bars', 40, 105.00, 'seller1'),
  ('Rebar Rods', 70, 80.00, 'seller1'),
  ('Hex Nuts', 500, 0.15, 'seller1'),
  ('Bolts', 400, 0.20, 'seller1'),
  ('Washers', 450, 0.05, 'seller1'),
  ('Power Tools', 10, 750.00, 'seller1'),
  ('Hand Tools', 20, 250.00, 'seller1'),
  ('Safety Helmets', 30, 45.00, 'seller1'),
  ('Work Gloves', 60, 12.00, 'seller1'),
  ('Measuring Tape', 40, 15.00, 'seller1'),
  ('Toolboxes', 25, 80.00, 'seller1'),
  ('Extension Cords', 35, 22.00, 'seller1'),
  ('Electric Drills', 15, 550.00, 'seller1'),
  ('Ladders', 20, 120.00, 'seller1'),
  ('Wheelbarrows', 10, 95.00, 'seller1');

INSERT INTO products (product_name, quantity, price, seller_port_id)
VALUES ('Iron Pipes', 100, 99.99, 'seller1');


DROP PROCEDURE IF EXISTS order_product;
DELIMITER $$
CREATE PROCEDURE order_product(
    IN p_product_id INT,
    IN p_consumer_port_id VARCHAR(50),
    IN p_quantity INT,
    IN p_seller_port_id VARCHAR(50)
)
BEGIN  
    DECLARE pro_quantity INT;
    SELECT quantity INTO pro_quantity FROM products WHERE product_id = p_product_id;
    IF pro_quantity > 0 AND p_quantity <= pro_quantity THEN
        INSERT INTO orders (product_id, consumer_port_id, quantity, order_date, seller_port_id)
        VALUES (p_product_id, p_consumer_port_id, p_quantity, CURDATE(), p_seller_port_id);
    ELSE 
        SELECT 'order less quantity ' AS message;
    END IF;
END$$
DELIMITER ;

  SELECT * FROM orders WHERE seller_port_id = 'seller1';
  select * from products;
     SELECT * FROM orders WHERE seller_port_id = 'seller1'; 
     SELECT * FROM orders WHERE consumer_port_id = 'user1';
     
  
-- Drop existing trigger if any
DROP TRIGGER IF EXISTS trg_auto_action_on_report;

-- Drop procedures if they exist
DROP PROCEDURE IF EXISTS add_reported_product;
DROP PROCEDURE IF EXISTS update_report_status;
DROP PROCEDURE IF EXISTS get_reported_issues_by_consumer;
DROP PROCEDURE IF EXISTS get_reports_by_seller;

-- Drop table
DROP TABLE IF EXISTS reported_products;


CREATE TABLE reported_products (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
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
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (consumer_port_id) REFERENCES consumer_port(port_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);

DELIMITER $$

CREATE TRIGGER trg_auto_action_on_report
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

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE add_reported_product (
    IN p_order_id INT,
    IN p_consumer_port_id VARCHAR(50),
    IN p_seller_port_id VARCHAR(50),
    IN p_product_id INT,
    IN p_issue_type ENUM('Damage', 'Wrong Product', 'Delayed', 'Still Not Received', 'Missing')
)
BEGIN
    INSERT INTO reported_products (
        order_id, consumer_port_id, seller_port_id, product_id, issue_type
    )
    VALUES (
        p_order_id, p_consumer_port_id, p_seller_port_id, p_product_id, p_issue_type
    );
    SELECT 'Report submitted successfully' AS message;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE update_report_status (
    IN p_report_id INT,
    IN p_seller_port_id VARCHAR(50)
)
BEGIN
    UPDATE reported_products
    SET status = 'Solved'
    WHERE report_id = p_report_id AND seller_port_id = p_seller_port_id;

    IF ROW_COUNT() = 0 THEN
        SELECT 'Report ID is invalid or does not belong to this seller.' AS message;
    ELSE
        SELECT 'Report marked as solved' AS message;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE get_reported_issues_by_consumer (
    IN p_consumer_port_id VARCHAR(50)
)
BEGIN
    SELECT 
        rp.report_id,
        rp.order_id,
        rp.product_id,
        p.product_name,
        rp.issue_type,
        rp.status,
        rp.action_taken,
        rp.report_date,
        rp.seller_port_id
    FROM reported_products rp
    JOIN products p ON rp.product_id = p.product_id
    WHERE rp.consumer_port_id = p_consumer_port_id;
END$$

DELIMITER ;




 SELECT o.order_id, o.product_id, p.product_name, o.quantity, o.order_date, o.order_placed, o.shipped, o.out_for_delivery, o.delivered, o.seller_port_id, o.consumer_port_id, cp.location, p.price
     FROM orders o
     JOIN products p ON o.product_id = p.product_id
     LEFT JOIN consumer_port cp ON o.consumer_port_id = cp.port_id
     WHERE o.consumer_port_id = 'user1'
     LIMIT 10 OFFSET 0;
     SELECT * FROM orders;
     
           SELECT COUNT(*) FROM orders WHERE seller_port_id = 'seller1';
               SELECT * FROM orders WHERE seller_port_id = 'seller1';
  SELECT * FROM orders WHERE seller_port_id = 'seller1';
  
  
  -- Jan
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (3, 'user1', 'seller1', 5, '2025-01-15', 1, 1, 1, 1);

-- Feb
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (4, 'user1', 'seller1', 10, '2025-02-10', 1, 1, 1, 1);

-- Mar
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (5, 'user1', 'seller1', 7, '2025-03-20', 1, 1, 1, 1);

-- Apr
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (3, 'user1', 'seller1', 8, '2025-04-05', 1, 1, 1, 1);

-- May
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (4, 'user1', 'seller1', 12, '2025-05-18', 1, 1, 1, 1);

-- Jun
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (5, 'user1', 'seller1', 6, '2025-06-22', 1, 1, 1, 1);

-- Jul
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (3, 'user1', 'seller1', 9, '2025-07-11', 1, 1, 1, 1);

-- Aug
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (4, 'user1', 'seller1', 11, '2025-08-14', 1, 1, 1, 1);

-- Sep
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (5, 'user1', 'seller1', 13, '2025-09-09', 1, 1, 1, 1);

-- Oct
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (3, 'user1', 'seller1', 4, '2025-10-25', 1, 1, 1, 1);

-- Nov
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (4, 'user1', 'seller1', 15, '2025-11-03', 1, 1, 1, 1);

-- Dec
INSERT INTO orders (product_id, consumer_port_id, seller_port_id, quantity, order_date, order_placed, shipped, out_for_delivery, delivered)
VALUES (5, 'user1', 'seller1', 10, '2025-12-19', 1, 1, 1, 1);

-- Example: Product 3, 4, 5 ke liye stock badhao
UPDATE products SET quantity = 100 WHERE product_id = 3;
UPDATE products SET quantity = 100 WHERE product_id = 4;
UPDATE products SET quantity = 100 WHERE product_id = 5;

  SELECT * FROM products WHERE product_id IN (3,4,5);
    CALL seller_monthly_sales('seller1', 2025);
    
    
DELIMITER $$
CREATE PROCEDURE seller_monthly_sales(
  IN p_seller VARCHAR(50),
  IN p_year INT
)
BEGIN
  SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS sale_month,
    SUM(o.quantity * p.price) AS total_revenue
  FROM orders o
  JOIN products p ON o.product_id = p.product_id
  WHERE p.seller_port_id = p_seller
    AND YEAR(o.order_date) = p_year
  GROUP BY sale_month
  ORDER BY sale_month;
END$$
DELIMITER ;


select * from reported_products;
CALL get_reports_by_seller('seller1');



  SELECT 
      rp.report_id,
      rp.order_id,
      rp.product_id,
      p.product_name,
      rp.issue_type,
      rp.status,
      rp.action_taken,
      rp.report_date,
      rp.consumer_port_id
  FROM reported_products rp
  JOIN products p ON rp.product_id = p.product_id
  WHERE rp.seller_port_id = p_seller_port_id;
  
  
  delimiter &&
     CREATE PROCEDURE get_reports_by_seller (
       IN p_seller_port_id VARCHAR(50)
   )
   BEGIN
       SELECT 
           rp.report_id,
           rp.order_id,
           rp.product_id,
           p.product_name,
           rp.issue_type,
           rp.status,
           rp.action_taken,
           rp.report_date,
           rp.consumer_port_id
       FROM reported_products rp
       JOIN products p ON rp.product_id = p.product_id
       WHERE rp.seller_port_id = p_seller_port_id;
   END && 
   delimiter ;