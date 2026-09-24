-- Synthetic but realistic-looking CreditMe/Lisa data.
-- No real customer, account, or personally identifiable information is used.
BEGIN;

WITH demo_rows(record_code, record_key, payload, source_file) AS (
    VALUES
        ('ENR-DLANC', 'DEMO-FR-000001', 'DLANC|DEMO-FR-000001|PRET-HABITAT|EUR|185000.00|240|2026-01-12', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000002', 'DLANC|DEMO-FR-000002|PRET-HABITAT|EUR|248500.00|300|2026-02-03', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000003', 'DLANC|DEMO-FR-000003|PRET-TRAVAUX|EUR|42000.00|120|2026-02-18', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000004', 'DLANC|DEMO-FR-000004|PRET-AUTO|EUR|27800.00|60|2026-03-06', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000005', 'DLANC|DEMO-FR-000005|PRET-HABITAT|EUR|312000.00|240|2026-03-21', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000006', 'DLANC|DEMO-FR-000006|PRET-ETUDES|EUR|18500.00|84|2026-04-09', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000007', 'DLANC|DEMO-FR-000007|PRET-RENOVATION|EUR|76500.00|180|2026-04-27', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000008', 'DLANC|DEMO-FR-000008|PRET-HABITAT|EUR|156000.00|180|2026-05-14', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000009', 'DLANC|DEMO-FR-000009|PRET-AUTO|EUR|36400.00|72|2026-06-02', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000010', 'DLANC|DEMO-FR-000010|PRET-TRAVAUX|EUR|59000.00|144|2026-06-19', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000011', 'DLANC|DEMO-FR-000011|PRET-HABITAT|EUR|425000.00|300|2026-07-07', 'synthetic-seed'),
        ('ENR-DLANC', 'DEMO-FR-000012', 'DLANC|DEMO-FR-000012|PRET-ETUDES|EUR|12000.00|60|2026-07-23', 'synthetic-seed')
)
INSERT INTO creditme.raw_record_payload (record_code, record_key, payload, source_file)
SELECT record_code, record_key, payload, source_file
FROM demo_rows
ON CONFLICT DO NOTHING;

WITH dossier_rows(dossier_key, product_code, currency_code, nominal_amount,
                  duration_months, proposal_date) AS (
    VALUES
        ('DEMO-FR-000001', 'PRET-HABITAT', 'EUR', 185000.00, 240, DATE '2026-01-12'),
        ('DEMO-FR-000002', 'PRET-HABITAT', 'EUR', 248500.00, 300, DATE '2026-02-03'),
        ('DEMO-FR-000003', 'PRET-TRAVAUX', 'EUR',  42000.00, 120, DATE '2026-02-18'),
        ('DEMO-FR-000004', 'PRET-AUTO',    'EUR',  27800.00,  60, DATE '2026-03-06'),
        ('DEMO-FR-000005', 'PRET-HABITAT', 'EUR', 312000.00, 240, DATE '2026-03-21'),
        ('DEMO-FR-000006', 'PRET-ETUDES',  'EUR',  18500.00,  84, DATE '2026-04-09'),
        ('DEMO-FR-000007', 'PRET-RENOVATION', 'EUR', 76500.00, 180, DATE '2026-04-27'),
        ('DEMO-FR-000008', 'PRET-HABITAT', 'EUR', 156000.00, 180, DATE '2026-05-14'),
        ('DEMO-FR-000009', 'PRET-AUTO',    'EUR',  36400.00,  72, DATE '2026-06-02'),
        ('DEMO-FR-000010', 'PRET-TRAVAUX', 'EUR',  59000.00, 144, DATE '2026-06-19'),
        ('DEMO-FR-000011', 'PRET-HABITAT', 'EUR', 425000.00, 300, DATE '2026-07-07'),
        ('DEMO-FR-000012', 'PRET-ETUDES',  'EUR',  12000.00,  60, DATE '2026-07-23')
)
INSERT INTO creditme.dossier
    (dossier_key, source_payload_id, product_code, currency_code,
     nominal_amount, duration_months, proposal_date)
SELECT d.dossier_key, p.payload_id, d.product_code, d.currency_code,
       d.nominal_amount, d.duration_months, d.proposal_date
FROM dossier_rows d
JOIN creditme.raw_record_payload p
  ON p.record_code = 'ENR-DLANC'
 AND p.record_key = d.dossier_key
ON CONFLICT (dossier_key) DO UPDATE SET
    source_payload_id = EXCLUDED.source_payload_id,
    product_code = EXCLUDED.product_code,
    currency_code = EXCLUDED.currency_code,
    nominal_amount = EXCLUDED.nominal_amount,
    duration_months = EXCLUDED.duration_months,
    proposal_date = EXCLUDED.proposal_date;

-- Additional raw records demonstrate that the catalog can receive record types
-- that are not projected into a relational business table yet.
WITH raw_rows(record_code, record_key, payload) AS (
    VALUES
        ('ENR-DCOMM', 'DEMO-FR-000001', 'DCOMM|DEMO-FR-000001|ACQUISITION|RESIDENTIAL|EUR|185000.00'),
        ('ENR-DCOMM', 'DEMO-FR-000002', 'DCOMM|DEMO-FR-000002|ACQUISITION|RESIDENTIAL|EUR|248500.00'),
        ('ENR-DCOMM', 'DEMO-FR-000003', 'DCOMM|DEMO-FR-000003|RENOVATION|RESIDENTIAL|EUR|42000.00'),
        ('ENR-DCOMM', 'DEMO-FR-000004', 'DCOMM|DEMO-FR-000004|VEHICLE|PERSONAL|EUR|27800.00'),
        ('ENR-DGEN',  'DEMO-FR-000001', 'DGEN|DEMO-FR-000001|STANDARD|ACTIVE|EUR'),
        ('ENR-DGEN',  'DEMO-FR-000005', 'DGEN|DEMO-FR-000005|STANDARD|ACTIVE|EUR'),
        ('ENR-DGEN',  'DEMO-FR-000011', 'DGEN|DEMO-FR-000011|STANDARD|PENDING|EUR')
)
INSERT INTO creditme.raw_record_payload
    (record_code, record_key, payload, source_file)
SELECT record_code, record_key, payload, 'synthetic-seed'
FROM raw_rows
ON CONFLICT DO NOTHING;

COMMIT;
