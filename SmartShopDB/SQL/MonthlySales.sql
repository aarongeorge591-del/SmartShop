USE SmartShopDB;
GO

-- Sales per branch per month
SELECT
    b.branch_name,
    FORMAT(o.order_date, 'yyyy-MM') AS Month,
    SUM(o.total_amount) AS TotalSales
FROM dbo.Orders o
JOIN dbo.Branches b ON o.branch_id = b.branch_id
GROUP BY b.branch_name, FORMAT(o.order_date, 'yyyy-MM')
ORDER BY b.branch_name, Month;
GO