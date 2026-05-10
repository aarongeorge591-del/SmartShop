/*
  Transaction_Concurrency_Demo.sql
  Demonstrates transaction management and concurrency control scenarios for SmartShop Ltd.
  
  Run SmartShopDB_Setup.sql first to create the database.
  
  SCENARIOS:
  1. Basic transaction with BEGIN TRAN…COMMIT
  2. Scenario where two users purchase the last item (deadlock/blocking simulation)
  3. Demonstrating isolation levels and locking
*/

USE SmartShopDB;
GO

-- =======================================================
-- SCENARIO 1: Simple Transaction - Processing an Order
-- =======================================================
-- This demonstrates a typical order processing transaction
-- that deducts stock and creates payment record atomically

PRINT '=== SCENARIO 1: Basic Order Processing Transaction ===';
GO

BEGIN TRAN ProcessOrder;

    -- Start an order transaction
    DECLARE @customerId INT = 1;
    DECLARE @productId INT = 4; -- Headphones
    DECLARE @quantityOrdered INT = 1;
    DECLARE @orderAmount DECIMAL(10,2);

    BEGIN TRY
        -- Insert the order
        INSERT INTO dbo.Orders (customer_id, branch_id, total_amount, order_type, order_date)
        VALUES (@customerId, 1, 15000, 'In-Store', GETDATE());
        
        DECLARE @orderId INT = SCOPE_IDENTITY();

        -- Insert order items
        INSERT INTO dbo.Order_Items (order_id, product_id, quantity, unit_price, subtotal)
        SELECT @orderId, @productId, @quantityOrdered, p.price, p.price * @quantityOrdered
        FROM dbo.Products p
        WHERE p.product_id = @productId;

        -- Deduct stock with isolation level protection
        UPDATE dbo.Products
        SET stock_quantity = stock_quantity - @quantityOrdered
        WHERE product_id = @productId;

        -- Record payment
        INSERT INTO dbo.Payments (order_id, payment_method, payment_amount, payment_status)
        VALUES (@orderId, 'Credit Card', 15000, 'Completed');

        COMMIT TRAN ProcessOrder;
        PRINT 'Order processed successfully. Order ID: ' + CAST(@orderId AS VARCHAR(10));
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN ProcessOrder;
        PRINT 'Error processing order: ' + ERROR_MESSAGE();
    END CATCH

GO

-- =======================================================
-- SCENARIO 2: Concurrency Issue - Last Item Race Condition
-- ======================================================= 
-- This demonstrates what happens when two users try to buy
-- the last item simultaneously
--
-- INSTRUCTIONS: Open this section in TWO query windows simultaneously
-- Window A: Run lines marked with [A]
-- Window B: Run lines marked with [B]
-- Observe the blocking and deadlock behavior

PRINT '=== SCENARIO 2: Race Condition - Two Users, One Last Item ===';
GO

-- [SETUP] Check stock before the scenario
SELECT product_id, product_name, stock_quantity 
FROM dbo.Products 
WHERE product_id = 6;
GO

/*
  [A] WINDOW A - User 1
  
  -- Check current stock
  SELECT @@SPID AS SessionID, stock_quantity FROM dbo.Products WHERE product_id = 6;
  
  -- Begin transaction with SERIALIZABLE isolation to prevent race condition
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
  BEGIN TRAN UserATransaction;
  
    -- User A reads stock (acquires RANGE lock)
    SELECT 'User A reading stock' AS Action, stock_quantity 
    FROM dbo.Products 
    WHERE product_id = 6;
    
    WAITFOR DELAY '00:00:05';  -- Simulate thinking time - WAIT HERE FOR USER B
    
    -- User A tries to deduct stock
    UPDATE dbo.Products 
    SET stock_quantity = stock_quantity - 1 
    WHERE product_id = 6;
    
    PRINT 'User A: Stock updated. Check Window B now.';
    
    WAITFOR DELAY '00:00:05';  -- Wait for user B to attempt update
    
  COMMIT TRAN UserATransaction;
  PRINT 'User A transaction committed.';
  
  -- Check final stock
  SELECT stock_quantity FROM dbo.Products WHERE product_id = 6;
*/

/*
  [B] WINDOW B - User 2 (Run after User A has started transaction)
  
  -- Check current stock
  SELECT @@SPID AS SessionID, stock_quantity FROM dbo.Products WHERE product_id = 6;
  
  -- Begin transaction with same isolation level
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
  BEGIN TRAN UserBTransaction;
  
    -- User B reads stock (will be blocked if User A has range lock)
    SELECT 'User B reading stock' AS Action, stock_quantity 
    FROM dbo.Products 
    WHERE product_id = 6;
    
    -- Try to deduct stock (this may cause DEADLOCK or BLOCKING)
    UPDATE dbo.Products 
    SET stock_quantity = stock_quantity - 1 
    WHERE product_id = 6;
    
    PRINT 'User B: Stock updated.';
    
  COMMIT TRAN UserBTransaction;
  PRINT 'User B transaction committed.';
  
  -- Check final stock
  SELECT stock_quantity FROM dbo.Products WHERE product_id = 6;
*/

GO

-- =======================================================
-- SCENARIO 3: Isolation Levels Comparison
-- =======================================================
-- Shows the impact of different isolation levels on concurrency

PRINT '=== SCENARIO 3: Isolation Levels and Their Impact ===';
GO

-- Example: Reading with READ UNCOMMITTED (Dirty Read Risk)
PRINT 'With READ UNCOMMITTED (may read uncommitted changes):';
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRAN DirtyReadTest;
    SELECT 'Isolation: READ UNCOMMITTED' AS IsolationLevel, 
           product_id, stock_quantity 
    FROM dbo.Products 
    WHERE product_id IN (1, 2, 3);
COMMIT;
GO

-- Example: Reading with REPEATABLE READ (Phantom Read Risk)
PRINT 'With REPEATABLE READ (repeatable but may see new rows):';
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRAN RepeatableReadTest;
    SELECT 'Isolation: REPEATABLE READ' AS IsolationLevel,
           product_id, stock_quantity 
    FROM dbo.Products 
    WHERE stock_quantity < 25;
COMMIT;
GO

-- Example: Reading with SERIALIZABLE (Strictest, prevents all anomalies)
PRINT 'With SERIALIZABLE (prevents dirty reads, phantom reads, and non-repeatable reads):';
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRAN SerializableTest;
    SELECT 'Isolation: SERIALIZABLE' AS IsolationLevel,
           product_id, stock_quantity 
    FROM dbo.Products 
    WHERE stock_quantity < 25;
COMMIT;
GO

-- Reset to default isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- =======================================================
-- SCENARIO 4: Deadlock Example with Lock Ordering
-- =======================================================
-- Two transactions acquiring locks in opposite order can cause deadlock

PRINT '=== SCENARIO 4: Deadlock Scenario ===';
GO

/*
  DEADLOCK SETUP (run in two windows):
  
  [A] WINDOW A:
  BEGIN TRAN DeadlockTestA;
    UPDATE dbo.Products SET stock_quantity = stock_quantity - 1 WHERE product_id = 1;
    WAITFOR DELAY '00:00:03';
    UPDATE dbo.Products SET stock_quantity = stock_quantity - 1 WHERE product_id = 2;
  COMMIT;
  
  [B] WINDOW B (start immediately after A's first update):
  BEGIN TRAN DeadlockTestB;
    UPDATE dbo.Products SET stock_quantity = stock_quantity - 1 WHERE product_id = 2;
    WAITFOR DELAY '00:00:03';
    UPDATE dbo.Products SET stock_quantity = stock_quantity - 1 WHERE product_id = 1;
  COMMIT;
  
  Result: One of these transactions will be terminated with deadlock victim error:
  "Msg 1205, Level 13, State 45, Server ... Transaction (Process ID XXX) was deadlocked..."
*/

-- Show which transaction was chosen as deadlock victim
SELECT @@SPID AS CurrentSessionID;
GO

-- =======================================================
-- SCENARIO 5: Monitoring Lock and Transaction Activity
-- =======================================================
-- Query to see active transactions and locks

PRINT '=== Monitoring Query: Active Transactions and Locks ===';
GO

-- View current transactions
-- columns transaction_begin_time and transaction_state may not exist on older servers.
-- fall back to dm_tran_active_transactions for begin_time if needed.
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('sys.dm_tran_session_transactions')
      AND name = 'transaction_begin_time'
)
BEGIN
    EXEC sp_executesql N'
    SELECT 
        t.transaction_id,
        s.session_id,
        s.login_name,
        t.transaction_begin_time,
        t.transaction_state,
        DATEDIFF(SECOND, t.transaction_begin_time, GETDATE()) AS DurationSeconds
    FROM sys.dm_exec_sessions s
    JOIN sys.dm_tran_session_transactions t ON s.session_id = t.session_id
    WHERE s.session_id > 50  -- exclude system sessions
    ORDER BY t.transaction_begin_time;';
END
ELSE
BEGIN
    -- transaction_begin_time not available; try dm_tran_active_transactions
    IF EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID('sys.dm_tran_active_transactions')
          AND name = 'begin_time'
    )
    BEGIN
        EXEC sp_executesql N'
        SELECT 
            t.transaction_id,
            s.session_id,
            s.login_name,
            at.begin_time AS transaction_begin_time,
            NULL AS transaction_state,
            DATEDIFF(SECOND, at.begin_time, GETDATE()) AS DurationSeconds
        FROM sys.dm_exec_sessions s
        JOIN sys.dm_tran_session_transactions t ON s.session_id = t.session_id
        LEFT JOIN sys.dm_tran_active_transactions at ON t.transaction_id = at.transaction_id
        WHERE s.session_id > 50
        ORDER BY at.begin_time;';
    END
    ELSE
    BEGIN
        -- no timestamp info available, fall back to basic view
        SELECT 
            t.transaction_id,
            s.session_id,
            s.login_name
        FROM sys.dm_exec_sessions s
        JOIN sys.dm_tran_session_transactions t ON s.session_id = t.session_id
        WHERE s.session_id > 50
        ORDER BY s.session_id;
    END
END


GO

-- View current locks
SELECT 
    resource_type,
    resource_subtype,
    request_session_id,
    request_status,
    request_mode,
    request_lifetime
FROM sys.dm_tran_locks
WHERE request_session_id > 50  -- exclude system sessions
ORDER BY request_session_id, resource_type;

GO

-- =======================================================
-- VERIFICATION QUERIES
-- =======================================================
-- Check final state of products after all transactions

PRINT '=== Final State After All Transactions ===';
GO

SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity
FROM dbo.Products
ORDER BY product_id;

GO

SELECT 
    o.order_id,
    c.first_name + ' ' + c.last_name AS CustomerName,
    b.branch_name,
    o.total_amount,
    o.order_type,
    o.order_date,
    p.payment_status
FROM dbo.Orders o
JOIN dbo.Customers c ON o.customer_id = c.customer_id
JOIN dbo.Branches b ON o.branch_id = b.branch_id
LEFT JOIN dbo.Payments p ON o.order_id = p.order_id
ORDER BY o.order_id DESC;

GO
