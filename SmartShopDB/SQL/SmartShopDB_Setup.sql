 -- =======================================================
-- STEP 0: Drop the database if it exists (start fresh)
-- =======================================================
IF DB_ID('SmartShopDB') IS NOT NULL
BEGIN
    -- force disconnect any users so the drop will succeed
    ALTER DATABASE SmartShopDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SmartShopDB;
END
GO

-- =======================================================
-- STEP 1: Create the database
-- =======================================================
CREATE DATABASE SmartShopDB;
GO

-- Use the database
USE SmartShopDB;
GO

--================================================================
-- make sure existing tables are removed before attempting to create
--================================================================
IF OBJECT_ID('dbo.Order_Items','U') IS NOT NULL DROP TABLE dbo.Order_Items;
IF OBJECT_ID('dbo.Payments','U') IS NOT NULL DROP TABLE dbo.Payments;
IF OBJECT_ID('dbo.Orders','U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Products','U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Customers','U') IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Branches','U') IS NOT NULL DROP TABLE dbo.Branches;
GO

-- =======================================================
-- STEP 2: Create Tables
-- =======================================================

-- Branches Table
-- (table dropped above if it already existed)
CREATE TABLE dbo.Branches (
    branch_id INT PRIMARY KEY IDENTITY(1,1),
    branch_name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    city VARCHAR(50),
    manager_name VARCHAR(100)
);
GO

-- Customers Table
CREATE TABLE dbo.Customers (
    customer_id INT PRIMARY KEY IDENTITY(1,1),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(255),
    region VARCHAR(50),
    created_at DATETIME DEFAULT GETDATE()
);
GO

-- Products Table
CREATE TABLE dbo.Products (
    product_id INT PRIMARY KEY IDENTITY(1,1),
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT NOT NULL,
    branch_id INT,
    FOREIGN KEY (branch_id) REFERENCES dbo.Branches(branch_id)
);
GO

-- Orders Table
CREATE TABLE dbo.Orders (
    order_id INT PRIMARY KEY IDENTITY(1,1),
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    order_date DATETIME DEFAULT GETDATE(),
    total_amount DECIMAL(10,2),
    order_type VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES dbo.Branches(branch_id)
);
GO

-- Order_Items Table (junction table for many-to-many)
CREATE TABLE dbo.Order_Items (
    order_item_id INT PRIMARY KEY IDENTITY(1,1),
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2),
    subtotal DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES dbo.Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES dbo.Products(product_id)
);
GO

-- Payments Table (1-to-1 with Orders)
CREATE TABLE dbo.Payments (
    payment_id INT PRIMARY KEY IDENTITY(1,1),
    order_id INT UNIQUE,
    payment_method VARCHAR(50),
    payment_amount DECIMAL(10,2),
    payment_date DATETIME DEFAULT GETDATE(),
    payment_status VARCHAR(20),
    FOREIGN KEY (order_id) REFERENCES dbo.Orders(order_id)
);
GO

-- =======================================================
-- STEP 3: Insert Sample Data
-- =======================================================

-- Branches
-- clear any existing sample rows before inserting
DELETE FROM dbo.Branches;
INSERT INTO dbo.Branches (branch_name, location, city, manager_name)
VALUES 
('Colombo Central', 'Colombo Downtown', 'Colombo', 'Nimal Perera'),
('Kandy City', 'Kandy Shopping Mall', 'Kandy', 'Saman Silva'),
('Galle Fort', 'Galle Historic District', 'Galle', 'Anna Jayasinghe'),
('Online Warehouse', 'Distribution Center', 'Colombo', 'Online Manager');
GO

-- Customers
DELETE FROM dbo.Customers;
INSERT INTO dbo.Customers (first_name, last_name, email, phone, address, region)
VALUES
('Kasun', 'Fernando', 'kasun@email.com', '0771234567', 'Colombo', 'Western'),
('Malini', 'Perera', 'malini@email.com', '0719876543', 'Kandy', 'Central'),
('Ruwan', 'Silva', 'ruwan@email.com', '0751122334', 'Galle', 'Southern'),
('Priya', 'Bandara', 'priya@email.com', '0772345678', 'Colombo', 'Western'),
('Suresh', 'Nawaz', 'suresh@email.com', '0773456789', 'Kandy', 'Central'),
('Annika', 'de Silva', 'annika@email.com', '0774567890', 'Galle', 'Southern'),
('Deepak', 'Gupta', 'deepak@email.com', '0775678901', 'Colombo', 'Western'),
('Samantha', 'Wijeratne', 'samantha@email.com', '0776789012', 'Jaffna', 'Northern'),
('Niroshan', 'Weerasinghe', 'niroshan@email.com', '0777890123', 'Colombo', 'Western'),
('Lakshmi', 'Kaur', 'lakshmi@email.com', '0778901234', 'Colombo', 'Western');
GO

-- Products
DELETE FROM dbo.Products;
INSERT INTO dbo.Products (product_name, category, price, stock_quantity, branch_id)
VALUES
('Laptop', 'Electronics', 250000, 10, 1),
('Smartphone', 'Electronics', 150000, 20, 1),
('Office Chair', 'Furniture', 45000, 15, 2),
('Headphones', 'Electronics', 15000, 30, 3),
('Desk Lamp', 'Furniture', 8500, 25, 1),
('USB-C Cable', 'Electronics', 2500, 100, 1),
('Wireless Mouse', 'Electronics', 5500, 45, 2),
('Monitor Stand', 'Furniture', 12000, 20, 3),
('Keyboard', 'Electronics', 8000, 35, 1),
('Desk Organizer', 'Furniture', 3500, 50, 2);
GO

-- Orders
DELETE FROM dbo.Orders;
INSERT INTO dbo.Orders (customer_id, branch_id, total_amount, order_type, order_date)
VALUES
(1, 1, 265000, 'In-Store', DATEADD(day, -90, GETDATE())),
(2, 2, 45000, 'In-Store', DATEADD(day, -85, GETDATE())),
(3, 3, 15000, 'Online', DATEADD(day, -80, GETDATE())),
(4, 1, 158500, 'In-Store', DATEADD(day, -75, GETDATE())),
(5, 2, 25000, 'Online', DATEADD(day, -70, GETDATE())),
(6, 3, 120000, 'In-Store', DATEADD(day, -65, GETDATE())),
(7, 1, 75500, 'Online', DATEADD(day, -60, GETDATE())),
(8, 4, 18000, 'Online', DATEADD(day, -55, GETDATE())),
(1, 2, 42500, 'In-Store', DATEADD(day, -50, GETDATE())),
(3, 1, 108000, 'Online', DATEADD(day, -45, GETDATE())),
(4, 2, 60000, 'Online', DATEADD(day, -40, GETDATE())),
(5, 3, 90000, 'In-Store', DATEADD(day, -35, GETDATE())),
(6, 1, 30000, 'Online', DATEADD(day, -30, GETDATE())),
(7, 2, 120000, 'In-Store', DATEADD(day, -25, GETDATE())),
(8, 3, 45000, 'Online', DATEADD(day, -20, GETDATE())),
(2, 1, 52000, 'In-Store', DATEADD(day, -18, GETDATE())),
(9, 4, 23000, 'Online', DATEADD(day, -15, GETDATE())),
(10, 2, 77000, 'Online', DATEADD(day, -12, GETDATE())),
(1, 3, 125000, 'In-Store', DATEADD(day, -10, GETDATE())),
(5, 1, 83000, 'Online', DATEADD(day, -7, GETDATE())),
(3, 2, 54000, 'In-Store', DATEADD(day, -5, GETDATE())),
(6, 4, 67000, 'Online', DATEADD(day, -3, GETDATE())),
(7, 1, 95500, 'In-Store', DATEADD(day, -1, GETDATE())),
(2, 3, 48000, 'Online', GETDATE());
GO

-- Order Items
DELETE FROM dbo.Order_Items;
INSERT INTO dbo.Order_Items (order_id, product_id, quantity, unit_price, subtotal)
VALUES
(1, 1, 1, 250000, 250000),
(1, 4, 1, 15000, 15000),
(2, 3, 1, 45000, 45000),
(3, 4, 1, 15000, 15000),
(4, 2, 1, 150000, 150000),
(4, 5, 1, 8500, 8500),
(5, 6, 10, 2500, 25000),
(6, 1, 1, 250000, 250000),
(6, 9, 1, 8000, 8000),
(6, 10, 2, 3500, 7000),
(7, 2, 1, 150000, 150000),
(7, 7, 1, 5500, 5500),
(8, 6, 2, 2500, 5000),
(8, 5, 1, 8500, 8500),
(8, 4, 1, 15000, 15000),
(9, 7, 2, 5500, 11000),
(9, 8, 1, 12000, 12000),
(9, 10, 3, 3500, 10500),
(10, 1, 1, 250000, 250000),
(10, 3, 1, 45000, 45000),
(10, 9, 1, 8000, 8000),

-- additional orders for trending
(11, 2, 2, 45000, 90000),
(12, 5, 1, 90000, 90000),
(13, 1, 1, 30000, 30000),
(14, 3, 1, 120000, 120000),
(15, 8, 1, 45000, 45000),
(16, 4, 1, 52000, 52000),
(17, 9, 1, 23000, 23000),
(18, 10,1, 77000, 77000),
(19, 1, 2, 125000, 250000),
(20, 5, 1, 83000, 83000),
(21, 3, 1, 54000, 54000),
(22, 6, 1, 67000, 67000),
(23, 7, 1, 95500, 95500),
(24, 2, 1, 48000, 48000);
GO

-- Payments
DELETE FROM dbo.Payments;
INSERT INTO dbo.Payments (order_id, payment_method, payment_amount, payment_status)
VALUES
(1, 'Credit Card', 265000, 'Completed'),
(2, 'Cash', 45000, 'Completed'),
(3, 'Debit Card', 15000, 'Completed'),
(4, 'Credit Card', 158500, 'Completed'),
(5, 'Online Transfer', 25000, 'Completed'),
(6, 'Credit Card', 120000, 'Completed'),
(7, 'Online Transfer', 75500, 'Completed'),
(8, 'Debit Card', 18000, 'Pending'),
(9, 'Cash', 42500, 'Completed'),
(10, 'Credit Card', 108000, 'Completed'),
(11, 'Cash', 90000, 'Completed'),
(12, 'Credit Card', 90000, 'Completed'),
(13, 'Debit Card', 30000, 'Completed'),
(14, 'Credit Card', 120000, 'Completed'),
(15, 'Online Transfer', 45000, 'Completed'),
(16, 'Cash', 52000, 'Completed'),
(17, 'Credit Card', 23000, 'Completed'),
(18, 'Online Transfer', 77000, 'Completed'),
(19, 'Debit Card', 250000, 'Completed'),
(20, 'Credit Card', 83000, 'Completed'),
(21, 'Cash', 54000, 'Completed'),
(22, 'Credit Card', 67000, 'Completed'),
(23, 'Online Transfer', 95500, 'Pending'),
(24, 'Cash', 48000, 'Completed');
GO

-- =======================================================
-- STEP 4: Quick Verification Queries
-- =======================================================

-- Check tables
SELECT * FROM dbo.Branches;
SELECT * FROM dbo.Customers;
SELECT * FROM dbo.Products;
SELECT * FROM dbo.Orders;
SELECT * FROM dbo.Order_Items;
SELECT * FROM dbo.Payments;

-- Check join
SELECT 
    o.order_id,
    c.first_name AS CustomerName,
    b.branch_name AS Branch,
    p.product_name AS Product,
    oi.quantity,
    o.total_amount
FROM dbo.Orders o
JOIN dbo.Customers c ON o.customer_id = c.customer_id
JOIN dbo.Branches b ON o.branch_id = b.branch_id
JOIN dbo.Order_Items oi ON o.order_id = oi.order_id
JOIN dbo.Products p ON oi.product_id = p.product_id;
GO