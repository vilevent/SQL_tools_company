
CREATE DATABASE IF NOT EXISTS tools_company;

USE tools_company;

CREATE TABLE customer (
    cus_id INT NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    mid_initial CHAR(1) NULL,
    area_code CHAR(3) NOT NULL,
    phone_num CHAR(8) NOT NULL,
    balance DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY(cus_id)
);

CREATE TABLE invoice (
    inv_number INT NOT NULL,
    cus_id INT NOT NULL,
    inv_date DATE NOT NULL,
    PRIMARY KEY(inv_number),
    CONSTRAINT FK_invoice_customer FOREIGN KEY(cus_id)
	REFERENCES customer(cus_id)
	ON DELETE CASCADE
);

CREATE TABLE vendor (
    vend_id INT NOT NULL,
    vend_name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    area_code CHAR(3) NOT NULL,
    phone_num CHAR(8) NOT NULL,
    state CHAR(2) NOT NULL,
    prev_order CHAR(1) NOT NULL,
    PRIMARY KEY(vend_id)
);

CREATE TABLE product (
    prod_code CHAR(8) NOT NULL,
    descript VARCHAR(150) NOT NULL,
    stocking_date DATE NOT NULL,
    onhand_units INT NOT NULL,
    min_units INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    discount_rate DECIMAL(3, 2) NOT NULL,
    vend_id INT NULL,
    PRIMARY KEY(prod_code),
    CONSTRAINT FK_product_vendor FOREIGN KEY(vend_id)
	REFERENCES vendor(vend_id)
	ON DELETE CASCADE
);

CREATE TABLE inv_line (
    inv_number INT NOT NULL,
    line_number INT NOT NULL,
    prod_code CHAR(8) NOT NULL,
    num_units INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY(inv_number, line_number),
    CONSTRAINT FK_inv_line_invoice FOREIGN KEY(inv_number)
	REFERENCES invoice(inv_number)
        ON DELETE CASCADE,
    CONSTRAINT FK_inv_line_product FOREIGN KEY(prod_code)
	REFERENCES product(prod_code)
	ON DELETE CASCADE
);


-- Import CSV file into database table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Customer.csv'
INTO TABLE customer
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    cus_id,
    last_name,
    first_name,
    mid_initial,
    area_code,
    phone_num,
    balance
);

-- Verify the data import into customer table
SELECT *
FROM customer;


-- Import remaining CSV files into database tables
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Invoice.csv'
INTO TABLE invoice
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    inv_number,
    cus_id,
    @inv_date
)
SET inv_date = STR_TO_DATE(@inv_date, '%c/%e/%Y');

SELECT *
FROM invoice;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Vendor.csv'
INTO TABLE vendor
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    vend_id,
    vend_name,
    contact,
    area_code,
    phone_num,
    state,
    prev_order
);

SELECT * FROM
vendor;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Product.csv'
INTO TABLE product
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    prod_code,
    descript,
    @stocking_date,
    onhand_units,
    min_units, 
    @price,
    discount_rate,
    vend_id
)
SET 
    stocking_date = STR_TO_DATE(@stocking_date, '%W, %M %e, %Y'),
    price = CAST(REPLACE(@price, '$', '') AS DECIMAL(10, 2));

SELECT *
FROM product;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Line.csv'
INTO TABLE inv_line
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    inv_number,
    line_number,
    prod_code,
    num_units,
    unit_price
);

SELECT *
FROM inv_line;


-- Task 1: Generate a listing of all purchases made by the customers, which contains
-- information about customer id, invoice number, invoice date, product description,
-- number of units, and price.
SELECT 
    c.cus_id AS 'Customer ID', 
    i.inv_number AS 'Invoice Number', 
    DATE_FORMAT(i.inv_date, '%M %e, %Y') AS 'Invoice Date', 
    p.descript AS 'Product Description', 
    il.num_units AS 'Units Bought', 
    CONCAT('$', il.unit_price) AS 'Unit Price'
FROM customer c JOIN invoice i
    ON c.cus_id = i.cus_id
JOIN inv_line il
    ON i.inv_number = il.inv_number
JOIN product p
    ON il.prod_code = p.prod_code
ORDER BY c.cus_id, i.inv_number, p.descript;


-- Task 2: Generate the listing of customer purchases, including
-- the subtotals for each of the invoice line numbers.
SELECT 
    c.cus_id AS 'Customer ID', 
    i.inv_number AS 'Invoice Number', 
    p.descript AS 'Product Description', 
    il.num_units AS 'Units Bought', 
    CONCAT('$', il.unit_price) AS 'Unit Price', 
    CONCAT('$', il.num_units * il.unit_price) AS 'Subtotal'
FROM customer c JOIN invoice i
    ON c.cus_id = i.cus_id
JOIN inv_line il
    ON i.inv_number = il.inv_number
JOIN product p
    ON il.prod_code = p.prod_code
ORDER BY c.cus_id, i.inv_number, p.descript;


-- Task 3: Generate a purchase summary for each customer, which includes
-- their balance and total purchase amount.
SELECT 
    t.cus_id AS 'Customer ID', 
    CONCAT('$', t.balance) AS 'Balance', 
    CONCAT('$', t.purchase_amt) AS 'Total Purchases'
FROM 
     (SELECT 
	 c.cus_id, c.balance, 
	 SUM(il.num_units * il.unit_price) AS purchase_amt
      FROM customer c JOIN invoice i
	 ON c.cus_id = i.cus_id
      JOIN inv_line il 
	 ON i.inv_number = il.inv_number
      GROUP BY c.cus_id) t   -- derived table t
ORDER BY t.cus_id;


-- Task 4: Write a query to produce the total purchase amount per invoice.
SELECT 
    t.inv_number AS 'Invoice Number', 
    CONCAT('$', t.invoice_tot) AS 'Invoice Total'
FROM
     (SELECT 
	 i.inv_number, 
         SUM(il.num_units * il.unit_price) AS invoice_tot
      FROM invoice i JOIN inv_line il
	 ON i.inv_number = il.inv_number
      GROUP BY i.inv_number) t
ORDER BY t.inv_number;


-- Task 5: Write a query to show the invoices and invoice totals per customer.
DROP TEMPORARY TABLE IF EXISTS t1;

CREATE TEMPORARY TABLE t1 
(
   SELECT 
      t.cus_id,
      t.inv_number,
      CONCAT('$', t.invoice_tot) AS invoice_tot
   FROM 
	(SELECT 
	     c.cus_id, i.inv_number,
	     SUM(il.num_units * il.unit_price) AS invoice_tot
	 FROM customer c JOIN invoice i
	     ON c.cus_id = i.cus_id
	 JOIN inv_line il
	     ON i.inv_number = il.inv_number
	 GROUP BY c.cus_id, i.inv_number) t
);

SELECT *
FROM t1
ORDER BY cus_id, inv_number;


-- Task 6: List the balance and name of the customers who have made purchases during 
-- the invoicing period. That is, for the customers who appear in the INVOICE table. 
SELECT DISTINCT
    c.cus_id,
    c.first_name,
    c.last_name,
    c.balance
FROM customer c JOIN invoice i
    ON c.cus_id = i.cus_id
ORDER BY c.cus_id;


-- Task 7: Write a query that finds the customers who did not make any purchases 
-- during the invoicing period.
SELECT 
    c.cus_id,
    c.first_name,
    c.last_name
FROM customer c LEFT JOIN invoice i
    ON c.cus_id = i.cus_id
WHERE i.cus_id IS NULL  -- non-matching rows from LEFT JOIN
ORDER BY c.cus_id;


-- Task 8: Write a query to find the customer balance characteristics for all customers. 
-- Obtain the total, min, max, and average balance.
SELECT 
    SUM(balance) AS 'Total Balances',
    MIN(balance) AS 'Minimum Balance',
    MAX(balance) AS 'Maximum Balance',
    ROUND(AVG(balance), 2) AS 'Average Balance'
FROM customer;

    
-- Task 9: Write a query to compute the total purchases amount, average purchase amount 
-- and the number of product purchases made by each customer that has invoices.
SELECT 
   c.cus_id, 
   SUM(il.num_units * il.unit_price) AS total_purchases_amt,
   COUNT(il.inv_number) AS num_purchases,
   ROUND(
          SUM(il.num_units * il.unit_price) / COUNT(il.inv_number), 2
	) AS avg_purchase_amt
FROM customer c JOIN invoice i
   ON c.cus_id = i.cus_id
JOIN inv_line il
   ON i.inv_number = il.inv_number
GROUP BY c.cus_id;


-- Task 10: Write a query to produce the number of invoices and the total purchase amounts by customer.
SELECT 	
    c.cus_id,
    COUNT(DISTINCT i.inv_number) AS 'Number of Invoices',
    SUM(il.num_units * il.unit_price) AS 'Total Purchases'
FROM customer c JOIN invoice i
    ON c.cus_id = i.cus_id
JOIN inv_line il
    ON i.inv_number = il.inv_number
GROUP BY c.cus_id;


-- Task 11: Write a query that find the customer balance summary for all customers who 
-- have NOT made purchases during the current invoicing period.
SELECT
    SUM(c.balance) AS total_balance,
    MIN(c.balance) AS min_balance,
    MAX(c.balance) AS max_balance,
    ROUND(AVG(c.balance), 2) AS avg_balance
FROM customer c LEFT JOIN invoice i
    ON c.cus_id = i.cus_id
WHERE i.cus_id IS NULL;


-- Task 12: Find the listing of all customers except those who purchased product '7.25-in. pwr. saw blade'
DROP TEMPORARY TABLE IF EXISTS t2;

CREATE TEMPORARY TABLE t2 
(
    SELECT i.*, p.*
    FROM invoice i JOIN inv_line il
	ON i.inv_number = il.inv_number
    JOIN product p 
	ON il.prod_code = p.prod_code
);

SELECT *
FROM t2;

-- Correlated subquery with NOT EXISTS operator
SELECT 
    c.cus_id AS 'customer ID',
    CONCAT(c.first_name, ' ', c.last_name) AS 'customer name',
    c.balance
FROM customer c
WHERE NOT EXISTS (SELECT *
		  FROM t2
		  WHERE t2.cus_id = c.cus_id
		     AND t2.descript = '7.25-in. pwr. saw blade');
                    

-- Task 13: Find the listing of all customers who purchased product 'Claw hammer', the number
-- of total units for this product, and number of purchases of this product, with respect 
-- to total purchases made by customer.
CREATE TEMPORARY TABLE t3
(
    SELECT 
	c.cus_id,
	c.first_name,
	c.last_name,
	SUM(IF(p.descript = 'Claw hammer', 1, 0)) AS claw_hammer_purchases,
	COUNT(il.inv_number) AS total_purchases
     FROM customer c JOIN invoice i
	ON c.cus_id = i.cus_id
     JOIN inv_line il 
	ON i.inv_number = il.inv_number
     JOIN product p
	ON il.prod_code = p.prod_code
     GROUP BY c.cus_id
);

-- Temporary table stores temporary result set
CREATE TEMPORARY TABLE t4
(
    SELECT 
	c.cus_id,
	SUM(il.num_units) AS total_units
    FROM customer c JOIN invoice i
	ON c.cus_id = i.cus_id
    JOIN inv_line il 
	ON i.inv_number = il.inv_number
    JOIN product p
	ON il.prod_code = p.prod_code
    WHERE p.descript = 'Claw hammer'
    GROUP BY c.cus_id
);

SELECT 
    t3.cus_id,
    t3.first_name,
    t3.last_name,
    t3.claw_hammer_purchases,
    t4.total_units AS total_claw_units,
    t3.total_purchases
FROM t3 JOIN t4
    ON t3.cus_id = t4.cus_id;


-- Task 14: Find the listing of all customers who purchased 7 or more line_units in total
-- for all of their invoices. 
SELECT 
    c.cus_id AS 'Customer ID',
    CONCAT(c.first_name, ' ', c.last_name) AS `Name`,
    SUM(il.num_units) AS 'Sum of Units'
FROM customer c JOIN invoice i
    ON c.cus_id = i.cus_id
JOIN inv_line il
    ON i.inv_number = il.inv_number
GROUP BY c.cus_id
HAVING SUM(il.num_units) >= 7;


-- Task 15: Write a query listing the products that are NOT supplied by a vendor.
SELECT 
  prod_code,
  descript,
  stocking_date
FROM product
WHERE vend_id IS NULL;


-- Task 16: Write a query to find out if there is any previous order by the vendor 
-- that supplies the product 'B&D jigsaw, 8-in. blade', and what vendor it is.
SELECT 
  p.prod_code,
  p.descript,
  v.vend_id,
  v.vend_name,
  v.prev_order
FROM product p JOIN vendor v
  ON p.vend_id = v.vend_id
WHERE p.descript = 'B&D jigsaw, 8-in. blade';


-- Task 17: Write a query that lists the description and the number of units for the 
-- products stocked before the year 2002.
SELECT
  prod_code,
  descript,
  stocking_date,
  onhand_units,
  vend_id
FROM product
WHERE YEAR(stocking_date) < 2002
ORDER BY stocking_date;

