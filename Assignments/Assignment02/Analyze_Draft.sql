EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.full_name,
    COUNT(o.order_id) AS orders_count,
    SUM(o.total_amount) AS revenue
FROM customers c
         JOIN orders o ON c.customer_id = o.customer_id
WHERE c.status = 'active'
GROUP BY c.customer_id, c.full_name
ORDER BY revenue DESC
LIMIT 100;

-- For total and mean ms counter of query
SELECT
    query,
    calls,
    round(total_exec_time::numeric, 1) AS total_ms,
    round(mean_exec_time::numeric, 1)  AS mean_ms,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 15;

-- For deadlocks analysis
SELECT
    blocked.pid       AS blocked_pid,
    blocked.query     AS blocked_query,
    blocking.pid      AS blocking_pid,
    blocking.query    AS blocking_query,
    blocked.wait_event_type,
    blocked.wait_event
FROM pg_stat_activity blocked
         JOIN pg_stat_activity blocking
              ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
ORDER BY blocked.pid;


-- Query 1 search_customer_by_email
EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE email LIKE '%example%';   -- Тут був gmail, але у нас просто немає gmail, тому я поставив example


EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE email LIKE '%example.com'; -- Та застосувати GIN index (буде перевіряти під-трійки), трішки допоможе якщо важлива бізнес логіква


SELECT *
FROM customers
WHERE email = 'test@example.com';


-- Query 2 orders_by_city_and_status
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE delivery_city LIKE '%a%'
  AND status = 'paid';


EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE delivery_city = 'city'
  AND status = 'paid';

-- Query 3 heavy_join
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.full_name,
    COUNT(o.order_id) AS orders_count,
    SUM(o.total_amount) AS revenue
FROM customers c
         JOIN orders o ON c.customer_id = o.customer_id
WHERE c.status = 'active'
GROUP BY c.customer_id, c.full_name
ORDER BY revenue DESC
LIMIT 100;


-- Query 4 events_aggregation
EXPLAIN ANALYZE
SELECT
    customer_id,
    event_type,
    COUNT(*) AS events_count,
    MAX(event_time) AS last_event_time
FROM customer_events_wide
WHERE event_time >= NOW() - INTERVAL '180 days'
GROUP BY customer_id, event_type
ORDER BY events_count DESC
LIMIT 200;

-- Query 5 items_products_join
EXPLAIN ANALYZE
SELECT
    p.category,
    COUNT(*) AS items_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
         JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Query 6 cartesian_pressure
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM customers c
         JOIN orders o ON o.customer_id = c.customer_id
         JOIN customer_events_wide e ON e.customer_id = c.customer_id
WHERE c.status IN ('active', 'inactive')
  AND e.event_time >= NOW() - INTERVAL '90 days';
