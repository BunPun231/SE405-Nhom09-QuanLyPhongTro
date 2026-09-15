-- Allow METERED services in the services charge_type constraint
ALTER TABLE services
    DROP CONSTRAINT IF EXISTS services_charge_type_check;

ALTER TABLE services
    ADD CONSTRAINT services_charge_type_check
    CHECK (charge_type IN ('FIXED', 'PER_PERSON', 'PER_INDEX', 'PER_QUANTITY', 'METERED'));