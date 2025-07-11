CREATE DATABASE erp_import_export;
USE erp_import_export;

CREATE TABLE consumer_port (
    port_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    location VARCHAR(100),
    role VARCHAR(20) DEFAULT 'Consumer'
);


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
