drop materialized view if exists mv_daily_fraud_summary;

create materialized view mv_daily_fraud_summary as
with daily as (
    select
        t.transaction_at::date as txn_date,
        count(*) as total_transactions,
        sum(t.amount) as total_amount,
        count(*) filter (where t.status = 'FLAGGED') as flagged_transactions,
        sum(t.amount) filter (where t.status = 'FLAGGED') as suspicious_amount,
        round(avg(t.risk_score)::numeric, 2) as avg_risk_score
    from transactions t
    group by t.transaction_at::date
),
alerts as (
    select
        fa.created_at::date as alert_date,
        count(*) as total_alerts
    from fraud_alerts fa
    group by fa.created_at::date
),
top_risky as (
    select
        txn_date,
        string_agg(customer_label, ', ' order by rnk) as top_risky_customers
    from (
        select
            t.transaction_at::date as txn_date,
            c.first_name || ' ' || c.last_name as customer_label,
            dense_rank() over (
                partition by t.transaction_at::date
                order by sum(t.amount * t.risk_score) desc
            ) as rnk
        from transactions t
        join accounts a on a.account_id = t.account_id
        join customers c on c.customer_id = a.customer_id
        where t.risk_score > 0
        group by t.transaction_at::date, c.customer_id, c.first_name, c.last_name
    ) ranked
    where rnk <= 3
    group by txn_date
)
select
    d.txn_date,
    d.total_transactions,
    d.total_amount,
    d.flagged_transactions,
    coalesce(d.suspicious_amount, 0) as suspicious_amount,
    d.avg_risk_score,
    coalesce(tr.top_risky_customers, '-') as top_risky_customers,
    coalesce(al.total_alerts, 0) as total_fraud_alerts
from daily d
left join top_risky tr on tr.txn_date = d.txn_date
left join alerts al on al.alert_date = d.txn_date
order by d.txn_date desc;

create unique index ux_mv_daily_fraud_summary_date
    on mv_daily_fraud_summary (txn_date);