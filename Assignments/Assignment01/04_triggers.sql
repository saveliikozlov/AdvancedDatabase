create or replace function trg_transactions_fn()
returns trigger
language plpgsql
as $$
declare
    v_score int;
begin
    if tg_op = 'INSERT' then
        insert into transaction_status_history (transaction_id, old_status, new_status)
        values (new.transaction_id, null, new.status);

        v_score := calculate_transaction_risk_score(new.transaction_id);

        update transactions
        set risk_score = v_score
        where transaction_id = new.transaction_id;

        if v_score >= 70 then
            call create_fraud_alert(
                new.transaction_id,
                format('auto-flagged: risk score %s', v_score),
                v_score
            );
        end if;

    elsif tg_op = 'UPDATE' then
        if new.status is distinct from old.status then
            insert into transaction_status_history (transaction_id, old_status, new_status)
            values (new.transaction_id, old.status, new.status);

            if new.status = 'APPROVED' and old.status is distinct from 'APPROVED' then
                update accounts
                set balance = balance - new.amount
                where account_id = new.account_id;

            elsif old.status = 'APPROVED' and new.status = 'DECLINED' then
                update accounts
                set balance = balance + old.amount
                where account_id = old.account_id;
            end if;
        end if;
    end if;

    return null;
end;
$$;

drop trigger if exists trg_transactions_after_insert on transactions;
drop trigger if exists trg_transactions_balance on transactions;
drop trigger if exists trg_transactions_status_history on transactions;
drop trigger if exists trg_transactions on transactions;
create trigger trg_transactions
after insert or update on transactions
for each row
execute function trg_transactions_fn();

create or replace function trg_audit_log_fn()
returns trigger
language plpgsql
as $$
declare
    v_customer_id bigint;
    v_old jsonb;
    v_new jsonb;
begin
    if tg_table_name = 'customers' then
        v_customer_id := coalesce(new.customer_id, old.customer_id);

    elsif tg_table_name = 'accounts' then
        v_customer_id := coalesce(new.customer_id, old.customer_id);

    elsif tg_table_name = 'transactions' then
        select a.customer_id
        into v_customer_id
        from accounts a
        where a.account_id = coalesce(new.account_id, old.account_id);
    end if;

    if tg_op <> 'INSERT' then v_old := to_jsonb(old); end if;
    if tg_op <> 'DELETE' then v_new := to_jsonb(new); end if;

    insert into audit_log (customer_id, table_name, operation, old_value, new_value)
    values (v_customer_id, tg_table_name, tg_op, v_old, v_new);

    if tg_op = 'DELETE' then
        return old;
    end if;
    return new;
end;
$$;

drop trigger if exists trg_audit_customers on customers;
create trigger trg_audit_customers
after insert or update or delete on customers
for each row execute function trg_audit_log_fn();

drop trigger if exists trg_audit_accounts on accounts;
create trigger trg_audit_accounts
after insert or update or delete on accounts
for each row execute function trg_audit_log_fn();

drop trigger if exists trg_audit_transactions on transactions;
create trigger trg_audit_transactions
after insert or update or delete on transactions
for each row execute function trg_audit_log_fn();


create or replace function trg_customers_block_delete_fn()
returns trigger
language plpgsql
as $$
begin
    if exists (
        select 1 from accounts
        where customer_id = old.customer_id
          and status = 'ACTIVE'
    ) then
        raise exception 'cannot delete customer % -- has active accounts', old.customer_id
            using errcode = '23503';
    end if;
    return old;
end;
$$;

drop trigger if exists trg_customers_block_delete on customers;
create trigger trg_customers_block_delete
before delete on customers
for each row
execute function trg_customers_block_delete_fn();
