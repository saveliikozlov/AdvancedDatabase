-- Optimization 3: events_aggregation
-- Normalization + partitioning of customer_events_wide
-- Before: Seq Scan on wide table
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, event_type, COUNT(*) AS events_count, MAX(event_time) AS last_event_time
FROM customer_events_wide
WHERE event_time >= NOW() - INTERVAL '180 days'
GROUP BY customer_id, event_type
ORDER BY events_count DESC
LIMIT 200;

-- Step 1: narrow hot table, partitioned by event_time (monthly RANGE)
DROP TABLE IF EXISTS customer_events CASCADE;
CREATE TABLE customer_events (
    event_id    integer NOT NULL,
    customer_id integer,
    event_type  text,
    event_time  timestamp NOT NULL
) PARTITION BY RANGE (event_time);

DO $$
DECLARE
    m date := '2025-06-01';
BEGIN
    WHILE m <= '2026-06-01' LOOP
        EXECUTE format(
            'CREATE TABLE customer_events_%s PARTITION OF customer_events
             FOR VALUES FROM (%L) TO (%L)',
            to_char(m, 'YYYY_MM'), m, m + interval '1 month');
        m := m + interval '1 month';
    END LOOP;
END $$;

-- Step 2: cold attributes table (normalization)
DROP TABLE IF EXISTS customer_event_attrs;
CREATE TABLE customer_event_attrs AS
SELECT event_id, source, campaign, device, browser, os, ip_address,
       page_url, referrer, utm_source, utm_medium, utm_campaign,
       attr_01, attr_02, attr_03, attr_04, attr_05,
       attr_06, attr_07, attr_08, attr_09, attr_10
FROM customer_events_wide;

ALTER TABLE customer_event_attrs ADD PRIMARY KEY (event_id);

-- Step 3: migrate hot data
INSERT INTO customer_events (event_id, customer_id, event_type, event_time)
SELECT event_id, customer_id, event_type, event_time
FROM customer_events_wide;

CREATE INDEX idx_events_part_customer_id ON customer_events (customer_id);


-- After: partition pruning + narrow rows
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, event_type, COUNT(*) AS events_count, MAX(event_time) AS last_event_time
FROM customer_events
WHERE event_time >= NOW() - INTERVAL '180 days'
GROUP BY customer_id, event_type
ORDER BY events_count DESC
LIMIT 200;

-- In addition: narrow time window -> pruning leaves 1-2 partitions
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, event_type, COUNT(*) AS events_count
FROM customer_events
WHERE event_time >= NOW() - INTERVAL '14 days'
GROUP BY customer_id, event_type
ORDER BY events_count DESC
LIMIT 200;

-- Shared benefit for cartesian_pressure (Query #5)
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN customer_events e ON e.customer_id = c.customer_id
WHERE c.status IN ('active', 'inactive')
  AND e.event_time >= NOW() - INTERVAL '90 days';