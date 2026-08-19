-- ============================================================
-- BANKACILIK VERİTABANI ŞEMASI
-- Proje: Finance & Banking SQL Portfolio Project
-- Veritabanı: PostgreSQL 14+
-- ============================================================

DROP TABLE IF EXISTS loan_payments CASCADE;
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS cards CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS branches CASCADE;

-- ------------------------------------------------------------
-- 1. ŞUBELER (branches)
-- ------------------------------------------------------------
CREATE TABLE branches (
    branch_id       SERIAL PRIMARY KEY,
    branch_name     VARCHAR(100) NOT NULL,
    city            VARCHAR(50) NOT NULL,
    opened_date     DATE NOT NULL,
    manager_name    VARCHAR(100)
);

-- ------------------------------------------------------------
-- 2. MÜŞTERİLER (customers)
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    phone           VARCHAR(20),
    date_of_birth   DATE NOT NULL,
    join_date       DATE NOT NULL,
    city            VARCHAR(50),
    credit_score    INT CHECK (credit_score BETWEEN 300 AND 850)
);

-- ------------------------------------------------------------
-- 3. ÇALIŞANLAR (employees)
-- ------------------------------------------------------------
CREATE TABLE employees (
    employee_id     SERIAL PRIMARY KEY,
    branch_id       INT NOT NULL REFERENCES branches(branch_id),
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    position        VARCHAR(50) NOT NULL,
    hire_date       DATE NOT NULL,
    salary          NUMERIC(10,2) CHECK (salary > 0)
);

-- ------------------------------------------------------------
-- 4. HESAPLAR (accounts)
-- ------------------------------------------------------------
CREATE TABLE accounts (
    account_id      SERIAL PRIMARY KEY,
    customer_id     INT NOT NULL REFERENCES customers(customer_id),
    branch_id       INT NOT NULL REFERENCES branches(branch_id),
    account_type    VARCHAR(20) NOT NULL CHECK (account_type IN ('CHECKING','SAVINGS','BUSINESS')),
    balance         NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    opened_date     DATE NOT NULL,
    status          VARCHAR(15) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','CLOSED','FROZEN'))
);

-- ------------------------------------------------------------
-- 5. İŞLEMLER (transactions)
-- ------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id      BIGSERIAL PRIMARY KEY,
    account_id          INT NOT NULL REFERENCES accounts(account_id),
    transaction_date    TIMESTAMP NOT NULL,
    transaction_type    VARCHAR(20) NOT NULL CHECK (transaction_type IN ('DEPOSIT','WITHDRAWAL','TRANSFER_IN','TRANSFER_OUT','FEE','INTEREST')),
    amount               NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    balance_after        NUMERIC(14,2) NOT NULL,
    description           VARCHAR(255)
);

-- ------------------------------------------------------------
-- 6. KARTLAR (cards)
-- ------------------------------------------------------------
CREATE TABLE cards (
    card_id         SERIAL PRIMARY KEY,
    account_id      INT NOT NULL REFERENCES accounts(account_id),
    card_type       VARCHAR(20) NOT NULL CHECK (card_type IN ('DEBIT','CREDIT')),
    issue_date      DATE NOT NULL,
    expiry_date     DATE NOT NULL,
    credit_limit    NUMERIC(12,2),
    status          VARCHAR(15) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','BLOCKED','EXPIRED'))
);

-- ------------------------------------------------------------
-- 7. KREDİLER (loans)
-- ------------------------------------------------------------
CREATE TABLE loans (
    loan_id             SERIAL PRIMARY KEY,
    customer_id         INT NOT NULL REFERENCES customers(customer_id),
    loan_type           VARCHAR(20) NOT NULL CHECK (loan_type IN ('PERSONAL','MORTGAGE','AUTO','BUSINESS')),
    principal_amount    NUMERIC(14,2) NOT NULL CHECK (principal_amount > 0),
    interest_rate       NUMERIC(5,2) NOT NULL CHECK (interest_rate >= 0),
    term_months         INT NOT NULL CHECK (term_months > 0),
    start_date          DATE NOT NULL,
    status               VARCHAR(15) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','PAID_OFF','DEFAULTED'))
);

-- ------------------------------------------------------------
-- 8. KREDİ ÖDEMELERİ (loan_payments)
-- ------------------------------------------------------------
CREATE TABLE loan_payments (
    payment_id      SERIAL PRIMARY KEY,
    loan_id         INT NOT NULL REFERENCES loans(loan_id),
    payment_date    DATE NOT NULL,
    amount_paid     NUMERIC(12,2) NOT NULL CHECK (amount_paid > 0),
    is_late         BOOLEAN NOT NULL DEFAULT FALSE
);

-- ------------------------------------------------------------
-- İNDEKSLER (performans için)
-- ------------------------------------------------------------
CREATE INDEX idx_accounts_customer   ON accounts(customer_id);
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_date    ON transactions(transaction_date);
CREATE INDEX idx_loans_customer       ON loans(customer_id);
CREATE INDEX idx_loan_payments_loan   ON loan_payments(loan_id);
