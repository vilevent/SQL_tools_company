# MySQL, Tools Company DB
> Programming assignment from Introduction to Databases course
###### *Note: I used MySQL Workbench when completing this assignment.*

### Creating the database

Example of a CREATE TABLE statement used, which has column constraints like PRIMARY KEY, FOREIGN KEY, NOT NULL.
```sql
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
```
*The database schema from **MySQL Workbench**:*

![db_schema](https://user-images.githubusercontent.com/96803412/147631017-0e0d6d76-7ab4-4284-ba99-89939be5f648.png)

### Data handling for empty cells

Before importing the 5 CSV files into the created tables, I used Excel to find and replace Blanks with NULL for **Product.csv** and **Customer.csv**
- There were cells that appeared "empty" but contained spaces in them. To remove the spaces in the "empty" cells, I first filtered the V_CODE column in Product.csv by "(Blanks)" and then highlighted the cells to Delete the spaces. Same process was used for the CUS_INITIAL column in Customer.csv.
- Once those cells are now empty, I selected Blanks with Go To Special in order to fill all empty cells with **NULL**, and then saved the CSV files.
- The final CSV files, after completing the above in Excel, are found in the ```CSV Files``` folder.

### Importing the data

Example of a LOAD DATA INFILE statement used to import **Invoice.csv** into the invoice table. I used the ```SET``` clause to transform the date from a format like '8/18/1999' to '1999-08-18'
```sql
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
```

### Highlights

I wrote SQL queries for 17 tasks. Below are some of queries I wanted to highlight.

#### Task 1: Generate a listing of all purchases made by the customers.
- Used the ```DATE_FORMAT``` function to format the invoice date into a format like 'August 18, 1999'
- Used the ```CONCAT``` function to have the unit price displayed with the $ symbol.
```sql
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
```
###### First 5 rows in the query output for Task 1
![Task1](https://user-images.githubusercontent.com/96803412/147635876-e323f418-8bc9-478f-ad12-e6146f3705bc.png)


#### Task 4: Write a query to produce the total purchase amount per invoice.
- Used the aggregate function ```SUM``` with the ```GROUP BY``` clause in the subquery nested within the ```FROM``` clause.
- With the derived table ```t```, I was able to format the total purchase amount with the $ symbol in the outer query.
```sql
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
```
###### The 8 rows in the query output for Task 4
![Task4](https://user-images.githubusercontent.com/96803412/147636555-30653e7e-43ff-4eaf-b205-36ace605016c.png)


#### Task 7: Write a query that finds the customers who did not make any purchases during the invoicing period.
- With the ```WHERE``` clause specifying ```i.cus_id IS NULL```, I found the non-matching rows in the ```LEFT JOIN```.
```sql
SELECT 
  c.cus_id,
  c.first_name,
  c.last_name
FROM customer c LEFT JOIN invoice i
  ON c.cus_id = i.cus_id
WHERE i.cus_id IS NULL  
ORDER BY c.cus_id;
 ```
 ###### The 5 rows in the query output for Task 7
 ![Task7](https://user-images.githubusercontent.com/96803412/147636152-053935d0-34d4-4e1e-96f7-909e2e3c2f83.png)

 
 #### Task 9: Write a query to compute the total purchases amount, average purchase amount and the number of product purchases made by each customer that has invoices.
 - Used the ```ROUND``` function on the calculate average purchase amounts to obtain values having 2 decimal places.
 - When grouping by customer ID, I used the ```COUNT``` function to find the number of invoice lines/purchases made per customer.
 ```sql
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
 ```
###### The 5 rows in the query output for Task 9
![Task9](https://user-images.githubusercontent.com/96803412/147636225-bf91542a-3522-4319-9479-6534ef9a5658.png)


#### Task 12: Find the listing of all customers except those who purchased product '7.25-in. pwr. saw blade'
- Used ```TEMPORARY TABLE t2``` to store the temporary result set of the ```SELECT``` statement.
- With the ```NOT EXISTS``` operator, I found the rows that don't meet the condition in the ```WHERE``` clause of the subquery.
```sql
CREATE TEMPORARY TABLE t2 
(
  SELECT i.*, p.*
  FROM invoice i JOIN inv_line il
    ON i.inv_number = il.inv_number
  JOIN product p 
    ON il.prod_code = p.prod_code
);

SELECT 
  c.cus_id AS 'customer ID',
  CONCAT(c.first_name, ' ', c.last_name) AS 'customer name',
  c.balance
FROM customer c
WHERE NOT EXISTS (SELECT *
                  FROM t2
                  WHERE c.cus_id = t2.cus_id
                  AND t2.descript = '7.25-in. pwr. saw blade');
```
###### The 7 rows in the query output for Task 12
![Task12](https://user-images.githubusercontent.com/96803412/147636437-15a33191-6dc4-4c70-b3b3-204a91ebfb7b.png)
