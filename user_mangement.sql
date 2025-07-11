USE erp_import_export;

CREATE TABLE consumer_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL check(char_length(password)>=8),
    location VARCHAR(100),
    role VARCHAR(20) DEFAULT 'Consumer'

);

CREATE TABLE seller_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL check(char_length(password)>=8),
    role VARCHAR(20) DEFAULT 'Seller'
);

-- to check if port_id is unique 
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
END $$

DELIMITER ;

-- ii port_id exist then trigger this message

-- consumer_port
DELIMITER $$

CREATE TRIGGER trg_consumer_port_unique
BEFORE INSERT ON consumer_port
FOR EACH ROW
BEGIN
    IF NOT is_port_id_unique(NEW.port_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'port_id already exists in either consumer_port or seller_port';
    END IF;
END $$

DELIMITER ;

-- seller_port
DELIMITER $$

CREATE TRIGGER trg_seller_port_unique
BEFORE INSERT ON seller_port
FOR EACH ROW
BEGIN
    IF NOT is_port_id_unique(NEW.port_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'port_id already exists in either seller_port or consumer_port';
    END IF;
END $$

DELIMITER ;


-- register 
DELIMITER $$

CREATE PROCEDURE register_user (
    IN p_port_id VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_location VARCHAR(100),
    IN p_role VARCHAR(20)
)
BEGIN
    IF p_role = 'Consumer' THEN
        INSERT INTO consumer_port (port_id, password, location, role)
        VALUES (p_port_id, p_password, p_location, p_role);
        
    ELSEIF p_role = 'Seller' THEN
        INSERT INTO seller_port (port_id, password, role)
        VALUES (p_port_id, p_password, p_role);
        
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid role. Must be Consumer or Seller';
    END IF;
END $$

DELIMITER ;

-- verigy using login
DELIMITER $$

CREATE FUNCTION verify_login (
    p_port_id VARCHAR(50),
    p_password VARCHAR(255)
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE role_result VARCHAR(20);

    IF EXISTS (SELECT 1 FROM consumer_port WHERE port_id = p_port_id AND password = p_password) THEN
        SET role_result = 'Consumer';

    ELSEIF EXISTS (SELECT 1 FROM seller_port WHERE port_id = p_port_id AND password = p_password) THEN
        SET role_result = 'Seller';

    ELSE
        SET role_result = 'Invalid';
    END IF;

    RETURN role_result;
END $$

DELIMITER ;

-- updated user profile
-- consumer

DELIMITER $$

CREATE PROCEDURE update_consumer_profile (
    IN p_port_id VARCHAR(50),
    IN p_new_password VARCHAR(255),
    IN p_new_location VARCHAR(100)
)
BEGIN
    UPDATE consumer_port
    SET password = p_new_password,
        location = p_new_location
    WHERE port_id = p_port_id;
END $$

DELIMITER ;


-- seller
DELIMITER $$

CREATE PROCEDURE update_seller_profile (
    IN p_port_id VARCHAR(50),
    IN p_new_password VARCHAR(255),
    IN p_new_location VARCHAR(100)
)
BEGIN
    UPDATE seller_port
    SET password = p_new_password
    WHERE port_id = p_port_id;
END $$

DELIMITER ;


-- delete account

-- consumer
DELIMITER $$

CREATE PROCEDURE delete_consumer_account (
    IN p_port_id VARCHAR(50)
)
BEGIN
    DELETE FROM consumer_port WHERE port_id = p_port_id;
END $$

DELIMITER ;

-- seller
DELIMITER $$

CREATE PROCEDURE delete_seller_account (
    IN p_port_id VARCHAR(50)
)
BEGIN
    DELETE FROM seller_port WHERE port_id = p_port_id;
END $$

DELIMITER ;
