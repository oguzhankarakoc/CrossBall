-- Unify identity_key for Ibrahimović / dotted-initial variants (e.g. Z.Ibrahimovic vs Zlatan Ibrahimovic).
-- Run `python -m pipeline dedupe-players` after applying to merge duplicate rows in DB.

UPDATE players
SET identity_key = 'ibrahimovic|z'
WHERE (
    normalized_name LIKE 'z %ibrahimovic%'
    OR normalized_name LIKE 'zlatan%ibrahimovic%'
    OR normalized_name = 'zibrahimovic'
    OR normalized_name ~ '^z\.?ibrahimovic'
  )
  AND (identity_key IS NULL OR identity_key <> 'ibrahimovic|z');

-- Re-apply Ronaldo cluster (idempotent).
UPDATE players
SET identity_key = 'ronaldo|c'
WHERE normalized_name LIKE '%ronaldo%'
  AND normalized_name LIKE '%cristiano%'
  AND (identity_key IS NULL OR identity_key <> 'ronaldo|c');
