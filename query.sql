-- ============================================================
-- Query Optimization Example
-- ============================================================
-- This file shows a common SQL query before and after optimization.
-- The example uses an orders/customers dataset.

-- ---------------------------------------------------------------
-- BEFORE: Unoptimized query
-- Problems:
--   1. SELECT * fetches all columns (including unused ones)
--   2. Implicit JOIN via WHERE clause (harder to read & optimize)
--   3. Function call on indexed column (col_with_func) prevents
--      index usage (non-sargable predicate)
--   4. Correlated subquery in SELECT runs once per row
--   5. No covering index hints; full table scans likely
-- ---------------------------------------------------------------
SELECT *
FROM   orders o,
       customers c
WHERE  o.customer_id = c.id
  AND  YEAR(o.created_at) = 2024
  AND  o.status != 'cancelled'
  AND  (
         SELECT COUNT(*)
         FROM   order_items oi
         WHERE  oi.order_id = o.id
       ) > 0;


-- ---------------------------------------------------------------
-- AFTER: Optimized query
-- Improvements:
--   1. SELECT only required columns (reduces I/O & network traffic)
--   2. Explicit INNER JOIN (clearer intent, same performance or
--      better with modern optimizers)
--   3. Range predicate on created_at instead of YEAR() function
--      so the index on (created_at) can be used (sargable)
--   4. Correlated subquery replaced with EXISTS (short-circuits
--      on the first matching row instead of counting all rows)
--   5. Suggested composite index documented below
-- ---------------------------------------------------------------
SELECT o.id          AS order_id,
       o.created_at,
       o.status,
       c.id          AS customer_id,
       c.name        AS customer_name,
       c.email
FROM   orders    o
INNER JOIN customers c ON c.id = o.customer_id
WHERE  o.created_at >= '2024-01-01'
  AND  o.created_at <  '2025-01-01'
  AND  o.status != 'cancelled'
  AND  EXISTS (
         SELECT 1
         FROM   order_items oi
         WHERE  oi.order_id = o.id
       );


-- ---------------------------------------------------------------
-- Recommended indexes
-- ---------------------------------------------------------------

-- Covers the date-range filter + status filter on orders
CREATE INDEX IF NOT EXISTS idx_orders_created_status
    ON orders (created_at, status);

-- Covers the EXISTS look-up on order_items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items (order_id);
