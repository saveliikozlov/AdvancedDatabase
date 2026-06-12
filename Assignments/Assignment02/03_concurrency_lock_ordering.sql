-- Bonus: Concurrency — lock contention & deadlocks
-- Diagnostics: who blocks whom right now
SELECT
    blocked.pid    AS blocked_pid,
    blocked.query  AS blocked_query,
    blocking.pid   AS blocking_pid,
    blocking.query AS blocking_query,
    blocked.wait_event_type,
    blocked.wait_event
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking
     ON blocking.pid = ANY (pg_blocking_pids(blocked.pid))
ORDER BY blocked.pid;

-- Deadlock counter for the database
SELECT datname, deadlocks
FROM pg_stat_database
WHERE datname = 'student_perf_lab';

-- Top queries by total time
SELECT query, calls,
       round(total_exec_time::numeric, 1) AS total_ms,
       round(mean_exec_time::numeric, 1)  AS mean_ms
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 15;


-- Deadlock demo:

-- BEFORE (opposite order -> deadlock):
-- Session T1:
--   BEGIN;
--   UPDATE customers SET country = country WHERE customer_id = 1;
--   UPDATE customers SET country = country WHERE customer_id = 2;
--   COMMIT;
-- Session T2 (between T1's two updates):
--   BEGIN;
--   UPDATE customers SET country = country WHERE customer_id = 2;
--   UPDATE customers SET country = country WHERE customer_id = 1;
--   -- ERROR: deadlock detected

-- AFTER (single global order: ascending customer_id -> no deadlock):
-- Session T1:
--   BEGIN;
--   UPDATE customers SET country = country WHERE customer_id = 1;
--   UPDATE customers SET country = country WHERE customer_id = 2;
--   COMMIT;
-- Session T2:
--   BEGIN;
--   UPDATE customers SET country = country WHERE customer_id = 1;  -- waits
--   UPDATE customers SET country = country WHERE customer_id = 2;
--   COMMIT;  -- only waiting, no deadlock

-- Ordered-lock pattern for pairs in code:
-- UPDATE first  WHERE customer_id = LEAST(a, b);
-- UPDATE second WHERE customer_id = GREATEST(a, b);

-- Symptomatic mitigations (for comparison, not the root fix):
-- SET lock_timeout = '2s';
-- SHOW deadlock_timeout;