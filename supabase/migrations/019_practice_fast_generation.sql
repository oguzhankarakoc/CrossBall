-- Practice puzzles: avoid statement timeout on 4x4 generation (fast path + extended timeout).

DROP FUNCTION IF EXISTS public.select_practice_puzzle(TEXT, SMALLINT, TEXT, INT, UUID);

-- Lightweight generator for practice (skips heavy quality evaluation loop).
CREATE OR REPLACE FUNCTION public.generate_practice_puzzle_fast(
  p_grid_size SMALLINT DEFAULT 3,
  p_min_answers INT DEFAULT 3,
  p_max_attempts INT DEFAULT 120
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_puzzle_id UUID;
  v_row_ids UUID[];
  v_col_ids UUID[];
  v_hash TEXT;
  v_r INT;
  v_c INT;
  v_rel club_relationships%ROWTYPE;
  v_attempt INT := 0;
  v_valid BOOLEAN;
  v_avg NUMERIC := 0;
  v_cells INT := 0;
BEGIN
  IF p_grid_size NOT IN (3, 4) THEN
    RAISE EXCEPTION 'grid_size must be 3 or 4';
  END IF;

  WHILE v_attempt < p_max_attempts LOOP
    v_attempt := v_attempt + 1;

    SELECT p.row_ids, p.col_ids
    INTO v_row_ids, v_col_ids
    FROM public.pick_valid_puzzle_clubs(p_grid_size, p_min_answers, NULL) p
    LIMIT 1;

    IF v_row_ids IS NULL OR v_col_ids IS NULL
       OR array_length(v_row_ids, 1) <> p_grid_size
       OR array_length(v_col_ids, 1) <> p_grid_size THEN
      EXIT;
    END IF;

    IF v_row_ids && v_col_ids THEN
      CONTINUE;
    END IF;

    v_valid := TRUE;
    v_avg := 0;
    v_cells := 0;

    FOR v_r IN 0..(p_grid_size - 1) LOOP
      FOR v_c IN 0..(p_grid_size - 1) LOOP
        SELECT * INTO v_rel
        FROM public.get_club_relationship(v_row_ids[v_r + 1], v_col_ids[v_c + 1]);

        IF v_rel IS NULL OR v_rel.valid_player_count < p_min_answers THEN
          v_valid := FALSE;
          EXIT;
        END IF;

        v_avg := v_avg + v_rel.difficulty_score;
        v_cells := v_cells + 1;
      END LOOP;
      EXIT WHEN NOT v_valid;
    END LOOP;

    IF NOT v_valid OR v_cells <> (p_grid_size * p_grid_size) THEN
      CONTINUE;
    END IF;

    v_hash := public.compute_puzzle_hash(v_row_ids, v_col_ids);

    IF EXISTS (SELECT 1 FROM puzzles WHERE puzzle_hash = v_hash) THEN
      CONTINUE;
    END IF;

    v_avg := v_avg / v_cells;

    INSERT INTO puzzles (
      puzzle_date, mode, grid_size, difficulty, difficulty_tier,
      puzzle_hash, quality_score, human_simulation_score, quality_metrics, is_published
    )
    VALUES (
      NULL, 'practice'::puzzle_mode, p_grid_size, v_avg, 'medium',
      v_hash, 50, 50, jsonb_build_object('practice_fast', TRUE), TRUE
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

        INSERT INTO puzzle_cells (puzzle_id, row_index, col_index, valid_answer_count, difficulty)
        VALUES (v_puzzle_id, v_r, v_c, v_rel.valid_player_count, v_rel.difficulty_score);
      END LOOP;
    END LOOP;

    RETURN v_puzzle_id;
  END LOOP;

  RAISE EXCEPTION 'generate_practice_puzzle_fast failed after % attempts', p_max_attempts;
END;
$$;

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
  v_daily_id UUID;
  v_min_answers INT;
  v_max_attempts INT;
  v_err TEXT;
BEGIN
  PERFORM set_config('statement_timeout', '120s', true);

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

  -- Fast pool pick (no per-row scoring subqueries).
  SELECT p.id INTO v_puzzle_id
  FROM puzzles p
  WHERE p.mode = 'practice'
    AND p.grid_size = p_grid_size
    AND p.is_published = TRUE
    AND (v_recent_ids IS NULL OR NOT (p.id = ANY(v_recent_ids)))
    AND (p_exclude_puzzle_id IS NULL OR p.id <> p_exclude_puzzle_id)
    AND (v_daily_id IS NULL OR p.id <> v_daily_id)
  ORDER BY random()
  LIMIT 1;

  IF v_puzzle_id IS NULL THEN
    v_min_answers := CASE WHEN p_grid_size = 4 THEN 3 ELSE 5 END;
    v_max_attempts := CASE WHEN p_grid_size = 4 THEN 180 ELSE 120 END;

    BEGIN
      v_puzzle_id := public.generate_practice_puzzle_fast(
        p_grid_size,
        v_min_answers,
        v_max_attempts
      );
    EXCEPTION WHEN OTHERS THEN
      v_err := SQLERRM;
      RAISE NOTICE 'generate_practice_puzzle_fast failed: %', v_err;
    END;
  END IF;

  IF v_puzzle_id IS NULL THEN
    BEGIN
      v_puzzle_id := public.generate_puzzle(
        'practice'::puzzle_mode,
        p_grid_size,
        CASE WHEN p_grid_size = 4 THEN 'easy' ELSE lower(trim(COALESCE(p_difficulty_tier, 'medium'))) END,
        NULL::DATE,
        CASE WHEN p_grid_size = 4 THEN 80 ELSE 200 END
      );
    EXCEPTION WHEN OTHERS THEN
      v_err := SQLERRM;
      RAISE NOTICE 'generate_puzzle fallback failed: %', v_err;
    END;
  END IF;

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

  IF p_exclude_puzzle_id IS NOT NULL AND v_puzzle_id = p_exclude_puzzle_id THEN
    RAISE EXCEPTION 'select_practice_puzzle FAILED: only excluded puzzle available';
  END IF;

  INSERT INTO user_practice_history (user_uuid, puzzle_id)
  VALUES (p_user_uuid, v_puzzle_id);

  RETURN v_puzzle_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_practice_puzzle_fast(SMALLINT, INT, INT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.select_practice_puzzle(TEXT, SMALLINT, TEXT, INT, UUID) TO anon, authenticated, service_role;
