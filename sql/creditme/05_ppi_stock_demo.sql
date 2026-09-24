-- Fictional normalized rows used to validate the PPI stock report.
BEGIN;

INSERT INTO creditme.loan_stock_snapshot
    (snapshot_date, dossier_key, cdselect5, cddevise12, crdu22, cdsitdos22,
     cdmdreg14, tyblk21, stadoss_position_22, source_file)
VALUES
    ('2026-09-01', 'PPI-DEMO-0001', '00001', 'EUR', 180000.00, '2', '2', '01', 'N', 'ppi-demo'),
    ('2026-09-01', 'PPI-DEMO-0002', '00001', 'EUR', 235500.00, '2', '1', '01', 'O', 'ppi-demo'),
    ('2026-09-01', 'PPI-DEMO-0003', '00001', 'EUR',  64000.00, '1', '3', '01', 'N', 'ppi-demo'),
    ('2026-09-01', 'PPI-DEMO-0004', '00001', 'CHF', 125000.00, '2', '2', '01', 'N', 'ppi-demo'),
    ('2026-09-01', 'PPI-DEMO-0005', '00001', 'CHF',  98500.00, '2', '1', '01', 'O', 'ppi-demo'),
    ('2026-09-01', 'PPI-DEMO-0006', '00001', 'EUR',  42000.00, '5', '1', '01', 'N', 'ppi-demo'),
    ('2026-09-01', 'PPI-DEMO-0007', '00002', 'EUR', 310000.00, '2', '1', '01', 'N', 'ppi-demo'),
    ('2026-09-01', 'PPI-DEMO-0008', '00001', 'EUR',  55000.00, '3', '1', '01', 'O', 'ppi-demo')
ON CONFLICT (snapshot_date, dossier_key) DO UPDATE SET
    cdselect5 = EXCLUDED.cdselect5,
    cddevise12 = EXCLUDED.cddevise12,
    crdu22 = EXCLUDED.crdu22,
    cdsitdos22 = EXCLUDED.cdsitdos22,
    cdmdreg14 = EXCLUDED.cdmdreg14,
    tyblk21 = EXCLUDED.tyblk21,
    stadoss_position_22 = EXCLUDED.stadoss_position_22,
    source_file = EXCLUDED.source_file;

COMMIT;

SELECT *
FROM creditme.ppi_stock_summary
WHERE snapshot_date = '2026-09-01'
ORDER BY currency_code;
