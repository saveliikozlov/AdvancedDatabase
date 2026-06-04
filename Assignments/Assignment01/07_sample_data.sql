insert into fraud_rules (rule_name, rule_type, threshold_value, is_active) values
    ('Large amount', 'LARGE_AMOUNT', 10000, true),
    ('High-risk country', 'HIGH_RISK_COUNTRY', 0, true),
    ('High velocity', 'VELOCITY', 5, true),
    ('Spending anomaly', 'AMOUNT_DEVIATION', 3, true),
    ('Dormant account waking', 'DORMANT_ACTIVITY', 30, false);

insert into customers (first_name, last_name, email, birth_date, country_code) values
    ('Anna', 'Kovalenko', 'anna.kovalenko@example.com', '1988-03-12', 'UA'),
    ('Petro', 'Shevchenko', 'petro.shev@example.com', '1979-11-04', 'UA'),
    ('Maria', 'Bondarenko', 'maria.b@example.com', '1995-07-22', 'UA'),
    ('Ivan', 'Lysenko', 'ivan.lysenko@example.com', '1971-01-30', 'UA'),
    ('Olena', 'Tkachenko', 'olena.t@example.com', '1991-09-15', 'PL'),
    ('Dmytro', 'Yatsenko', 'dmytro.y@example.com', '1985-04-19', 'DE'),
    ('Kateryna', 'Hrechko', 'kateryna.h@example.com', '2000-12-01', 'UA'),
    ('Serhii', 'Marchenko', 'serhii.m@example.com', '1968-06-09', 'UA'),
    ('Nadia', 'Pylypenko', 'nadia.p@example.com', '1993-02-25', 'CZ'),
    ('Bohdan', 'Hrytsenko', 'bohdan.h@example.com', '1982-08-08', 'UA');


insert into accounts (customer_id, account_number, currency, balance, status) values
    (1, 'UA213223130000026007233566001', 'UAH', 50000.00, 'ACTIVE'),
    (1, 'UA213223130000026007233566002', 'USD', 3500.00, 'ACTIVE'),
    (2, 'UA213223130000026007233566003', 'UAH', 12000.00, 'ACTIVE'),
    (3, 'UA213223130000026007233566004', 'UAH', 8000.00, 'ACTIVE'),
    (3, 'UA213223130000026007233566005', 'EUR', 1500.00, 'ACTIVE'),
    (4, 'UA213223130000026007233566006', 'UAH', 80000.00, 'ACTIVE'),
    (5, 'UA213223130000026007233566007', 'EUR', 9000.00, 'ACTIVE'),
    (6, 'UA213223130000026007233566008', 'EUR', 11000.00, 'ACTIVE'),
    (7, 'UA213223130000026007233566009', 'UAH', 25000.00, 'ACTIVE'),
    (8, 'UA213223130000026007233566010', 'UAH', 150000.00, 'ACTIVE'),
    (8, 'UA213223130000026007233566011', 'USD', 5000.00, 'FROZEN'),
    (9, 'UA213223130000026007233566012', 'EUR', 6500.00, 'ACTIVE'),
    (10, 'UA213223130000026007233566013', 'UAH', 30000.00, 'ACTIVE');


insert into cards (account_id, card_number_hash, card_type, status, expiration_date) values
    (1, encode(sha256('4111111111110001'::bytea), 'hex'), 'DEBIT', 'ACTIVE', '2028-12-31'),
    (1, encode(sha256('4111111111110002'::bytea), 'hex'), 'CREDIT', 'ACTIVE', '2027-06-30'),
    (2, encode(sha256('4111111111110003'::bytea), 'hex'), 'DEBIT', 'ACTIVE', '2026-09-30'),
    (3, encode(sha256('4111111111110004'::bytea), 'hex'), 'DEBIT', 'ACTIVE', '2028-01-31'),
    (4, encode(sha256('4111111111110005'::bytea), 'hex'), 'CREDIT', 'ACTIVE', '2029-04-30'),
    (5, encode(sha256('4111111111110006'::bytea), 'hex'), 'DEBIT', 'ACTIVE', '2027-11-30'),
    (6, encode(sha256('4111111111110007'::bytea), 'hex'), 'CREDIT', 'ACTIVE', '2028-08-31'),
    (7, encode(sha256('4111111111110008'::bytea), 'hex'), 'DEBIT', 'ACTIVE', '2026-12-31'),
    (8, encode(sha256('4111111111110009'::bytea), 'hex'), 'DEBIT', 'ACTIVE', '2028-05-31'),
    (9, encode(sha256('4111111111110010'::bytea), 'hex'), 'CREDIT', 'ACTIVE', '2027-02-28'),
    (10, encode(sha256('4111111111110011'::bytea), 'hex'), 'DEBIT', 'ACTIVE', '2029-10-31'),
    (12, encode(sha256('4111111111110012'::bytea), 'hex'), 'DEBIT', 'ACTIVE', '2028-03-31'),
    (13, encode(sha256('4111111111110013'::bytea), 'hex'), 'CREDIT', 'ACTIVE', '2027-07-31');


insert into transactions
    (account_id, card_id, amount, currency, merchant_category, merchant_country, transaction_at) values
    (1, 1, 120.00, 'UAH', 'GROCERY', 'UA', now() - interval '5 days'),
    (1, 1, 85.50, 'UAH', 'GROCERY', 'UA', now() - interval '5 days' + interval '2 hours'),
    (1, 2, 400.00, 'UAH', 'RESTAURANT', 'UA', now() - interval '4 days'),
    (2, 3, 35.00, 'USD', 'ECOMMERCE', 'US', now() - interval '4 days'),
    (3, 4, 220.00, 'UAH', 'FUEL', 'UA', now() - interval '3 days'),
    (4, 5, 18.00, 'UAH', 'TRANSPORT', 'UA', now() - interval '3 days'),
    (4, 5, 42.00, 'UAH', 'GROCERY', 'UA', now() - interval '3 days' + interval '1 hour'),
    (5, 6, 60.00, 'EUR', 'RESTAURANT', 'PL', now() - interval '2 days'),
    (6, 7, 150.00, 'EUR', 'ECOMMERCE', 'DE', now() - interval '2 days'),
    (7, 8, 210.00, 'UAH', 'GROCERY', 'UA', now() - interval '2 days'),
    (8, 9, 500.00, 'UAH', 'CLOTHING', 'UA', now() - interval '2 days'),
    (10, 11, 780.00, 'UAH', 'ELECTRONICS', 'UA', now() - interval '1 day'),
    (6, 7, 12500.00, 'EUR', 'JEWELRY', 'DE', now() - interval '1 day'),
    (2, 3, 1200.00, 'USD', 'ECOMMERCE', 'NG', now() - interval '36 hours'),
    (7, 8, 650.00, 'UAH', 'WIRE', 'IR', now() - interval '30 hours'),
    (1, 1, 100.00, 'UAH', 'ECOMMERCE', 'UA', now() - interval '6 hours'),
    (1, 1, 90.00, 'UAH', 'ECOMMERCE', 'UA', now() - interval '6 hours' + interval '10 minutes'),
    (1, 1, 180.00, 'UAH', 'ECOMMERCE', 'UA', now() - interval '6 hours' + interval '20 minutes'),
    (1, 1, 220.00, 'UAH', 'ECOMMERCE', 'UA', now() - interval '6 hours' + interval '30 minutes'),
    (1, 1, 310.00, 'UAH', 'ECOMMERCE', 'UA', now() - interval '6 hours' + interval '45 minutes'),
    (4, 5, 9000.00, 'UAH', 'JEWELRY', 'UA', now() - interval '2 hours'),
    (10, 11, 330.00, 'UAH', 'GROCERY', 'UA', now() - interval '30 minutes'),
    (2, 3, 12000.00, 'USD', 'WIRE', 'IR', now() - interval '1 hour');
