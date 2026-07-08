-- Unify identity_key for common duplicate display-name clusters (short vs full legal names).

UPDATE players
SET identity_key = 'coutinho|p'
WHERE normalized_name LIKE '%coutinho%'
  AND normalized_name LIKE '%philippe%'
  AND (identity_key IS NULL OR identity_key <> 'coutinho|p');

UPDATE players
SET identity_key = 'morata|a'
WHERE normalized_name LIKE '%morata%'
  AND normalized_name LIKE '%alvaro%'
  AND (identity_key IS NULL OR identity_key <> 'morata|a');
