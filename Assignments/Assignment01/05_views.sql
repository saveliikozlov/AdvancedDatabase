create or replace view vw_customer_accounts as
select
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.email,
    c.country_code,
    c.is_active as customer_active,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance,
    a.status as account_status,
    a.opened_at
from customers c
left join accounts a on a.customer_id = c.customer_id;


create or replace view vw_recent_transactions as
select
    t.transaction_id,
    t.transaction_at,
    t.amount,
    t.currency,
    t.status,
    t.risk_score,
    t.merchant_category,
    t.merchant_country,
    a.account_number,
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    mask_card_number(crd.card_number_hash) as card_masked
from transactions t
join accounts a on a.account_id = t.account_id
join customers c on c.customer_id = a.customer_id
left join cards crd on crd.card_id = t.card_id
where t.transaction_at >= now() - interval '7 days';


create or replace view vw_flagged_transactions as
select
    t.transaction_id,
    t.transaction_at,
    t.amount,
    t.currency,
    t.risk_score,
    t.merchant_country,
    a.account_number,
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    fa.alert_id,
    fa.reason as alert_reason,
    fa.alert_status
from transactions t
join accounts a on a.account_id = t.account_id
join customers c on c.customer_id = a.customer_id
left join fraud_alerts fa on fa.transaction_id = t.transaction_id
where t.status = 'FLAGGED';

create or replace view vw_customer_risk_profile as
with txn_stats as (
    select
        a.customer_id,
        count(t.*) as total_txns_90d,
        coalesce(sum(t.amount) filter (where t.status = 'APPROVED'), 0) as approved_volume_90d,
        coalesce(avg(t.risk_score), 0) as avg_risk_score_90d,
        count(*) filter (where t.status = 'FLAGGED') as flagged_count_90d
    from accounts a
    left join transactions t
           on t.account_id = a.account_id
          and t.transaction_at >= now() - interval '90 days'
    group by a.customer_id
)
select
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.country_code,
    get_customer_age(c.customer_id) as age,
    coalesce(ts.total_txns_90d, 0) as total_txns_90d,
    coalesce(ts.approved_volume_90d, 0) as approved_volume_90d,
    round(coalesce(ts.avg_risk_score_90d, 0), 1) as avg_risk_score_90d,
    coalesce(ts.flagged_count_90d, 0) as flagged_count_90d,
    (select count(*)
       from fraud_alerts fa
       join transactions t on t.transaction_id = fa.transaction_id
       join accounts a on a.account_id = t.account_id
      where a.customer_id = c.customer_id
        and fa.alert_status = 'OPEN') as open_alerts,
    case
        when coalesce(ts.avg_risk_score_90d, 0) >= 60 then 'HIGH'
        when coalesce(ts.avg_risk_score_90d, 0) >= 30 then 'MEDIUM'
        else 'LOW'
    end as risk_tier
from customers c
left join txn_stats ts on ts.customer_id = c.customer_id;
