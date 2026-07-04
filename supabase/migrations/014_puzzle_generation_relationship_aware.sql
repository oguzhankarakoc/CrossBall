-- Relationship-aware puzzle generation: pick row/col clubs from the
-- club_relationships graph instead of random top-club sampling.

-- =============================================================================
-- Pick a valid row/col club set for a grid (structural constraint only)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.pick_valid_puzzle_clubs(
  p_grid_size SMALLINT,
  p_min_answers INT,
  p_recent_club_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (row_ids UUID[], col_ids UUID[])
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_row_ids UUID[];
  v_col_ids UUID[];
BEGIN
  SELECT ARRAY_AGG(sub.id ORDER BY sub.id)
  INTO v_row_ids
  FROM (
    SELECT c.id
    FROM clubs c
    WHERE c.is_top_club = TRUE
      AND (
        SELECT COUNT(DISTINCT partner.id)
        FROM club_relationships cr
        JOIN clubs partner
          ON partner.id = CASE
            WHEN cr.club_a_id = c.id THEN cr.club_b_id
            ELSE cr.club_a_id
          END
        WHERE (cr.club_a_id = c.id OR cr.club_b_id = c.id)
          AND cr.valid_player_count >= p_min_answers
          AND partner.is_top_club = TRUE
          AND partner.id <> c.id
      ) >= p_grid_size
    ORDER BY -LN(GREATEST(random(), 1e-9)) / (
      CASE
        WHEN p_recent_club_ids IS NOT NULL AND c.id = ANY(p_recent_club_ids) THEN 0.35
        ELSE 2.0
      END
    )
    LIMIT p_grid_size
  ) sub;

  IF v_row_ids IS NULL OR array_length(v_row_ids, 1) <> p_grid_size THEN
    RETURN;
  END IF;

  SELECT ARRAY_AGG(sub.id ORDER BY sub.id)
  INTO v_col_ids
  FROM (
    SELECT c.id
    FROM clubs c
    WHERE c.is_top_club = TRUE
      AND NOT (c.id = ANY(v_row_ids))
      AND (
        SELECT COUNT(*)
        FROM unnest(v_row_ids) AS r(rid)
        WHERE EXISTS (
          SELECT 1
          FROM club_relationships cr
          WHERE cr.valid_player_count >= p_min_answers
            AND (
              (cr.club_a_id = r.rid AND cr.club_b_id = c.id)
              OR (cr.club_a_id = c.id AND cr.club_b_id = r.rid)
            )
        )
      ) = p_grid_size
    ORDER BY -LN(GREATEST(random(), 1e-9)) / (
      CASE
        WHEN p_recent_club_ids IS NOT NULL AND c.id = ANY(p_recent_club_ids) THEN 0.35
        ELSE 2.0
      END
    )
    LIMIT p_grid_size
  ) sub;

  IF v_col_ids IS NULL OR array_length(v_col_ids, 1) <> p_grid_size THEN
    RETURN;
  END IF;

  row_ids := v_row_ids;
  col_ids := v_col_ids;
  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.pick_valid_puzzle_clubs(SMALLINT, INT, UUID[]) TO authenticated;

-- =============================================================================
-- Generate puzzle using relationship-aware club selection
-- =============================================================================

CREATE OR REPLACE FUNCTION public.generate_puzzle(
  p_mode puzzle_mode DEFAULT 'daily',
  p_grid_size SMALLINT DEFAULT 3,
  p_difficulty_tier TEXT DEFAULT 'medium',
  p_puzzle_date DATE DEFAULT NULL,
  p_max_attempts INT DEFAULT 5000
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_min_answers INT := public.tier_min_answers(p_difficulty_tier);
  v_puzzle_id UUID;
  v_row_ids UUID[];
  v_col_ids UUID[];
  v_hash TEXT;
  v_r INT;
  v_c INT;
  v_rel club_relationships%ROWTYPE;
  v_cell_count INT;
  v_avg_difficulty NUMERIC;
  v_attempt INT := 0;
  v_recent_hashes TEXT[];
  v_recent_club_ids UUID[];
  v_eval JSONB;
  v_quality INT;
  v_human INT;
  v_rejected INT := 0;
BEGIN
  IF p_grid_size NOT IN (3, 4) THEN
    RAISE EXCEPTION 'grid_size must be 3 or 4';
  END IF;

  SELECT ARRAY_AGG(puzzle_hash)
  INTO v_recent_hashes
  FROM puzzles
  WHERE puzzle_hash IS NOT NULL
    AND created_at > NOW() - INTERVAL '30 days';

  SELECT ARRAY_AGG(DISTINCT club_id)
  INTO v_recent_club_ids
  FROM (
    SELECT prc.club_id
    FROM puzzle_row_clubs prc
    JOIN puzzles p ON p.id = prc.puzzle_id
    WHERE p.created_at > NOW() - INTERVAL '14 days'
    UNION
    SELECT pcc.club_id
    FROM puzzle_col_clubs pcc
    JOIN puzzles p ON p.id = pcc.puzzle_id
    WHERE p.created_at > NOW() - INTERVAL '14 days'
  ) recent;

  WHILE v_attempt < p_max_attempts LOOP
    v_attempt := v_attempt + 1;

    SELECT p.row_ids, p.col_ids
    INTO v_row_ids, v_col_ids
    FROM public.pick_valid_puzzle_clubs(
      p_grid_size,
      v_min_answers,
      v_recent_club_ids
    ) p
    LIMIT 1;

    IF v_row_ids IS NULL OR v_col_ids IS NULL
       OR array_length(v_row_ids, 1) <> p_grid_size
       OR array_length(v_col_ids, 1) <> p_grid_size THEN
      CONTINUE;
    END IF;

    IF v_row_ids && v_col_ids THEN
      CONTINUE;
    END IF;

    v_hash := public.compute_puzzle_hash(v_row_ids, v_col_ids);

    IF v_hash = ANY(COALESCE(v_recent_hashes, ARRAY[]::TEXT[])) THEN
      CONTINUE;
    END IF;

    v_cell_count := 0;
    v_avg_difficulty := 0;

    FOR v_r IN 0..(p_grid_size - 1) LOOP
      FOR v_c IN 0..(p_grid_size - 1) LOOP
        SELECT * INTO v_rel
        FROM public.get_club_relationship(v_row_ids[v_r + 1], v_col_ids[v_c + 1]);

        IF v_rel IS NULL OR v_rel.valid_player_count < v_min_answers THEN
          v_cell_count := -1;
          EXIT;
        END IF;

        v_avg_difficulty := v_avg_difficulty + v_rel.difficulty_score;
        v_cell_count := v_cell_count + 1;
      END LOOP;
      EXIT WHEN v_cell_count < 0;
    END LOOP;

    IF v_cell_count <> (p_grid_size * p_grid_size) THEN
      CONTINUE;
    END IF;

    v_avg_difficulty := v_avg_difficulty / v_cell_count;

    v_eval := public.evaluate_puzzle_candidate(v_row_ids, v_col_ids, p_grid_size, v_min_answers);
    v_quality := (v_eval->>'quality_score')::INT;
    v_human := (v_eval->>'human_simulation_score')::INT;

    IF NOT COALESCE((v_eval->>'passed')::BOOLEAN, FALSE) THEN
      v_rejected := v_rejected + 1;
      CONTINUE;
    END IF;

    INSERT INTO puzzles (
      puzzle_date,
      mode,
      grid_size,
      difficulty,
      difficulty_tier,
      puzzle_hash,
      quality_score,
      human_simulation_score,
      quality_metrics,
      is_published
    )
    VALUES (
      COALESCE(p_puzzle_date, CASE WHEN p_mode = 'daily' THEN CURRENT_DATE ELSE NULL END),
      p_mode,
      p_grid_size,
      v_avg_difficulty,
      lower(trim(p_difficulty_tier)),
      v_hash,
      v_quality,
      v_human,
      v_eval,
      TRUE
    )
    RETURNING id INTO v_puzzle_id;

    FOR v_r IN 0..(p_grid_size - 1) LOOP
      INSERT INTO puzzle_row_clubs (puzzle_id, row_index, club_id)
      VALUES (v_puzzle_id, v_r, v_row_ids[v_r + 1]);
    END LOOP;

    FOR v_c IN 0..(p_grid_size - 1) LOOP
      INSERT INTO puzzle_col_clubs (puzzle_id, col_index, club_id)
      VALUES (v_puzzle_id, v_c, v_col_ids[v_c + 1]);
    END LOOP;

    FOR v_r IN 0..(p_grid_size - 1) LOOP
      FOR v_c IN 0..(p_grid_size - 1) LOOP
        SELECT * INTO v_rel
        FROM public.get_club_relationship(v_row_ids[v_r + 1], v_col_ids[v_c + 1]);

        INSERT INTO puzzle_cells (
          puzzle_id, row_index, col_index, valid_answer_count, difficulty
        )
        VALUES (
          v_puzzle_id,
          v_r,
          v_c,
          v_rel.valid_player_count,
          v_rel.difficulty_score
        );
      END LOOP;
    END LOOP;

    RAISE NOTICE 'Published puzzle % (quality=%, human=%, attempts=%, rejected=%)',
      v_puzzle_id, v_quality, v_human, v_attempt, v_rejected;

    RETURN v_puzzle_id;
  END LOOP;

  RAISE EXCEPTION 'Failed to generate quality puzzle after % attempts (% rejected by quality gate)',
    p_max_attempts, v_rejected;
END;
$$;

-- =============================================================================
-- Daily: one global puzzle per date, tier fallback when data is sparse
-- =============================================================================

CREATE OR REPLACE FUNCTION public.ensure_daily_puzzle(
  p_date DATE DEFAULT CURRENT_DATE,
  p_difficulty_tier TEXT DEFAULT 'medium'
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
    lower(trim(COALESCE(p_difficulty_tier, 'medium'))),
    'hard',
    'legend'
  ];
  v_err TEXT;
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

  FOREACH v_tier IN ARRAY v_tiers LOOP
    BEGIN
      RETURN public.generate_puzzle(
        'daily'::puzzle_mode,
        3::SMALLINT,
        v_tier,
        p_date,
        CASE WHEN v_tier = 'legend' THEN 8000 ELSE 3000 END
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

  RAISE EXCEPTION 'ensure_daily_puzzle FAILED: %', COALESCE(v_err, 'no tier succeeded');
END;
$$;

-- =============================================================================
-- Practice: avoid recent club overlap, tier fallback on generation
-- =============================================================================

CREATE OR REPLACE FUNCTION public.select_practice_puzzle(
  p_user_uuid TEXT,
  p_grid_size SMALLINT DEFAULT 3,
  p_difficulty_tier TEXT DEFAULT 'medium',
  p_lookback_days INT DEFAULT 30
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
  v_tier TEXT;
  v_tiers TEXT[] := ARRAY[
    lower(trim(COALESCE(p_difficulty_tier, 'medium'))),
    'hard',
    'legend'
  ];
  v_err TEXT;
BEGIN
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
        EXIT;
      EXCEPTION WHEN OTHERS THEN
        v_err := SQLERRM;
        RAISE NOTICE 'select_practice_puzzle tier % failed: %', v_tier, v_err;
      END;
    END LOOP;
  END IF;

  IF v_puzzle_id IS NULL THEN
    RAISE EXCEPTION 'select_practice_puzzle FAILED: %', COALESCE(v_err, 'pool empty and generation failed');
  END IF;

  INSERT INTO user_practice_history (user_uuid, puzzle_id)
  VALUES (p_user_uuid, v_puzzle_id);

  RETURN v_puzzle_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_daily_puzzle(DATE, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.select_practice_puzzle(TEXT, SMALLINT, TEXT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.generate_puzzle(puzzle_mode, SMALLINT, TEXT, DATE, INT) TO authenticated;

-- Seed today's global daily puzzle (non-fatal)
DO $$
DECLARE
  v_today DATE := CURRENT_DATE;
BEGIN
  BEGIN
    PERFORM public.ensure_daily_puzzle(v_today, 'medium');
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Daily puzzle seed skipped: %', SQLERRM;
  END;
END;
$$;
