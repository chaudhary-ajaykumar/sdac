-- Consumer Accounts
INSERT INTO consumer_port (port_id, password, location)
VALUES 
('C001', 'pass123', 'Mumbai'),
('C002', 'pass456', 'Chennai');

-- Seller Accounts
INSERT INTO seller_port (port_id, password)
VALUES 
('S001', 'sell123'),
('S002', 'sell456');


-- dummy products
INSERT INTO products (product_name, quantity, price, seller_port_id)
VALUES
('Steel Rods', 100, 250.00, 'S001'),
('Copper Wire', 200, 180.50, 'S001'),
('Wooden Planks', 150, 120.75, 'S002'),
('Plastic Containers', 300, 60.00, 'S002');


-- dummy oders
-- Consumer C001 orders Steel Rods
CALL place_order(1, 'C001', 10, '2025-06-01');

-- Consumer C002 orders Wooden Planks
CALL place_order(3, 'C002', 5, '2025-06-15');

-- Consumer C001 orders Copper Wire
CALL place_order(2, 'C001', 20, '2025-06-18');

-- Consumer C002 orders Plastic Containers
CALL place_order(4, 'C002', 30, '2025-06-20');


-- updated oder status

-- Mark Order 1 as Shipped
CALL update_order_status(1, 'shipped');

-- Mark Order 2 as Out for Delivery
CALL update_order_status(2, 'shipped');
CALL update_order_status(2, 'out_for_delivery');

-- Mark Order 3 as Delivered
CALL update_order_status(3, 'shipped');
CALL update_order_status(3, 'out_for_delivery');
CALL update_order_status(3, 'delivered');


-- dum,y issue
-- Consumer C001 reports a damaged Steel Rods order
CALL report_issue('C001', 1, 'Damage');

-- Consumer C002 reports "Still Not Received" for Plastic Containers
CALL report_issue('C002', 4, 'Still Not Received');


-- sale report
-- Monthly sales report for S001 for June 2025
CALL monthly_sales_report('S001', 6, 2025);

-- Yearly sales report for S002 for 2025
CALL yearly_sales_report('S002', 2025);

-- Get total revenue for seller S001
SELECT get_total_revenue('S001') AS total_revenue_s1;

-- Get top-selling product of seller S001
SELECT get_top_product('S001') AS top_product_s1;


-- test resoulation
-- Seller resolves Report ID 1 (Damage)
CALL solve_reported_issue(1);

-- Check pending issue count for seller S002
SELECT count_pending_issues('S002') AS pending_issues_s2;


-- All Products
SELECT * FROM products;

-- All Orders
SELECT * FROM orders;

-- All Reports
SELECT * FROM reported_products;
