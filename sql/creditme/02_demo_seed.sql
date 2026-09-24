-- Demonstration data only: values are intentionally fictional.
BEGIN;

INSERT INTO creditme.raw_record_payload
    (record_code, record_key, payload, source_file)
VALUES
    ('ENR-DLANC', 'DEMO-SG-000001',
     'DEMO|ENR-DLANC|DEMO-SG-000001|FICTITIOUS', 'demo-seed')
ON CONFLICT DO NOTHING;

INSERT INTO creditme.dossier
    (dossier_key, source_payload_id, product_code, currency_code,
     nominal_amount, duration_months, proposal_date)
SELECT 'DEMO-SG-000001', payload_id, 'DEMO-HOME', 'EUR',
       250000.00, 240, DATE '2030-01-15'
FROM creditme.raw_record_payload
WHERE record_code = 'ENR-DLANC' AND record_key = 'DEMO-SG-000001'
ON CONFLICT (dossier_key) DO UPDATE SET
    source_payload_id = EXCLUDED.source_payload_id,
    product_code = EXCLUDED.product_code,
    currency_code = EXCLUDED.currency_code,
    nominal_amount = EXCLUDED.nominal_amount,
    duration_months = EXCLUDED.duration_months,
    proposal_date = EXCLUDED.proposal_date;

COMMIT;
