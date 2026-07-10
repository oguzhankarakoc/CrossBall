-- Fix generate_daily_puzzle_fast: setseed() expects double precision, not text.

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
  v_recent_hashes TEXT[];
  v_recent_club_ids UUID[];
  v_seed DOUBLE PRECISION;
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
    WHERE p.mode = 'daily'
      AND p.created_at > NOW() - INTERVAL '14 days'
    UNION
    SELECT pcc.club_id
    FROM puzzle_col_clubs pcc
    JOIN puzzles p ON p.id = pcc.puzzle_id
    WHERE p.mode = 'daily'
      AND p.created_at > NOW() - INTERVAL '14 days'
  ) recent;

  v_seed := (
    ('x' || substr(md5(p_puzzle_date::TEXT || ':daily_fast'), 1, 8))::bit(32)::bigint::double precision
  ) / 4294967295.0;
  PERFORM setseed(v_seed);

  WHILE v_attempt < p_max_attempts LOOP
    v_attempt := v_attempt + 1;

    SELECT p.row_ids, p.col_ids
    INTO v_row_ids, v_col_ids
    FROM public.pick_valid_puzzle_clubs(p_grid_size, p_min_answers, v_recent_club_ids) p
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

    IF v_hash = ANY(COALESCE(v_recent_hashes, ARRAY[]::TEXT[])) THEN
      CONTINUE;
    END IF;

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
