CREATE TABLE Employee (
  EmpID           CHAR(5)       PRIMARY KEY,
  EmpFName        VARCHAR(50),
  EmpLName        VARCHAR(50),
  EmpType         VARCHAR(20),
  EmpStreetNo     VARCHAR(10),
  EmpStreetName   VARCHAR(100),
  EmpCity         VARCHAR(50),
  EmpState        CHAR(2),
  EmpZIP          VARCHAR(10),
  EmpPhone        VARCHAR(15),
  EmpEmail        VARCHAR(100),
  EmpDOB          DATE,
  SupervisorID    CHAR(5),
  FOREIGN KEY (SupervisorID)
    REFERENCES Employee(EmpID)
);

CREATE TABLE Supplier (
  SupplierID          CHAR(5)       PRIMARY KEY,
  SupplierName        VARCHAR(100),
  SupplierStreetNo    VARCHAR(10),
  SupplierStreetName  VARCHAR(100),
  SupplierCity        VARCHAR(50),
  SupplierState       CHAR(2),
  SupplierZIP         VARCHAR(10),
  SupplierPhone       VARCHAR(15),
  SupplierEmail       VARCHAR(100)
);

CREATE TABLE SupplierOrder (
  SupOrderID        CHAR(5)       PRIMARY KEY,
  SupOrderSendDate  DATE,
  SupOrderRecdDate  DATE,
  SupOrderAmount    DECIMAL(10,2),
  EmpID             CHAR(5),
  SupplierID        CHAR(5),
  FOREIGN KEY (EmpID)
    REFERENCES Employee(EmpID),
  FOREIGN KEY (SupplierID)
    REFERENCES Supplier(SupplierID)
);

CREATE TABLE Product (
  ProdID        CHAR(5)       PRIMARY KEY,
  ProdName      VARCHAR(100),
  ProdListPrice DECIMAL(10,2),
  ProdCostPrice DECIMAL(10,2),
  ProdOnHand    INT,
  ProdReorder   INT,
  SupplierID    CHAR(5),
  FOREIGN KEY (SupplierID)
    REFERENCES Supplier(SupplierID)
);

CREATE TABLE Customer (
  CustID          CHAR(5)       PRIMARY KEY,
  CustFName       VARCHAR(50),
  CustLName       VARCHAR(50),
  CustStreetNo    VARCHAR(10),
  CustStreetName  VARCHAR(100),
  CustCity        VARCHAR(50),
  CustState       CHAR(2),
  CustZIP         VARCHAR(10),
  CustPhone       VARCHAR(15),
  CustEmail       VARCHAR(100)
);

CREATE TABLE CustomerOrder (
  CustOrderID           CHAR(5)       PRIMARY KEY,
  CustOrderRecdDate     DATE,
  CustOrderShipDate     DATE,
  CustOrderPayment      DECIMAL(10,2),
  CustOrderPaymentRecd  DATE,
  CustID                CHAR(5),
  FOREIGN KEY (CustID)
    REFERENCES Customer(CustID)
);

-- 1) supplier order lines
CREATE TABLE SupplierOrderItem (
  SupOrderID CHAR(5) NOT NULL,
  ProdID     CHAR(5) NOT NULL,
  Quantity   INT       NOT NULL,
  PRIMARY KEY (SupOrderID, ProdID),
  FOREIGN KEY (SupOrderID) REFERENCES SupplierOrder(SupOrderID),
  FOREIGN KEY (ProdID)     REFERENCES Product(ProdID)
);

-- 2) customer order lines
CREATE TABLE CustomerOrderItem  (
  CustOrderID CHAR(5) NOT NULL,
  ProdID      CHAR(5) NOT NULL,
  Quantity    INT       NOT NULL,
  PRIMARY KEY (CustOrderID, ProdID),
  FOREIGN KEY (CustOrderID) REFERENCES CustomerOrder(CustOrderID),
  FOREIGN KEY (ProdID)      REFERENCES Product(ProdID)
);

---
--Supplier Table
---

ALTER TABLE Supplier
  ADD Region VARCHAR(20);

--check it!
-- select * from Supplier;

-- 3) Seed name-lists and region list
WITH FirstNames AS (
  SELECT * FROM (VALUES
    ('Alice'),('Bob'),('Charlie'),('Doug'),('Eve'),
    ('Frank'),('Grace'),('Heidi'),('Ivan'),('Judy'),
    ('Mallory'),('Niaj'),('Olivia'),('Peggy'),('Trent')
  ) AS f(name)
),
LastNames AS (
  SELECT * FROM (VALUES
    ('Smith'),('Jones'),('Williams'),('Brown'),('Davis'),
    ('Miller'),('Wilson'),('Moore'),('Taylor'),('Anderson'),
    ('Thomas'),('Jackson'),('White'),('Harris'),('Martin')
  ) AS l(name)
),
Streets AS (
  SELECT * FROM (VALUES
    ('Main St'),('Oak Ave'),('Pine Rd'),('Maple Dr'),
    ('Cedar Ln'),('Elm St'),('Washington Blvd'),('Lakeview Way'),
    ('Sunset Blvd'),('Hilltop Rd')
  ) AS s(name)
),
Cities AS (
  SELECT * FROM (VALUES
    ('New York','NY','100'),('Los Angeles','CA','900'),
    ('Chicago','IL','606'),('Houston','TX','770'),
    ('Phoenix','AZ','850'),('Philadelphia','PA','191'),
    ('San Antonio','TX','782'),('San Diego','CA','921'),
    ('Dallas','TX','752'),('San Jose','CA','951')
  ) AS c(city, state, zipprefix)
),
Regions AS (
  SELECT * FROM (VALUES
    ('Asia'),('Europe'),('Africa'),('South America'),('North America')
  ) AS r(region)
)
-- 4) Populate 10 Suppliers (2 per region)
, Num AS (
  SELECT GENERATE_SERIES(1, 10) AS n
)
INSERT INTO Supplier
  (SupplierID,SupplierName,SupplierStreetNo,SupplierStreetName,
   SupplierCity,SupplierState,SupplierZIP,SupplierPhone,
   SupplierEmail,Region)
SELECT
  LPAD(CAST(n AS VARCHAR),5,'0'),
  -- make up names
  CONCAT(LEFT(fn.Name,3), ' ', LEFT(ln.Name,4)),
  CAST(FLOOR(RANDOM()*999)+1 AS VARCHAR), -- street no
  st.Name,
  ct.City, ct.State,
  ct.ZipPrefix || LPAD(CAST(FLOOR(RANDOM()*99) AS VARCHAR),2,'0'),
  CONCAT('(',FLOOR(RANDOM()*900)+100,')', FLOOR(RANDOM()*900)+100,'-',FLOOR(RANDOM()*9000)+1000),
  LOWER(fn.Name || '.' || ln.Name || '@supplier.com'),
  -- region: each region twice
  CASE
    WHEN n BETWEEN 1 AND 2 THEN 'Asia'
    WHEN n BETWEEN 3 AND 4 THEN 'Europe'
    WHEN n BETWEEN 5 AND 6 THEN 'Africa'
    WHEN n BETWEEN 7 AND 8 THEN 'South America'
    ELSE 'North America'
  END
FROM Num
CROSS JOIN LATERAL (SELECT name FROM FirstNames ORDER BY RANDOM() LIMIT 1) fn
CROSS JOIN LATERAL (SELECT name FROM LastNames  ORDER BY RANDOM() LIMIT 1) ln
CROSS JOIN LATERAL (SELECT name FROM Streets    ORDER BY RANDOM() LIMIT 1) st
CROSS JOIN LATERAL (SELECT city, state, zipprefix FROM Cities ORDER BY RANDOM() LIMIT 1) ct
ORDER BY n
;

-- 5) Populate 20 Employees (random supervisors allowed to be NULL)
WITH Tally AS (
  SELECT GENERATE_SERIES(1, 20) AS n
),
FirstNames AS (
  SELECT * FROM (VALUES
    ('Alice'),('Bob'),('Charlie'),('Doug'),('Eve'),
    ('Frank'),('Grace'),('Heidi'),('Ivan'),('Judy'),
    ('Mallory'),('Niaj'),('Olivia'),('Peggy'),('Trent')
  ) AS f(name)
),
LastNames AS (
  SELECT * FROM (VALUES
    ('Smith'),('Jones'),('Williams'),('Brown'),('Davis'),
    ('Miller'),('Wilson'),('Moore'),('Taylor'),('Anderson'),
    ('Thomas'),('Jackson'),('White'),('Harris'),('Martin')
  ) AS l(name)
),
Streets AS (
  SELECT * FROM (VALUES
    ('Main St'),('Oak Ave'),('Pine Rd'),('Maple Dr'),
    ('Cedar Ln'),('Elm St'),('Washington Blvd'),('Lakeview Way'),
    ('Sunset Blvd'),('Hilltop Rd')
  ) AS s(name)
),
Cities AS (
  SELECT * FROM (VALUES
    ('New York','NY','100'),('Los Angeles','CA','900'),
    ('Chicago','IL','606'),('Houston','TX','770'),
    ('Phoenix','AZ','850'),('Philadelphia','PA','191'),
    ('San Antonio','TX','782'),('San Diego','CA','921'),
    ('Dallas','TX','752'),('San Jose','CA','951')
  ) AS c(city, state, zipprefix)
)
INSERT INTO Employee
  (EmpID,EmpFName,EmpLName,EmpType,EmpStreetNo,EmpStreetName,
   EmpCity,EmpState,EmpZIP,EmpPhone,EmpEmail,EmpDOB,SupervisorID)
SELECT
  LPAD(CAST(n AS VARCHAR),5,'0'),
  fn.Name, ln.Name,
  CASE WHEN n%3=0 THEN 'Manager' WHEN n%3=1 THEN 'Staff' ELSE 'Contractor' END,
  CAST(FLOOR(RANDOM()*999)+1 AS VARCHAR),
  st.Name,
  ct.City, ct.State,
  ct.ZipPrefix || LPAD(CAST(FLOOR(RANDOM()*99) AS VARCHAR),2,'0'),
  CONCAT('(',FLOOR(RANDOM()*900)+100,')', FLOOR(RANDOM()*900)+100,'-',FLOOR(RANDOM()*9000)+1000),
  LOWER(fn.Name || '.' || ln.Name || '@company.com'),
  (CURRENT_DATE - INTERVAL '1 day' * (FLOOR(RANDOM()*15000)))::DATE,  -- random DOB in last ~40 years
  CASE WHEN n<=3 THEN NULL
    ELSE LPAD(CAST(FLOOR(RANDOM()*(n-1))+1 AS VARCHAR),5,'0')
  END
FROM Tally
CROSS JOIN LATERAL (SELECT name FROM FirstNames ORDER BY RANDOM() LIMIT 1) fn
CROSS JOIN LATERAL (SELECT name FROM LastNames  ORDER BY RANDOM() LIMIT 1) ln
CROSS JOIN LATERAL (SELECT name FROM Streets    ORDER BY RANDOM() LIMIT 1) st
CROSS JOIN LATERAL (SELECT city, state, zipprefix FROM Cities ORDER BY RANDOM() LIMIT 1) ct
ORDER BY n
;

-- 6) Populate 50 Products
WITH Tally AS (
  SELECT GENERATE_SERIES(1, 50) AS n
)
INSERT INTO Product
  (ProdID,ProdName,ProdListPrice,ProdCostPrice,ProdOnHand,ProdReorder,SupplierID)
SELECT
  LPAD(CAST(n AS VARCHAR),5,'0'),
  CONCAT('Prod',n),
  ROUND((20 + (FLOOR(RANDOM()*500))/100.0)::NUMERIC,2),   -- list price 20.00–24.99
  ROUND((10 + (FLOOR(RANDOM()*1000))/100.0)::NUMERIC,2),  -- cost price 10.00–19.99
  FLOOR(RANDOM()*200),                          -- on hand 0–199
  10 + FLOOR(RANDOM()*20),                          -- reorder 10–29
  -- random supplier
  LPAD(CAST((FLOOR(RANDOM()*10))+1 AS VARCHAR),5,'0')
FROM Tally
ORDER BY n
;

-- 7) Populate 250 Customers (all US)
WITH Tally AS (
  SELECT GENERATE_SERIES(1, 250) AS n
),
FirstNames AS (
  SELECT * FROM (VALUES
    ('Alice'),('Bob'),('Charlie'),('Doug'),('Eve'),
    ('Frank'),('Grace'),('Heidi'),('Ivan'),('Judy'),
    ('Mallory'),('Niaj'),('Olivia'),('Peggy'),('Trent')
  ) AS f(name)
),
LastNames AS (
  SELECT * FROM (VALUES
    ('Smith'),('Jones'),('Williams'),('Brown'),('Davis'),
    ('Miller'),('Wilson'),('Moore'),('Taylor'),('Anderson'),
    ('Thomas'),('Jackson'),('White'),('Harris'),('Martin')
  ) AS l(name)
),
Streets AS (
  SELECT * FROM (VALUES
    ('Main St'),('Oak Ave'),('Pine Rd'),('Maple Dr'),
    ('Cedar Ln'),('Elm St'),('Washington Blvd'),('Lakeview Way'),
    ('Sunset Blvd'),('Hilltop Rd')
  ) AS s(name)
),
Cities AS (
  SELECT * FROM (VALUES
    ('New York','NY','100'),('Los Angeles','CA','900'),
    ('Chicago','IL','606'),('Houston','TX','770'),
    ('Phoenix','AZ','850'),('Philadelphia','PA','191'),
    ('San Antonio','TX','782'),('San Diego','CA','921'),
    ('Dallas','TX','752'),('San Jose','CA','951')
  ) AS c(city, state, zipprefix)
)
INSERT INTO Customer
  (CustID,CustFName,CustLName,CustStreetNo,CustStreetName,
   CustCity,CustState,CustZIP,CustPhone,CustEmail)
SELECT
  LPAD(CAST(n AS VARCHAR),5,'0'),
  fn.Name, ln.Name,
  CAST(FLOOR(RANDOM()*999)+1 AS VARCHAR),
  st.Name,
  ct.City, ct.State,
  ct.ZipPrefix || LPAD(CAST(FLOOR(RANDOM()*99) AS VARCHAR),2,'0'),
  CONCAT('(',FLOOR(RANDOM()*900)+100,')', FLOOR(RANDOM()*900)+100,'-',FLOOR(RANDOM()*9000)+1000),
  LOWER(fn.Name || '.' || ln.Name || '@customer.com')
FROM Tally
CROSS JOIN LATERAL (SELECT name FROM FirstNames ORDER BY RANDOM() LIMIT 1) fn
CROSS JOIN LATERAL (SELECT name FROM LastNames  ORDER BY RANDOM() LIMIT 1) ln
CROSS JOIN LATERAL (SELECT name FROM Streets    ORDER BY RANDOM() LIMIT 1) st
CROSS JOIN LATERAL (SELECT city, state, zipprefix FROM Cities ORDER BY RANDOM() LIMIT 1) ct
ORDER BY n
;

-- 8) Populate 500 CustomerOrders
WITH Tally AS (
  SELECT GENERATE_SERIES(1, 500) AS n
)
INSERT INTO CustomerOrder
  (CustOrderID,CustOrderRecdDate,CustOrderShipDate,
   CustOrderPayment,CustOrderPaymentRecd,CustID)
SELECT
  LPAD(CAST(n AS VARCHAR),5,'0'),
  -- received in Feb 2025
  ('2025-02-01'::DATE + (FLOOR(RANDOM()*28) * INTERVAL '1 day'))::DATE,
  -- shipped in March 2025
  ('2025-03-01'::DATE + (FLOOR(RANDOM()*31) * INTERVAL '1 day'))::DATE,
  -- payment amount random 100–500
  ROUND((100 + (FLOOR(RANDOM()*400)))::NUMERIC,2),
  -- payment recd in April 2025
  ('2025-04-01'::DATE + (FLOOR(RANDOM()*30) * INTERVAL '1 day'))::DATE,
  -- random customer
  LPAD(CAST((FLOOR(RANDOM()*250))+1 AS VARCHAR),5,'0')
FROM Tally
ORDER BY n
;

-- 9) Populate 500 SupplierOrders
WITH Tally AS (
  SELECT GENERATE_SERIES(1, 500) AS n
)
INSERT INTO SupplierOrder
  (SupOrderID,SupOrderSendDate,SupOrderRecdDate,
   SupOrderAmount,EmpID,SupplierID)
SELECT
  LPAD(CAST(n AS VARCHAR),5,'0'),
  -- sent in Jan 2025
  ('2025-01-01'::DATE + (FLOOR(RANDOM()*31) * INTERVAL '1 day'))::DATE,
  -- recd in Feb 2025
  ('2025-02-01'::DATE + (FLOOR(RANDOM()*28) * INTERVAL '1 day'))::DATE,
  -- amount random 500–2000
  ROUND((500 + (FLOOR(RANDOM()*1500)))::NUMERIC,2),
  -- random employee
  LPAD(CAST((FLOOR(RANDOM()*20))+1 AS VARCHAR),5,'0'),
  -- random supplier
  LPAD(CAST((FLOOR(RANDOM()*10))+1 AS VARCHAR),5,'0')
FROM Tally
ORDER BY n;


-- 1) Customer orders
INSERT INTO CustomerOrderItem (CustOrderID, ProdID, Quantity)
SELECT
  o.CustOrderID,
  x.ProdID,
  -- random quantity 1–10
  FLOOR(RANDOM()*10) + 1
FROM CustomerOrder AS o
CROSS JOIN LATERAL (
  -- pick between 1 and 5 distinct products
  SELECT ProdID
  FROM Product
  ORDER BY RANDOM()
  LIMIT (FLOOR(RANDOM()*5) + 1)
) AS x;

-- 2) Supplier orders
INSERT INTO SupplierOrderItem (SupOrderID, ProdID, Quantity)
SELECT
  o.SupOrderID,
  x.ProdID,
  -- random quantity 1–20
  FLOOR(RANDOM()*20) + 1
FROM SupplierOrder AS o
CROSS JOIN LATERAL (
  SELECT ProdID
  FROM Product
  ORDER BY RANDOM()
  LIMIT (FLOOR(RANDOM()*5) + 1)
) AS x;

-- Quick counts to verify:
-- SELECT
--   (SELECT COUNT(*) FROM Supplier)          AS Suppliers,
--   (SELECT COUNT(*) FROM Employee)          AS Employees,
--   (SELECT COUNT(*) FROM Product)           AS Products,
--   (SELECT COUNT(*) FROM Customer)          AS Customers,
--   (SELECT COUNT(*) FROM CustomerOrder)     AS CustOrders,
--   (SELECT COUNT(*) FROM SupplierOrder)     AS SupOrders;

-- select * from Supplier;
-- select * from Employee;
-- select * from Product;
-- select * from Customer;
-- select * from CustomerOrder;
-- select * from SupplierOrder;

-- User creation for PostgreSQL
-- Note: PostgreSQL user management and permissions are different from SQL Server.
-- You'd typically use `CREATE USER` and then `GRANT` privileges.
-- The concept of "contained user" is specific to SQL Server.

-- 1) Drop the user if it exists
-- DROP USER IF EXISTS professor1;

-- -- 2) Create the user with password
-- CREATE USER professor1 WITH PASSWORD 'ChangeMe123!';

-- -- 3) Grant read-only access
-- GRANT CONNECT ON DATABASE postgres TO professor1; -- Grant connect to your database (e.g., 'postgres')
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO professor1; -- Grant select on all tables in the 'public' schema
-- GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO professor1; -- Grant select on sequences if needed for auto-incrementing IDs