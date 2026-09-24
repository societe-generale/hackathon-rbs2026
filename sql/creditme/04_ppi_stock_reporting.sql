-- PPI stock reporting model.
-- The source dictionary does not document joins between DLANC, DPAY, DSTAT and
-- TFONC, so this table is an explicit integration boundary for the daily feed.
BEGIN;

CREATE TABLE IF NOT EXISTS creditme.loan_stock_snapshot (
    snapshot_date date NOT NULL,
    dossier_key text NOT NULL,
    nosoc char(5) NOT NULL DEFAULT '00100',
    cdselect5 char(5) NOT NULL,
    cddevise12 char(3) NOT NULL,
    crdu22 numeric(18,2) NOT NULL CHECK (crdu22 >= 0),
    cdsitdos22 char(1) NOT NULL,
    cdmdreg14 char(1),
    tyblk21 char(2),
    stadoss_position_22 char(1),
    source_file text,
    loaded_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (snapshot_date, dossier_key),
    CHECK (nosoc = '00100'),
    CHECK (cdselect5 IN ('00001', '00002', '00003')),
    CHECK (cddevise12 = upper(cddevise12)),
    CHECK (cdsitdos22 IN ('1', '2', '3', '4', '5')),
    CHECK (tyblk21 IS NULL OR tyblk21 = '01'),
    CHECK (stadoss_position_22 IS NULL OR stadoss_position_22 IN ('O', 'N', ' '))
);

CREATE INDEX IF NOT EXISTS loan_stock_snapshot_scope_idx
    ON creditme.loan_stock_snapshot
       (snapshot_date, cdselect5, cddevise12, cdsitdos22);

CREATE OR REPLACE VIEW creditme.ppi_current_stock AS
SELECT
    snapshot_date,
    dossier_key,
    crdu22 AS outstanding_amount,
    cddevise12 AS currency_code,
    (cdmdreg14 = '2') AS is_sg_direct_debit,
    (cdmdreg14 IS DISTINCT FROM '2') AS is_external_direct_debit,
    (tyblk21 = '01' AND stadoss_position_22 = 'O') AS has_unpaid_installment
FROM creditme.loan_stock_snapshot
WHERE cdselect5 = '00001'
  AND cdsitdos22 IN ('1', '2');

CREATE OR REPLACE VIEW creditme.ppi_stock_summary AS
SELECT
    snapshot_date,
    currency_code,
    count(*) AS loan_count,
    sum(outstanding_amount) AS outstanding_amount,
    count(*) FILTER (WHERE is_external_direct_debit) AS external_debit_loan_count,
    coalesce(sum(outstanding_amount) FILTER
        (WHERE is_external_direct_debit), 0) AS external_debit_outstanding_amount,
    count(*) FILTER
        (WHERE is_external_direct_debit AND has_unpaid_installment)
        AS external_unpaid_loan_count,
    coalesce(sum(outstanding_amount) FILTER
        (WHERE is_external_direct_debit AND has_unpaid_installment), 0)
        AS external_unpaid_outstanding_amount
FROM creditme.ppi_current_stock
GROUP BY snapshot_date, currency_code;

COMMENT ON TABLE creditme.loan_stock_snapshot IS
    'Normalized daily integration boundary for DLANC, DPAY, DSTAT and TFONC fields.';
COMMENT ON COLUMN creditme.loan_stock_snapshot.cdmdreg14 IS
    'DPAY CDMDREG-14: 2 means SG account direct debit; other values mean external account.';
COMMENT ON COLUMN creditme.loan_stock_snapshot.stadoss_position_22 IS
    'DSTAT STADOSS-21 position 22: O means unpaid when TYBLK-21 is 01.';
COMMENT ON COLUMN creditme.loan_stock_snapshot.cdselect5 IS
    'Market: 00001 PPI/LISA, 00002 professional/corporate, 00003 credit lines.';
COMMENT ON COLUMN creditme.loan_stock_snapshot.crdu22 IS
    'TFONC CRDU-22: outstanding amount.';
COMMENT ON COLUMN creditme.loan_stock_snapshot.cdsitdos22 IS
    'TFONC CDSITDOS-22: 1 assembly, 2 repayment in progress, 3/4 blocked, 5 settled.';

COMMIT;

-- Main business answer, one row per currency:
-- SELECT * FROM creditme.ppi_stock_summary
-- ORDER BY snapshot_date DESC, currency_code;

