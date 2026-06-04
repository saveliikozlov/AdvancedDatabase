create or replace function mask_card_number(p_card_number text)
returns text
language sql
immutable
as $$
    select case
        when p_card_number is null or length(p_card_number) < 8 then '****'
        else substr(p_card_number, 1, 4)
          || repeat('*', length(p_card_number) - 8)
          || substr(p_card_number, length(p_card_number) - 3)
    end;
$$;




create or replace function get_customer_age(p_customer_id bigint)
returns int
language sql
stable
as $$
    select extract(year from age(current_date, birth_date))::int
    from customers
    where customer_id = p_customer_id;
$$;




create or replace function is_high_risk_country(p_country_code char(2))
returns boolean
language sql
immutable
as $$
    select p_country_code in ('NG', 'KP', 'IR', 'SY', 'AF', 'YE', 'RU');
$$;




create or replace function calculate_customer_daily_volume(
    p_customer_id bigint,
    p_target_date date
)
returns numeric
language sql
stable
as $$
    select coalesce(sum(t.amount), 0)
    from transactions t
    join accounts a on a.account_id = t.account_id
    where a.customer_id = p_customer_id
      and t.transaction_at::date = p_target_date
      and t.status <> 'DECLINED';
$$;



create or replace function calculate_transaction_risk_score(p_transaction_id bigint)
returns int
language sql
stable
as $$
    select least(
        case when t.amount >= 10000 then 40
             when t.amount >= 5000 then 20
             else 0 end
      + case when is_high_risk_country(t.merchant_country) then 30 else 0 end
      + case when (
            select count(*)
            from transactions prev
            join accounts pa on pa.account_id = prev.account_id
            where pa.customer_id = a.customer_id
              and prev.transaction_id <> t.transaction_id
              and prev.transaction_at > t.transaction_at - interval '1 hour'
              and prev.transaction_at <= t.transaction_at
        ) >= 3 then 30 else 0 end,
        100)
    from transactions t
    join accounts a on a.account_id = t.account_id
    where t.transaction_id = p_transaction_id;
$$;
