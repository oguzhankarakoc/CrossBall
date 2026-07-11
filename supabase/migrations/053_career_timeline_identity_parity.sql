-- Align career timeline with validate_player_intersection:
-- identity-group careers + club equivalence for axis highlights.

DROP FUNCTION IF EXISTS public.get_player_career_timeline(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS public.get_player_career_timeline(UUID, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.get_player_career_timeline(
  p_player_id UUID,
  p_row_club_id TEXT,
  p_col_club_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_player_name TEXT;
  v_row_ids UUID[];
  v_col_ids UUID[];
BEGIN
  SELECT name INTO v_player_name FROM players WHERE id = p_player_id;

  v_row_ids := public.club_ids_equivalent_to(p_row_club_id);
  v_col_ids := public.club_ids_equivalent_to(p_col_club_id);

  RETURN jsonb_build_object(
    'ok', TRUE,
    'player_name', COALESCE(v_player_name, 'Player'),
    'entries', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'club_id', x.club_id,
          'club_name', x.club_name,
          'start_year', x.start_year,
          'end_year', x.end_year,
          'highlight', x.highlight
        )
        ORDER BY x.start_year NULLS LAST, x.club_name
      )
      FROM (
        SELECT DISTINCT ON (pch.club_id)
          pch.club_id,
          COALESCE(c.short_name, c.display_name, c.name) AS club_name,
          EXTRACT(YEAR FROM pch.start_date)::INT AS start_year,
          CASE
            WHEN pch.end_date IS NULL THEN NULL
            ELSE EXTRACT(YEAR FROM pch.end_date)::INT
          END AS end_year,
          (
            pch.club_id = ANY (v_row_ids)
            OR pch.club_id = ANY (v_col_ids)
          ) AS highlight
        FROM player_career_history pch
        JOIN clubs c ON c.id = pch.club_id
        WHERE pch.player_id = ANY (public.player_identity_group_ids(p_player_id))
          AND pch.is_senior = TRUE
          AND pch.is_youth = FALSE
          AND pch.is_reserve = FALSE
        ORDER BY pch.club_id, pch.start_date NULLS LAST
      ) x
    ), '[]'::JSONB)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_player_career_timeline(UUID, TEXT, TEXT)
  TO service_role;
