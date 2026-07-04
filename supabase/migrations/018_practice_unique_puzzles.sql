-- Practice mode: never serve daily puzzle; support exclude id for back-to-back sessions.

DROP FUNCTION IF EXISTS public.select_practice_puzzle(TEXT, SMALLINT, TEXT, INT);

CREATE OR REPLACE FUNCTION public.select_practice_puzzle(
  p_user_uuid TEXT,
  p_grid_size SMALLINT DEFAULT 3,
  p_difficulty_tier TEXT DEFAULT 'medium',
  p_lookback_days INT DEFAULT 30,
  p_exclude_puzzle_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_puzzle_id UUID;
  v_recent_ids UUID[];
  v_recent_club_ids UUID[];
  v_daily_id UUID;
  v_tier TEXT;
  v_tiers TEXT[] := ARRAY[
    lower(trim(COALESCE(p_difficulty_tier, 'medium'))),
    'hard',
    'legend'
  ];
  v_err TEXT;
BEGIN
  SELECT id INTO v_daily_id
  FROM puzzles
  WHERE mode = 'daily'
    AND puzzle_date = CURRENT_DATE
    AND is_published = TRUE
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT ARRAY_AGG(DISTINCT puzzle_id)
  INTO v_recent_ids
  FROM user_practice_history
  WHERE user_uuid = p_user_uuid
    AND played_at > NOW() - (p_lookback_days || ' days')::INTERVAL;

  SELECT ARRAY_AGG(DISTINCT club_id)
  INTO v_recent_club_ids
  FROM (
    SELECT prc.club_id
    FROM user_practice_history h
    JOIN puzzle_row_clubs prc ON prc.puzzle_id = h.puzzle_id
    WHERE h.user_uuid = p_user_uuid
      AND h.played_at > NOW() - (p_lookback_days || ' days')::INTERVAL
    UNION
    SELECT pcc.club_id
    FROM user_practice_history h
    JOIN puzzle_col_clubs pcc ON pcc.puzzle_id = h.puzzle_id
    WHERE h.user_uuid = p_user_uuid
      AND h.played_at > NOW() - (p_lookback_days || ' days')::INTERVAL
  ) clubs;

  SELECT p.id INTO v_puzzle_id
  FROM puzzles p
  WHERE p.mode = 'practice'
    AND p.grid_size = p_grid_size
    AND p.is_published = TRUE
    AND (v_recent_ids IS NULL OR NOT (p.id = ANY(v_recent_ids)))
    AND (p_exclude_puzzle_id IS NULL OR p.id <> p_exclude_puzzle_id)
    AND (v_daily_id IS NULL OR p.id <> v_daily_id)
  ORDER BY
    -LN(GREATEST(random(), 1e-9)) / (
      1.0
      + COALESCE((
        SELECT COUNT(*)::NUMERIC FROM user_practice_history h WHERE h.puzzle_id = p.id
      ), 0)
      + COALESCE((
        SELECT COUNT(DISTINCT prc.club_id)::NUMERIC
        FROM puzzle_row_clubs prc
        WHERE prc.puzzle_id = p.id
          AND v_recent_club_ids IS NOT NULL
          AND prc.club_id = ANY(v_recent_club_ids)
      ), 0) * 2.0
      + COALESCE((
        SELECT COUNT(DISTINCT pcc.club_id)::NUMERIC
        FROM puzzle_col_clubs pcc
        WHERE pcc.puzzle_id = p.id
          AND v_recent_club_ids IS NOT NULL
          AND pcc.club_id = ANY(v_recent_club_ids)
      ), 0) * 2.0
    )
  LIMIT 1;

  IF v_puzzle_id IS NULL THEN
    FOREACH v_tier IN ARRAY v_tiers LOOP
      BEGIN
        v_puzzle_id := public.generate_puzzle(
          'practice'::puzzle_mode,
          p_grid_size,
          v_tier,
          NULL::DATE,
          CASE WHEN v_tier = 'legend' THEN 5000 ELSE 2000 END
        );
        IF p_exclude_puzzle_id IS NOT NULL AND v_puzzle_id = p_exclude_puzzle_id THEN
          v_puzzle_id := NULL;
        ELSIF v_daily_id IS NOT NULL AND v_puzzle_id = v_daily_id THEN
          v_puzzle_id := NULL;
        ELSE
          EXIT;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        v_err := SQLERRM;
        RAISE NOTICE 'select_practice_puzzle tier % failed: %', v_tier, v_err;
      END;
    END LOOP;
  END IF;

  -- Practice-only fallback (never daily).
  IF v_puzzle_id IS NULL THEN
    SELECT p.id INTO v_puzzle_id
    FROM puzzles p
    WHERE p.mode = 'practice'
      AND p.grid_size = p_grid_size
      AND p.is_published = TRUE
      AND (p_exclude_puzzle_id IS NULL OR p.id <> p_exclude_puzzle_id)
      AND (v_daily_id IS NULL OR p.id <> v_daily_id)
    ORDER BY p.created_at DESC
    LIMIT 1;
  END IF;

  IF v_puzzle_id IS NULL THEN
    RAISE EXCEPTION 'select_practice_puzzle FAILED: %', COALESCE(v_err, 'no practice puzzles available');
  END IF;

  INSERT INTO user_practice_history (user_uuid, puzzle_id)
  VALUES (p_user_uuid, v_puzzle_id);

  RETURN v_puzzle_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.select_practice_puzzle(TEXT, SMALLINT, TEXT, INT, UUID) TO anon, authenticated, service_role;
