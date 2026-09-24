-- Mock data and query for the CreditMe/Lisa stock use case.
-- All dossier identifiers and amounts below are synthetic.
-- Run after 01_schema.sql. The script is idempotent.
BEGIN;

CREATE TABLE IF NOT EXISTS creditme.loan_dossier (
    dossier_key text PRIMARY KEY,
    company_code char(5) NOT NULL,
    market_code char(5) NOT NULL,
    currency_code char(3) NOT NULL,
    source_record_code text NOT NULL DEFAULT 'ENR-DLANC',
    CONSTRAINT loan_dossier_currency_ck CHECK (currency_code IN ('EUR', 'CHF'))
);

CREATE TABLE IF NOT EXISTS creditme.loan_payment (
    dossier_key text PRIMARY KEY REFERENCES creditme.loan_dossier(dossier_key) ON DELETE CASCADE,
    payment_mode char(1) NOT NULL,
    source_record_code text NOT NULL DEFAULT 'ENR-DPAY'
);

CREATE TABLE IF NOT EXISTS creditme.loan_functional_status (
    dossier_key text PRIMARY KEY REFERENCES creditme.loan_dossier(dossier_key) ON DELETE CASCADE,
    loan_status char(1) NOT NULL,
    capital_remaining_due numeric(18,2) NOT NULL CHECK (capital_remaining_due >= 0),
    source_record_code text NOT NULL DEFAULT 'ENR-TFONC',
    CONSTRAINT loan_functional_status_ck CHECK (loan_status IN ('1', '2', '3', '4', '5'))
);

CREATE TABLE IF NOT EXISTS creditme.loan_stat (
    dossier_key text PRIMARY KEY REFERENCES creditme.loan_dossier(dossier_key) ON DELETE CASCADE,
    block_type char(2) NOT NULL,
    status_area text NOT NULL,
    source_record_code text NOT NULL DEFAULT 'ENR-DSTAT',
    CONSTRAINT loan_stat_block_type_ck CHECK (length(block_type) = 2)
);

INSERT INTO creditme.loan_dossier
    (dossier_key, company_code, market_code, currency_code)
VALUES
    ('MOCK-PPI-EUR-001', '00100', '00001', 'EUR'),
    ('MOCK-PPI-EUR-002', '00100', '00001', 'EUR'),
    ('MOCK-PPI-EUR-003', '00100', '00001', 'EUR'),
    ('MOCK-PPI-EUR-004', '00100', '00001', 'EUR'),
    ('MOCK-PPI-CHF-001', '00100', '00001', 'CHF'),
    ('MOCK-PPI-CHF-002', '00100', '00001', 'CHF'),
    ('MOCK-PRO-001',     '00100', '00002', 'EUR'),
    ('MOCK-SOLD-001',    '00100', '00001', 'EUR')
ON CONFLICT (dossier_key) DO UPDATE SET
    company_code = EXCLUDED.company_code,
    market_code = EXCLUDED.market_code,
    currency_code = EXCLUDED.currency_code;

INSERT INTO creditme.loan_payment (dossier_key, payment_mode)
VALUES
    ('MOCK-PPI-EUR-001', '2'),
    ('MOCK-PPI-EUR-002', '7'),
    ('MOCK-PPI-EUR-003', '7'),
    ('MOCK-PPI-EUR-004', '2'),
    ('MOCK-PPI-CHF-001', '7'),
    ('MOCK-PPI-CHF-002', '2'),
    ('MOCK-PRO-001',     '7'),
    ('MOCK-SOLD-001',    '7')
ON CONFLICT (dossier_key) DO UPDATE SET
    payment_mode = EXCLUDED.payment_mode;

INSERT INTO creditme.loan_functional_status
    (dossier_key, loan_status, capital_remaining_due)
VALUES
    ('MOCK-PPI-EUR-001', '2', 185000.00),
    ('MOCK-PPI-EUR-002', '2', 248500.00),
    ('MOCK-PPI-EUR-003', '1',  42000.00),
    ('MOCK-PPI-EUR-004', '2',  76500.00),
    ('MOCK-PPI-CHF-001', '2', 132000.00),
    ('MOCK-PPI-CHF-002', '2',  98000.00),
    ('MOCK-PRO-001',     '2', 410000.00),
    ('MOCK-SOLD-001',    '5',      0.00)
ON CONFLICT (dossier_key) DO UPDATE SET
    loan_status = EXCLUDED.loan_status,
    capital_remaining_due = EXCLUDED.capital_remaining_due;

INSERT INTO creditme.loan_stat (dossier_key, block_type, status_area)
VALUES
    ('MOCK-PPI-EUR-001', '01', '                    '),
    ('MOCK-PPI-EUR-002', '01', '                     O'),
    ('MOCK-PPI-EUR-003', '01', '                    '),
    ('MOCK-PPI-EUR-004', '01', '                     O'),
    ('MOCK-PPI-CHF-001', '01', '                    '),
    ('MOCK-PPI-CHF-002', '01', '                     O'),
    ('MOCK-PRO-001',     '01', '                     O'),
    ('MOCK-SOLD-001',    '01', '                     O')
ON CONFLICT (dossier_key) DO UPDATE SET
    block_type = EXCLUDED.block_type,
    status_area = EXCLUDED.status_area;

CREATE OR REPLACE VIEW creditme.v_ppi_stock AS
SELECT
    d.currency_code AS devise,
    CASE WHEN p.payment_mode = '2'
         THEN 'PRELEVEMENT_SG'
         ELSE 'PRELEVEMENT_EXTERNE'
    END AS type_prelevement,
    COUNT(*) AS nombre_prets,
    SUM(s.capital_remaining_due) AS stock_encours,
    COUNT(*) FILTER (
        WHERE p.payment_mode <> '2'
          AND st.block_type = '01'
          AND substring(st.status_area FROM 22 FOR 1) = 'O'
    ) AS nombre_impayes_externe,
    COALESCE(SUM(s.capital_remaining_due) FILTER (
        WHERE p.payment_mode <> '2'
          AND st.block_type = '01'
          AND substring(st.status_area FROM 22 FOR 1) = 'O'
    ), 0.00) AS stock_impayes_externe
FROM creditme.loan_dossier d
JOIN creditme.loan_payment p ON p.dossier_key = d.dossier_key
JOIN creditme.loan_functional_status s ON s.dossier_key = d.dossier_key
LEFT JOIN creditme.loan_stat st ON st.dossier_key = d.dossier_key
WHERE d.company_code = '00100'
  AND d.market_code = '00001'
  AND d.currency_code IN ('EUR', 'CHF')
  AND s.loan_status IN ('1', '2')
GROUP BY d.currency_code, type_prelevement;

COMMIT;

-- Expected result for the mock data:
-- EUR / PRELEVEMENT_SG      : 2 loans, 261500.00 outstanding, 0 unpaid
-- EUR / PRELEVEMENT_EXTERNE : 2 loans, 290500.00 outstanding, 2 unpaid
-- CHF / PRELEVEMENT_SG      : 1 loan,  98000.00 outstanding, 0 unpaid
-- CHF / PRELEVEMENT_EXTERNE : 1 loan, 132000.00 outstanding, 1 unpaid
SELECT *
FROM creditme.v_ppi_stock
ORDER BY devise, type_prelevement;
