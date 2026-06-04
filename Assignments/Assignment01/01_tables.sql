drop table if exists audit_log cascade;
drop table if exists fraud_alerts cascade;
drop table if exists fraud_rules cascade;
drop table if exists transaction_status_history cascade;
drop table if exists transactions cascade;
drop table if exists cards cascade;
drop table if exists accounts cascade;
drop table if exists customers cascade;

create table customers (
    customer_id bigserial primary key,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    email varchar(255) not null,
    birth_date date not null check (birth_date < current_date),
    country_code char(2) not null,
    created_at timestamptz not null default now(),
    is_active boolean not null default true,
    constraint uq_customers_email unique (email),
    constraint chk_customer_country check (country_code ~ '^[A-Z]{2}$')
);

create table accounts (
    account_id bigserial primary key,
    customer_id bigint not null,
    account_number varchar(34) not null,
    currency char(3) not null check (currency in ('UAH','USD','EUR')),
    balance numeric(18,2) not null default 0 check (balance >= 0),
    status varchar(20) not null default 'ACTIVE' check (status in ('ACTIVE','FROZEN','CLOSED')),
    opened_at timestamptz not null default now(),
    constraint fk_accounts_customer foreign key (customer_id) references customers(customer_id),
    constraint uq_accounts_number unique (account_number),
    constraint chk_account_number_format check (length(account_number) >= 8)
);

create table cards (
    card_id bigserial primary key,
    account_id bigint not null,
    card_number_hash char(64) not null,
    card_type varchar(20) not null check (card_type in ('DEBIT','CREDIT','PREPAID')),
    status varchar(20) not null default 'ACTIVE' check (status in ('ACTIVE','BLOCKED','EXPIRED')),
    expiration_date date not null,
    constraint fk_cards_account foreign key (account_id) references accounts(account_id),
    constraint uq_cards_hash unique (card_number_hash)
);

create table transactions (
    transaction_id bigserial primary key,
    account_id bigint not null,
    card_id bigint,
    amount numeric(18,2) not null check (amount > 0),
    currency char(3) not null check (currency in ('UAH','USD','EUR')),
    merchant_category varchar(50),
    merchant_country char(2),
    status varchar(20) not null default 'PENDING' check (status in ('PENDING','APPROVED','DECLINED','FLAGGED')),
    risk_score int not null default 0 check (risk_score between 0 and 100),
    transaction_at timestamptz not null,
    created_at timestamptz not null default now(),
    constraint fk_transactions_account foreign key (account_id) references accounts(account_id),
    constraint fk_transactions_card foreign key (card_id) references cards(card_id)
);

create table transaction_status_history (
    history_id bigserial primary key,
    transaction_id bigint not null,
    old_status varchar(20),
    new_status varchar(20) not null,
    changed_at timestamptz not null default now(),
    changed_by varchar(100) not null default current_user,
    constraint fk_tsh_transaction foreign key (transaction_id) references transactions(transaction_id)
        on delete cascade
);

create table fraud_rules (
    rule_id bigserial primary key,
    rule_name varchar(100) not null,
    rule_type varchar(50) not null,
    threshold_value int not null,
    is_active boolean not null default true,
    constraint uq_fraud_rules_name unique (rule_name)
);

create table fraud_alerts (
    alert_id bigserial primary key,
    transaction_id bigint not null,
    rule_id bigint,
    reason text not null,
    risk_score int not null check (risk_score between 0 and 100),
    alert_status varchar(20) not null default 'OPEN' check (alert_status in ('OPEN','INVESTIGATING','RESOLVED','DISMISSED')),
    created_at timestamptz not null default now(),
    constraint fk_fa_transaction foreign key (transaction_id) references transactions(transaction_id)
        on delete cascade,
    constraint fk_fa_rule foreign key (rule_id) references fraud_rules(rule_id)
        on delete set null
);

create table audit_log (
    audit_id bigserial primary key,
    customer_id bigint,
    table_name varchar(63) not null,
    operation varchar(10) not null check (operation in ('INSERT','UPDATE','DELETE')),
    old_value jsonb,
    new_value jsonb,
    changed_at timestamptz not null default now(),
    constraint fk_audit_customer foreign key (customer_id) references customers(customer_id)
        on delete set null
);

create index ix_accounts_customer on accounts (customer_id);
create index ix_transactions_account_date on transactions (account_id, transaction_at desc);
create index ix_fa_transaction on fraud_alerts (transaction_id);
create index ix_transactions_open on transactions (status)
    where status in ('PENDING', 'FLAGGED');
