-- Backfill missing player nationality/position from sibling records sharing identity_key.

UPDATE players AS target
SET
  nationality_code = COALESCE(target.nationality_code, source.nationality_code),
  primary_position = COALESCE(target.primary_position, source.primary_position),
  updated_at = NOW()
FROM (
  SELECT
    identity_key,
    MAX(nationality_code) FILTER (WHERE nationality_code IS NOT NULL AND nationality_code <> '') AS nationality_code,
    MAX(primary_position) FILTER (WHERE primary_position IS NOT NULL AND primary_position <> '') AS primary_position
  FROM players
  WHERE identity_key IS NOT NULL AND identity_key <> ''
  GROUP BY identity_key
) AS source
WHERE target.identity_key = source.identity_key
  AND (
    (target.nationality_code IS NULL OR target.nationality_code = '')
    OR (target.primary_position IS NULL OR target.primary_position = '')
  )
  AND (
    source.nationality_code IS NOT NULL
    OR source.primary_position IS NOT NULL
  );
