-- Merge duplicate Cristiano Ronaldo records that share the same person but different name forms.

UPDATE players
SET identity_key = 'ronaldo|c'
WHERE normalized_name LIKE '%ronaldo%'
  AND normalized_name LIKE '%cristiano%'
  AND (identity_key IS NULL OR identity_key <> 'ronaldo|c');
