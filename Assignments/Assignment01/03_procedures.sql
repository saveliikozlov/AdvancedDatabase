create or replace procedure create_fraud_alert(
    p_transaction_id bigint,
    p_reason text,
    p_risk_score int,
    p_rule_id bigint default null
)
language plpgsql
as $$
begin
    insert into fraud_alerts (transaction_id, rule_id, reason, risk_score, alert_status)
    values (p_transaction_id, p_rule_id, p_reason, p_risk_score, 'OPEN');

    update transactions
    set status = 'FLAGGED'
    where transaction_id = p_transaction_id
      and status <> 'FLAGGED';
end;
$$;




create or replace procedure freeze_account(p_account_id bigint)
language plpgsql
as $$
begin
    update accounts set status = 'FROZEN'
    where account_id = p_account_id;

    if not found then
        raise exception 'account % does not exist', p_account_id
            using errcode = 'P0002';
    end if;

    update cards set status = 'BLOCKED'
    where account_id = p_account_id
      and status = 'ACTIVE';
end;
$$;




create or replace procedure process_transaction(p_transaction_id bigint)
language plpgsql
as $$
declare
    v_status text;
    v_score int;
    v_amount numeric(18,2);
    v_account_id bigint;
    v_balance numeric(18,2);
begin
    select status, risk_score, amount, account_id
      into v_status, v_score, v_amount, v_account_id
    from transactions
    where transaction_id = p_transaction_id;

    if not found then
        raise exception 'transaction % not found', p_transaction_id;
    end if;
    if v_status <> 'PENDING' then
        raise notice 'transaction % is not PENDING (status=%); skipping',
            p_transaction_id, v_status;
        return;
    end if;

    select balance into v_balance
    from accounts
    where account_id = v_account_id;

    if v_score >= 70 then
        call create_fraud_alert(p_transaction_id,
            format('auto-flagged by process_transaction: risk %s', v_score), v_score);
    elsif v_balance >= v_amount then
        update transactions set status = 'APPROVED'
        where transaction_id = p_transaction_id;
    else
        update transactions set status = 'DECLINED'
        where transaction_id = p_transaction_id;
    end if;
end;
$$;



create or replace procedure approve_pending_transactions(p_max_risk int default 40)
language plpgsql
as $$
declare
    r record;
    v_balance numeric(18, 2);
begin
    for r in
        select t.transaction_id, t.account_id, t.amount
        from transactions t
        where t.status = 'PENDING' and t.risk_score <= p_max_risk
        order by t.account_id, t.transaction_at, t.transaction_id
    loop
        select balance into v_balance
        from accounts
        where account_id = r.account_id;

        if v_balance >= r.amount then
            update transactions
            set status = 'APPROVED'
            where transaction_id = r.transaction_id;
        end if;
    end loop;
end;
$$;



create or replace procedure refresh_fraud_dashboard()
language plpgsql
as $$
begin
    refresh materialized view concurrently mv_daily_fraud_summary;
end;
$$;
