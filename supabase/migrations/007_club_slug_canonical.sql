-- Canonical club slug resolution + intersection validation.
-- Fixes false negatives when puzzle clubs use legacy slugs (barcelona)
-- but career data uses ETL slugs (fc-barcelona), or vice versa.

DROP FUNCTION IF EXISTS public.get_intersection_players(UUID, UUID);

CREATE OR REPLACE FUNCTION public.canonical_club_slug(p_slug TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_slug IN ('fc-barcelona') THEN 'barcelona'
    WHEN p_slug IN ('chelsea-fc') THEN 'chelsea'
    WHEN p_slug IN ('paris-saintgermain', 'paris-saint-germain') THEN 'psg'
    ELSE p_slug
  END;
$$;

CREATE OR REPLACE FUNCTION public.club_ids_equivalent_to(p_club_ref TEXT)
RETURNS UUID[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_slug TEXT;
BEGIN
  IF p_club_ref ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    SELECT public.canonical_club_slug(c.slug)
    INTO v_slug
    FROM clubs c
    WHERE c.id = p_club_ref::UUID;
  ELSE
    v_slug := public.canonical_club_slug(p_club_ref);
  END IF;

  IF v_slug IS NULL THEN
    RETURN ARRAY[]::UUID[];
  END IF;

  RETURN ARRAY(
    SELECT c.id
    FROM clubs c
    WHERE public.canonical_club_slug(c.slug) = v_slug
  );
END;
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
    WHERE h.player_id = p_player_id
      AND h.club_id = ANY(public.club_ids_equivalent_to(p_club_ref))
      AND h.is_senior = TRUE
      AND h.is_youth = FALSE
      AND h.is_reserve = FALSE
  );
$$;

CREATE OR REPLACE FUNCTION public.validate_player_intersection(
  p_player_id UUID,
  p_row_club_ref TEXT,
  p_col_club_ref TEXT
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.player_played_for_clubs(p_player_id, p_row_club_ref)
     AND public.player_played_for_clubs(p_player_id, p_col_club_ref);
$$;

CREATE OR REPLACE FUNCTION public.get_intersection_players(
  p_row_club_id TEXT,
  p_col_club_id TEXT
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  nationality_code CHAR(2),
  primary_position TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT p.id, p.name, p.nationality_code, p.primary_position
  FROM players p
  WHERE public.player_played_for_clubs(p.id, p_row_club_id)
    AND public.player_played_for_clubs(p.id, p_col_club_id)
  LIMIT 50;
END;
$$;

GRANT EXECUTE ON FUNCTION public.canonical_club_slug(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.club_ids_equivalent_to(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.player_played_for_clubs(UUID, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.validate_player_intersection(UUID, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_intersection_players(TEXT, TEXT) TO anon, authenticated;

-- Merge duplicate alias clubs so career rows point at canonical records.
DO $merge$
DECLARE
  rec RECORD;
  canonical_id UUID;
BEGIN
  FOR rec IN
    SELECT * FROM (VALUES
      ('barcelona', 'fc-barcelona'),
      ('chelsea', 'chelsea-fc'),
      ('psg', 'paris-saintgermain')
    ) AS t(canonical_slug, duplicate_slug)
  LOOP
    SELECT id INTO canonical_id FROM clubs WHERE slug = rec.canonical_slug LIMIT 1;
    IF canonical_id IS NULL THEN
      CONTINUE;
    END IF;

    UPDATE player_career_history h
    SET club_id = canonical_id
    FROM clubs dup
    WHERE h.club_id = dup.id
      AND dup.slug = rec.duplicate_slug
      AND NOT EXISTS (
        SELECT 1
        FROM player_career_history existing
        WHERE existing.player_id = h.player_id
          AND existing.club_id = canonical_id
          AND existing.start_date IS NOT DISTINCT FROM h.start_date
          AND existing.is_loan = h.is_loan
      );

    DELETE FROM player_career_history h
    USING clubs dup
    WHERE h.club_id = dup.id
      AND dup.slug = rec.duplicate_slug;

    DELETE FROM clubs WHERE slug = rec.duplicate_slug;
  END LOOP;
END;
$merge$;

SELECT public.refresh_player_club_intersections();
