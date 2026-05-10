USE SmartShopDB;
GO

-- Top-selling products by quantity sold
SELECT 
    p.product_name,
    SUM(oi.quantity) AS total_sold
FROM dbo.Order_Items oi
JOIN dbo.Products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sold DESC;
GO