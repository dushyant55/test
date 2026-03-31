# test

## Query Optimization

`query.sql` contains a before/after example of a common SQL query optimization.

### What was changed and why

| # | Issue | Fix |
|---|-------|-----|
| 1 | `SELECT *` fetches every column | Select only the columns you actually need |
| 2 | Implicit comma-join in `FROM` | Use explicit `INNER JOIN … ON` for clarity and consistent optimizer behavior |
| 3 | `YEAR(created_at) = 2024` wraps an indexed column in a function (non-sargable) | Replace with a range predicate `created_at >= '2024-01-01' AND created_at < '2025-01-01'` so the index can be used |
| 4 | Correlated `SELECT COUNT(*) … > 0` subquery runs once per row | Replace with `EXISTS (SELECT 1 …)` which short-circuits on the first match |
| 5 | Missing indexes | Add composite index on `orders(created_at, status)` and index on `order_items(order_id)` |

### Recommended indexes

```sql
CREATE INDEX idx_orders_created_status ON orders (created_at, status);
CREATE INDEX idx_order_items_order_id  ON order_items (order_id);
```
