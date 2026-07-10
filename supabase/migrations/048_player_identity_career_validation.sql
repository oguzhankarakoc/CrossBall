-- Validate careers across duplicate player rows that share identity_key
-- (e.g. Kaggle id 190871 Neymar + API id af-276 Neymar).

CREATE OR REPLACE FUNCTION public.player_identity_group_ids(p_player_id UUID)
RETURNS UUID[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH source AS (
    SELECT identity_key
    FROM players
    WHERE id = p_player_id
  )
  SELECT COALESCE(
    ARRAY(
      SELECT p.id
      FROM players p
      CROSS JOIN source s
      WHERE p.id = p_player_id
         OR (
           s.identity_key IS NOT NULL
           AND s.identity_key <> ''
           AND p.identity_key = s.identity_key
         )
    ),
    ARRAY[p_player_id]
  );
$$;

CREATE OR REPLACE FUNCTION public.player_played_for_clubs(
  p_player_id UUID,
  p_club_ref TEXT
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM player_career_history h
    WHERE h.player_id = ANY(public.player_identity_group_ids(p_player_id))
      AND h.club_id = ANY(public.club_ids_equivalent_to(p_club_ref))
      AND h.is_senior = TRUE
      AND h.is_youth = FALSE
      AND h.is_reserve = FALSE
  );
$$;

-- Unify common split Kaggle/API duplicate clusters.
UPDATE players
SET identity_key = 'neymar|n'
WHERE normalized_name ILIKE '%neymar%'
  AND (identity_key IS NULL OR identity_key <> 'neymar|n');

UPDATE players
SET identity_key = 'nunez|d'
WHERE normalized_name ~* 'n[uú]ñez'
  AND (
    normalized_name ILIKE '%darwin%'
    OR normalized_name ~* '^d[\.\s]'
  )
  AND (identity_key IS NULL OR identity_key <> 'nunez|d');

UPDATE players
SET identity_key = 'cancelo|j'
WHERE normalized_name ILIKE '%cancelo%'
  AND (identity_key IS NULL OR identity_key <> 'cancelo|j');

GRANT EXECUTE ON FUNCTION public.player_identity_group_ids(UUID) TO anon, authenticated, service_role;
