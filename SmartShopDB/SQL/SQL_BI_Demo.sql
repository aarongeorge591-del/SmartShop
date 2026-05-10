/*
  SQL_BI_Demo.sql - sample business intelligence queries
  Run against the SmartShopDB database created by SmartShopDB_Setup.sql.
  Includes aggregation, grouping, and recent activity examples.
*/

USE SmartShopDB;
GO

-- =====================================
-- 1️Top-selling products (by quantity)
-- =====================================
SELECT 
    p.product_name,
    SUM(oi.quantity) AS total_sold,
    SUM(oi.quantity * oi.unit_price) AS total_sales_amount
FROM Order_Items oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sold DESC;
GO

-- =====================================
-- 2️Monthly sales per branch
-- =====================================
SELECT
    b.branch_name,
    FORMAT(o.order_date, 'yyyy-MM') AS Month,
    SUM(o.total_amount) AS TotalSales
FROM Orders o
JOIN Branches b ON o.branch_id = b.branch_id
GROUP BY b.branch_name, FORMAT(o.order_date, 'yyyy-MM')
ORDER BY b.branch_name, Month;
GO

-- =====================================
-- 3️Customer spend summary
-- =====================================
SELECT
    c.first_name + ' ' + c.last_name AS Customer,
    COUNT(o.order_id) AS NumberOfOrders,
    SUM(o.total_amount) AS TotalSpent
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
GROUP BY c.first_name, c.last_name
ORDER BY TotalSpent DESC;
GO

-- =====================================
-- 4️Orders in the last 7 days
-- =====================================
SELECT 
    o.order_id,
    c.first_name + ' ' + c.last_name AS Customer,
    o.order_date,
    o.total_amount
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= DATEADD(day, -7, GETDATE())
ORDER BY o.order_date DESC;
GO

-- =====================================
-- 5️Product sales per category
-- =====================================
SELECT 
    p.category,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.unit_price) AS total_sales
FROM Order_Items oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_sales DESC;
GO

-- =====================================
-- 6️Top branches by total sales
-- =====================================
SELECT
    b.branch_name,
    SUM(o.total_amount) AS BranchSales
FROM Orders o
JOIN Branches b ON o.branch_id = b.branch_id
GROUP BY b.branch_name
ORDER BY BranchSales DESC;
GO

-- =====================================
-- 7️Low stock products (threshold 20)
-- =====================================
SELECT
    product_name,
    stock_quantity
FROM Products
WHERE stock_quantity < 20
ORDER BY stock_quantity;
GO
