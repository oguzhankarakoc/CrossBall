-- Performance: hot RPCs, indexes, daily puzzle path, club slug lookup.
-- Addresses CI timeouts (double graph refresh) and search/leaderboard latency.

-- =============================================================================
-- 1. Indexes for leaderboard + session scoring
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_player_progression_rating_global
  ON public.player_progression (competitive_rating DESC, experience_points DESC)
  WHERE games_completed > 0;

CREATE INDEX IF NOT EXISTS idx_session_hints_session
  ON public.session_hints (session_id);

CREATE INDEX IF NOT EXISTS idx_puzzles_daily_created
  ON public.puzzles (created_at DESC)
  WHERE mode = 'daily';

CREATE INDEX IF NOT EXISTS idx_puzzle_row_clubs_club
  ON public.puzzle_row_clubs (club_id);

CREATE INDEX IF NOT EXISTS idx_puzzle_col_clubs_club
  ON public.puzzle_col_clubs (club_id);

-- =============================================================================
-- 2. club_ids_equivalent_to — index-friendly slug IN list (no function on column)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.club_ids_equivalent_to(p_club_ref TEXT)
RETURNS UUID[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_slug TEXT;
  v_slugs TEXT[];
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

  -- Keys are canonical_club_slug() outputs; values are all raw slugs that map to them.
  v_slugs := CASE v_slug
    WHEN 'barcelona' THEN ARRAY['barcelona', 'fc-barcelona']
    WHEN 'chelsea' THEN ARRAY['chelsea', 'chelsea-fc']
    WHEN 'psg' THEN ARRAY['psg', 'paris-saintgermain', 'paris-saint-germain']
    WHEN 'bayern-munich' THEN ARRAY['bayern-munich', 'bayern', 'fc-bayern-munchen', 'bayern-munchen']
    WHEN 'manchester-united' THEN ARRAY['manchester-united', 'man-utd', 'man-united', 'manchester-utd', 'manchester_utd']
    WHEN 'manchester-city' THEN ARRAY['manchester-city', 'man-city', 'manchester_city']
    WHEN 'arsenal-fc' THEN ARRAY['arsenal-fc', 'arsenal']
    WHEN 'liverpool-fc' THEN ARRAY['liverpool-fc', 'liverpool']
    WHEN 'inter-milan' THEN ARRAY['inter-milan', 'inter', 'internazionale']
    WHEN 'atletico-madrid' THEN ARRAY['atletico-madrid', 'atletico', 'atletico-madrigo']
    WHEN 'fc-porto' THEN ARRAY['fc-porto', 'porto']
    WHEN 'tottenham-hotspur' THEN ARRAY['tottenham-hotspur', 'tottenham', 'spurs']
    WHEN 'newcastle-united' THEN ARRAY['newcastle-united', 'newcastle']
    WHEN 'west-ham-united' THEN ARRAY['west-ham-united', 'west-ham']
    WHEN 'celtic-fc' THEN ARRAY['celtic-fc', 'celtic']
    WHEN 'rangers-fc' THEN ARRAY['rangers-fc', 'rangers']
    WHEN 'sevilla-fc' THEN ARRAY['sevilla-fc', 'sevilla']
    WHEN 'valencia-cf' THEN ARRAY['valencia-cf', 'valencia']
    WHEN 'borussia-dortmund' THEN ARRAY['borussia-dortmund', 'dortmund', 'bvb']
    WHEN 'borussia-monchengladbach' THEN ARRAY['borussia-monchengladbach', 'gladbach']
    WHEN 'ac-milan' THEN ARRAY['ac-milan', 'milan']
    ELSE ARRAY[v_slug]
  END;

  RETURN ARRAY(
    SELECT c.id
    FROM clubs c
    WHERE c.slug = ANY(v_slugs)
  );
END;
$$;

-- =============================================================================
-- 3. get_intersection_players — use materialized view (not full players scan)
-- =============================================================================

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
DECLARE
  v_row UUID[];
  v_col UUID[];
BEGIN
  v_row := public.club_ids_equivalent_to(p_row_club_id);
  v_col := public.club_ids_equivalent_to(p_col_club_id);

  IF coalesce(array_length(v_row, 1), 0) = 0
     OR coalesce(array_length(v_col, 1), 0) = 0 THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT DISTINCT p.id, p.name, p.nationality_code, p.primary_position
  FROM public.player_club_intersections i
  JOIN public.players p ON p.id = i.player_id
  WHERE (i.club_a_id = ANY (v_row) AND i.club_b_id = ANY (v_col))
     OR (i.club_a_id = ANY (v_col) AND i.club_b_id = ANY (v_row))
  LIMIT 50;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_intersection_players(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_intersection_players(TEXT, TEXT) TO service_role;

-- =============================================================================
-- 4. Weekly leaderboard — single CTE pass, no per-row 7-day subquery
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_weekly_daily_leaderboard(
  p_user_uuid TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := (NOW() AT TIME ZONE 'UTC')::DATE;
  v_week_key TEXT := public.iso_week_key(v_today);
  v_week_start DATE := public.iso_week_start(v_today);
  v_week_end DATE := v_week_start + 6;
  v_limit INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100);
BEGIN
  RETURN (
    WITH week_dates AS (
      SELECT generate_series(v_week_start, v_week_end, '1 day'::interval)::date AS puzzle_date
    ),
    totals AS (
      SELECT
        wds.user_uuid,
        SUM(wds.daily_score) AS total_score,
        COUNT(*) FILTER (WHERE wds.daily_score > 0) AS days_played,
        SUM(wds.hints_used) AS total_hints,
        SUM(wds.mistakes) AS total_mistakes,
        MAX(wds.completed_at) AS last_completed_at
      FROM public.weekly_daily_scores wds
      WHERE wds.week_key = v_week_key
      GROUP BY wds.user_uuid
      HAVING SUM(wds.daily_score) > 0
    ),
    ranked AS (
      SELECT
        ROW_NUMBER() OVER (
          ORDER BY
            t.total_score DESC,
            t.total_hints ASC,
            t.total_mistakes ASC,
            t.last_completed_at ASC
        ) AS rank,
        t.user_uuid,
        public.resolve_player_display_name(u.display_name, t.user_uuid) AS display_name,
        t.total_score,
        t.days_played,
        t.total_hints,
        t.total_mistakes
      FROM totals t
      JOIN public.users u ON u.user_uuid = t.user_uuid
    ),
    top_n AS (
      SELECT * FROM ranked WHERE rank <= v_limit
    ),
    needed AS (
      SELECT user_uuid FROM top_n
      UNION
      SELECT p_user_uuid
      WHERE p_user_uuid IS NOT NULL
        AND EXISTS (SELECT 1 FROM ranked r WHERE r.user_uuid = p_user_uuid)
    ),
    daily_by_user AS (
      SELECT
        n.user_uuid,
        jsonb_agg(
          jsonb_build_object(
            'date', wd.puzzle_date,
            'score', COALESCE(wds.daily_score, 0)
          )
          ORDER BY wd.puzzle_date
        ) AS daily_scores
      FROM needed n
      CROSS JOIN week_dates wd
      LEFT JOIN public.weekly_daily_scores wds
        ON wds.week_key = v_week_key
       AND wds.user_uuid = n.user_uuid
       AND wds.puzzle_date = wd.puzzle_date
      GROUP BY n.user_uuid
    )
    SELECT jsonb_build_object(
      'ok', TRUE,
      'week_key', v_week_key,
      'week_start', v_week_start,
      'week_end', v_week_end,
      'entries', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'rank', t.rank,
            'user_uuid', t.user_uuid,
            'display_name', t.display_name,
            'total_score', t.total_score,
            'days_played', t.days_played,
            'total_hints', t.total_hints,
            'total_mistakes', t.total_mistakes,
            'daily_scores', COALESCE(d.daily_scores, '[]'::JSONB)
          )
          ORDER BY t.rank
        )
        FROM top_n t
        LEFT JOIN daily_by_user d ON d.user_uuid = t.user_uuid
      ), '[]'::JSONB),
      'my_entry', (
        SELECT jsonb_build_object(
          'rank', r.rank,
          'user_uuid', r.user_uuid,
          'display_name', r.display_name,
          'total_score', r.total_score,
          'days_played', r.days_played,
          'total_hints', r.total_hints,
          'total_mistakes', r.total_mistakes,
          'daily_scores', COALESCE(d.daily_scores, '[]'::JSONB)
        )
        FROM ranked r
        LEFT JOIN daily_by_user d ON d.user_uuid = r.user_uuid
        WHERE p_user_uuid IS NOT NULL
          AND r.user_uuid = p_user_uuid
        LIMIT 1
      )
    )
  );
END;
$$;

-- =============================================================================
-- 5. ensure_daily_puzzle — fast path first (CI timeout), quality path fallback
-- =============================================================================

CREATE OR REPLACE FUNCTION public.ensure_daily_puzzle(
  p_date DATE DEFAULT CURRENT_DATE,
  p_difficulty_tier TEXT DEFAULT 'hard'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
  v_tier TEXT;
  v_tiers TEXT[] := ARRAY[
    lower(trim(COALESCE(p_difficulty_tier, 'hard'))),
    'legend',
    'hard',
    'medium',
    'easy'
  ];
  v_err TEXT;
  v_pairs INT;
BEGIN
  SELECT id INTO v_id
  FROM puzzles
  WHERE puzzle_date = p_date
    AND mode = 'daily'
    AND grid_size = 3
    AND is_published = TRUE
  LIMIT 1;

  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;

  v_pairs := public.ensure_club_relationship_graph(100);
  RAISE NOTICE 'ensure_daily_puzzle: club_relationships pairs=%', v_pairs;

  -- Fast generator first (bounded attempts) — primary path for CI.
  BEGIN
    RETURN public.generate_daily_puzzle_fast(p_date, 3::SMALLINT, 3, 200);
  EXCEPTION
    WHEN unique_violation THEN
      SELECT id INTO v_id
      FROM puzzles
      WHERE puzzle_date = p_date AND mode = 'daily' AND grid_size = 3
      LIMIT 1;
      IF v_id IS NOT NULL THEN
        RETURN v_id;
      END IF;
    WHEN OTHERS THEN
      v_err := SQLERRM;
      RAISE NOTICE 'ensure_daily_puzzle fast(3) failed: %', v_err;
  END;

  BEGIN
    RETURN public.generate_daily_puzzle_fast(p_date, 3::SMALLINT, 1, 300);
  EXCEPTION
    WHEN unique_violation THEN
      SELECT id INTO v_id
      FROM puzzles
      WHERE puzzle_date = p_date AND mode = 'daily' AND grid_size = 3
      LIMIT 1;
      IF v_id IS NOT NULL THEN
        RETURN v_id;
      END IF;
    WHEN OTHERS THEN
      v_err := SQLERRM;
      RAISE NOTICE 'ensure_daily_puzzle fast(1) failed: %', v_err;
  END;

  -- Quality path as fallback (can be slow; only if fast failed).
  FOREACH v_tier IN ARRAY v_tiers LOOP
    BEGIN
      RETURN public.generate_puzzle(
        'daily'::puzzle_mode,
        3::SMALLINT,
        v_tier,
        p_date,
        80
      );
    EXCEPTION
      WHEN unique_violation THEN
        SELECT id INTO v_id
        FROM puzzles
        WHERE puzzle_date = p_date AND mode = 'daily' AND grid_size = 3
        LIMIT 1;
        IF v_id IS NOT NULL THEN
          RETURN v_id;
        END IF;
      WHEN OTHERS THEN
        v_err := SQLERRM;
        RAISE NOTICE 'ensure_daily_puzzle tier % failed: %', v_tier, v_err;
    END;
  END LOOP;

  SELECT id INTO v_id
  FROM puzzles
  WHERE puzzle_date = p_date
    AND mode = 'daily'
    AND grid_size = 3
  LIMIT 1;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'ensure_daily_puzzle failed for %', p_date;
  END IF;
  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_daily_puzzle(DATE, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.club_ids_equivalent_to(TEXT) TO service_role, authenticated;
