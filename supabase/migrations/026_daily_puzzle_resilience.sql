-- Daily puzzle resilience: refresh sparse club graph + fast fallback generator.

CREATE OR REPLACE FUNCTION public.ensure_club_relationship_graph(
  p_min_pairs INT DEFAULT 100
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count FROM club_relationships;

  IF v_count >= p_min_pairs THEN
    RETURN v_count;
  END IF;

  RAISE NOTICE 'club_relationships sparse (% pairs) — refreshing graph', v_count;
  PERFORM public.refresh_player_club_intersections();
  PERFORM public.refresh_club_relationships();

  SELECT COUNT(*)::INT INTO v_count FROM club_relationships;
  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_daily_puzzle_fast(
  p_puzzle_date DATE DEFAULT CURRENT_DATE,
  p_grid_size SMALLINT DEFAULT 3,
  p_min_answers INT DEFAULT 3,
  p_max_attempts INT DEFAULT 200
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

  SELECT id INTO v_puzzle_id
  FROM puzzles
  WHERE puzzle_date = p_puzzle_date
    AND mode = 'daily'
    AND grid_size = p_grid_size
    AND is_published = TRUE
  LIMIT 1;

  IF v_puzzle_id IS NOT NULL THEN
    RETURN v_puzzle_id;
  END IF;

  PERFORM public.ensure_club_relationship_graph(50);

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

    IF EXISTS (
      SELECT 1 FROM puzzles
      WHERE puzzle_hash = v_hash
        OR (puzzle_date = p_puzzle_date AND mode = 'daily' AND grid_size = p_grid_size)
    ) THEN
      CONTINUE;
    END IF;

    v_avg := v_avg / v_cells;

    INSERT INTO puzzles (
      puzzle_date, mode, grid_size, difficulty, difficulty_tier,
      puzzle_hash, quality_score, human_simulation_score, quality_metrics, is_published
    )
    VALUES (
      p_puzzle_date, 'daily'::puzzle_mode, p_grid_size, v_avg, 'medium',
      v_hash, 50, 50,
      jsonb_build_object('daily_fast', TRUE, 'min_answers', p_min_answers),
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

        INSERT INTO puzzle_cells (puzzle_id, row_index, col_index, valid_answer_count, difficulty)
        VALUES (v_puzzle_id, v_r, v_c, v_rel.valid_player_count, v_rel.difficulty_score);
      END LOOP;
    END LOOP;

    RETURN v_puzzle_id;
  END LOOP;

  RAISE EXCEPTION 'generate_daily_puzzle_fast failed after % attempts (min_answers=%)',
    p_max_attempts, p_min_answers;
END;
$$;

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
    'legend',
    'medium',
    'hard',
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

  FOREACH v_tier IN ARRAY v_tiers LOOP
    BEGIN
      RETURN public.generate_puzzle(
        'daily'::puzzle_mode,
        3::SMALLINT,
        v_tier,
        p_date,
        100
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

  BEGIN
    RETURN public.generate_daily_puzzle_fast(p_date, 3, 3, 200);
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
    RETURN public.generate_daily_puzzle_fast(p_date, 3, 1, 300);
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

  RAISE EXCEPTION 'ensure_daily_puzzle FAILED (pairs=%): %',
    v_pairs, COALESCE(v_err, 'no tier succeeded');
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_club_relationship_graph(INT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_daily_puzzle_fast(DATE, SMALLINT, INT, INT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.ensure_daily_puzzle(DATE, TEXT) TO authenticated, service_role;
