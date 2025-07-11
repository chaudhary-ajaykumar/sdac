USE erp_import_export;

CREATE TABLE consumer_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    location VARCHAR(100),
    role VARCHAR(20) DEFAULT 'Consumer'
);

CREATE TABLE reported_products (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    consumer_port_id VARCHAR(50),
    product_id INT,
    issue_type ENUM('Damage', 'Wrong Product', 'Delayed', 'Still Not Received', 'Missing'),
    solution ENUM('Pending', 'Solved') DEFAULT 'Pending',
    report_date DATE,
    FOREIGN KEY (consumer_port_id) REFERENCES consumer_port(port_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INT DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    seller_port_id VARCHAR(50),
    FOREIGN KEY (seller_port_id) REFERENCES seller_port(port_id)
);

-- report a issue

This inserts a report and auto-selects today’s date.
DELIMITER $$

CREATE PROCEDURE report_issue (
    IN p_consumer_port_id VARCHAR(50),
    IN p_product_id INT,
    IN p_issue_type ENUM('Damage', 'Wrong Product', 'Delayed', 'Still Not Received', 'Missing')
)
BEGIN
    INSERT INTO reported_products (
        consumer_port_id,
        product_id,
        issue_type,
        solution,
        report_date
    )
    VALUES (
        p_consumer_port_id,
        p_product_id,
        p_issue_type,
        'Pending',
        CURDATE()
    );
END $$

DELIMITER ;

-- auto suggest solution
-- usr this in froentend to display this message


DELIMITER $$

CREATE TRIGGER trg_auto_suggest_solution
BEFORE INSERT ON reported_products
FOR EACH ROW
BEGIN
    CASE NEW.issue_type
        WHEN 'Damage' THEN
            SET NEW.solution = 'Pending'; -- Suggest: Replace item
        WHEN 'Wrong Product' THEN
            SET NEW.solution = 'Pending'; -- Suggest: Exchange product
        WHEN 'Delayed' THEN
            SET NEW.solution = 'Pending'; -- Suggest: Apology + delivery tracking
        WHEN 'Still Not Received' THEN
            SET NEW.solution = 'Pending'; -- Suggest: Raise alert to seller
        WHEN 'Missing' THEN
            SET NEW.solution = 'Pending'; -- Suggest: Investigate and compensate
    END CASE;
END $$

DELIMITER ;


-- mark isssued as solve

DELIMITER $$

CREATE PROCEDURE solve_reported_issue (
    IN p_report_id INT
)
BEGIN
    UPDATE reported_products
    SET solution = 'Solved'
    WHERE report_id = p_report_id;
END $$

DELIMITER ;

-- count pending report

DELIMITER $$

CREATE FUNCTION count_pending_issues (
    p_seller_port_id VARCHAR(50)
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE pending_count INT;

    SELECT COUNT(*)
    INTO pending_count
    FROM reported_products rp
    JOIN products p ON rp.product_id = p.product_id
    WHERE p.seller_port_id = p_seller_port_id AND rp.solution = 'Pending';

    RETURN pending_count;
END $$

DELIMITER ;


