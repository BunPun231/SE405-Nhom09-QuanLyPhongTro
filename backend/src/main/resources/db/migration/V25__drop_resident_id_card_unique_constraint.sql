-- V25: Drop global unique constraint on id_card_number in resident_profiles
ALTER TABLE resident_profiles DROP CONSTRAINT IF EXISTS resident_profiles_id_card_number_key;
