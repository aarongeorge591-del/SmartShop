USE SmartShopDB;
GO

-- Start a transaction
BEGIN TRANSACTION;

-- Example: Customer buys 2 laptops
DECLARE @OrderID INT;

-- Insert new order
INSERT INTO dbo.Orders (customer_id, branch_id, total_amount, order_type)
VALUES (1, 1, 500000, 'In-Store');

-- Get the new order id
SET @OrderID = SCOPE_IDENTITY();

-- Insert order items
INSERT INTO dbo.Order_Items (order_id, product_id, quantity, unit_price, subtotal)
VALUES (@OrderID, 1, 2, 250000, 500000);

-- Update product stock (simulate concurrency-safe purchase)
UPDATE dbo.Products
SET stock_quantity = stock_quantity - 2
WHERE product_id = 1;

-- Uncomment to **commit** transaction
COMMIT TRANSACTION;

-- Or rollback if something goes wrong
-- ROLLBACK TRANSACTION;

-- Verify new order
SELECT * FROM dbo.Orders WHERE order_id = @OrderID;
SELECT * FROM dbo.Order_Items WHERE order_id = @OrderID;
SELECT product_name, stock_quantity FROM dbo.Products WHERE product_id = 1;
GO