
-- 1. customer + accounts overview
select *
from vw_customer_accounts
order by customer_id, account_id;


-- 2. recent transactions with masked card hint ( 7-days interval )
select transaction_id, customer_name, amount, currency, status, risk_score,
       merchant_country, card_masked
from vw_recent_transactions
order by transaction_at desc
limit 20;


-- 3. analyst inbox: flagged transactions
select transaction_id, customer_name, amount, currency, risk_score,
       merchant_country, alert_reason, alert_status
from vw_flagged_transactions
order by transaction_id;


-- 4. portfolio-wide risk profile
select *
from vw_customer_risk_profile
order by avg_risk_score_90d desc;


-- 5. daily fraud dashboard
call refresh_fraud_dashboard();
select *
from mv_daily_fraud_summary
order by txn_date desc;


-- 6. per-customer daily volume today
select
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer,
    current_date as as_of,
    calculate_customer_daily_volume(c.customer_id, current_date) as volume_today
from customers c
order by volume_today desc;


-- 7. transaction status history for the most recently FLAGGED txn
with last_flagged as (
    select transaction_id
    from transactions
    where status = 'FLAGGED'
    order by transaction_id desc
    limit 1
)
select h.history_id, h.transaction_id, h.old_status, h.new_status, h.changed_at, h.changed_by
from transaction_status_history h
join last_flagged lf on lf.transaction_id = h.transaction_id
order by h.changed_at;


-- 8. audit log tail
select audit_id, customer_id, table_name, operation, changed_at
from audit_log
order by audit_id desc
limit 25;


-- 9. demonstrate freeze_account procedure

do $$
declare
    v_pending bigint;
begin
    select transaction_id into v_pending
    from transactions where status = 'PENDING' order by transaction_id limit 1;
    if v_pending is not null then
        call process_transaction(v_pending);
        raise notice 'processed pending transaction %', v_pending;
    end if;
end$$;


-- 11. demonstrate batch approval

call approve_pending_transactions(40);


-- 12. demonstrate the customer-deletion guard
delete from customers where customer_id = 1;


-- 13. rank customers by 90-day flagged amount
select
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer,
    sum(t.amount) as flagged_amount_90d,
    rank() over (order by sum(t.amount) desc) as rnk
from transactions t
join accounts a on a.account_id = t.account_id
join customers c on c.customer_id = a.customer_id
where t.status = 'FLAGGED'
  and t.transaction_at >= now() - interval '90 days'
group by c.customer_id, c.first_name, c.last_name
order by rnk;
