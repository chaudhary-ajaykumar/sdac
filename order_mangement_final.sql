-- order_mangement

create database if not exists import_export_sdac_test ;
use import_export_sdac_test;

create table consumer_port(port_id  int  auto_increment primary key,password varchar(255) not null ,location varchar(255),role varchar(30) not null );

create table seller_port(port_id  int  auto_increment primary key,password varchar(255) not null ,location varchar(255),role varchar(30) not null );

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL,
    quantity INT,
    price DOUBLE,
    seller_port_id INT,
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    consumer_port_id INT,
    seller_port_id INT,
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

 
CREATE TABLE reported_products (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    consumer_port_id INT,
    seller_port_id INT,
    issue_type ENUM('Damage', 'Wrong Product', 'Delayed', 'Still Not Received'),
    status ENUM('solved', 'pending'),
    action_taken ENUM('replacement', 'compensation', 'resend'),
    report_date DATE,

    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (consumer_port_id) REFERENCES consumer_port(port_id),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);



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


-- more coorect logic for order stauts as it alterDELIMITER $$
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


-- track order flag status 
delimiter $$
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


-- 1. Insert a seller
INSERT INTO seller_port (password, location, role)
VALUES ('seller123', 'Delhi', 'seller');

-- 2. Insert a product linked to seller_id = 1
INSERT INTO products (product_name, quantity, price, seller_port_id)
VALUES ('Laptop', 10, 50000, 1);

-- 3. Insert a consumer
INSERT INTO consumer_port (password, location, role)
VALUES ('consumer123', 'Mumbai', 'consumer');

-- 4. Call procedure to place an order (product_id=1, consumer_id=1, quantity=2, seller_id=1)
CALL order_product(1, 1, 2, 1);

-- 5. Check data inserted into orders
SELECT * FROM orders;

-- 6. Check updated quantity in products (should be 10 - 2 = 8)
SELECT * FROM products;

-- 7. Call order_flag procedure to update order status using boolean flags
CALL order_flag(1, TRUE, FALSE, FALSE); -- Mark as shipped

-- 8. Call update_order_flag procedure to update using stage
CALL update_order_flag(1, 'out_for_delivery');
CALL update_order_flag(1, 'delivered');

-- 9. Call get_order_status function
SELECT get_order_status(1) AS order_status;

-- 10. Final check on order flags
SELECT * FROM orders;

