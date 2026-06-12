-- Optimization 1: search_customer_by_email (Query #1)
-- Before: leading-% LIKE -> Seq Scan
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM customers WHERE email LIKE '%example%';

-- Rewrite: real access pattern -> exact match
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM customers WHERE email = 'test@example.com';

-- Optional: trigram index for substring search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_customers_email_trgm
    ON customers USING gin (email gin_trgm_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM customers WHERE email LIKE '%example.com';


-- Optimization 2: orders_by_city_and_status (Query #2)
-- Before: LIKE '%a%' + low-cardinality status -> Seq Scan
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders
WHERE delivery_city LIKE '%a%' AND status = 'paid';

-- Composite index for the rewritten query
CREATE INDEX IF NOT EXISTS idx_orders_city_status
    ON orders (delivery_city, status);

-- Rewrite: equality on city -> composite index works
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders
WHERE delivery_city = (SELECT delivery_city FROM orders LIMIT 1)
  AND status = 'paid';

-- Partial index for frequent status-only queries
CREATE INDEX IF NOT EXISTS idx_orders_paid
    ON orders (status) WHERE status = 'paid';

-- Left-prefix rule demo: status alone does NOT use the composite index
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE status = 'paid';
