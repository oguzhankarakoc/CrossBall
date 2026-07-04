-- Optimized coordinated club picking (top-N brute force) + daily quality fallback.

CREATE OR REPLACE FUNCTION public.find_col_clubs_for_rows(
  p_row_ids UUID[],
  p_grid_size SMALLINT,
  p_min_answers INT,
  p_recent_club_ids UUID[] DEFAULT NULL
)
RETURNS UUID[]
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT ARRAY_AGG(sub.id ORDER BY sub.id)
  FROM (
    SELECT c.id
    FROM clubs c
    JOIN (
      SELECT
        CASE
          WHEN cr.club_a_id = ANY(p_row_ids) THEN cr.club_b_id
          ELSE cr.club_a_id
        END AS col_id
      FROM club_relationships cr
      WHERE cr.valid_player_count >= p_min_answers
        AND (cr.club_a_id = ANY(p_row_ids) OR cr.club_b_id = ANY(p_row_ids))
      GROUP BY 1
      HAVING COUNT(DISTINCT CASE
        WHEN cr.club_a_id = ANY(p_row_ids) THEN cr.club_a_id
        ELSE cr.club_b_id
      END) = p_grid_size
    ) eligible ON eligible.col_id = c.id
    WHERE c.is_top_club = TRUE
      AND NOT (c.id = ANY(p_row_ids))
    ORDER BY -LN(GREATEST(random(), 1e-9)) / (
      CASE
        WHEN p_recent_club_ids IS NOT NULL AND c.id = ANY(p_recent_club_ids) THEN 0.35
        ELSE 2.0
      END
    )
    LIMIT p_grid_size
  ) sub;
$$;

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
  v_top_ids UUID[];
  v_rids UUID[];
  v_cids UUID[];
  v_i INT;
  v_j INT;
  v_k INT;
  v_l INT;
  v_n INT;
BEGIN
  IF p_grid_size NOT IN (3, 4) THEN
    RETURN;
  END IF;

  SELECT ARRAY_AGG(top12.id ORDER BY top12.reach DESC, top12.id)
  INTO v_top_ids
  FROM (
    SELECT sub.id, sub.reach
    FROM (
      SELECT
        c.id,
        (
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
        ) AS reach
      FROM clubs c
      WHERE c.is_top_club = TRUE
    ) sub
    WHERE sub.reach >= p_grid_size
    ORDER BY sub.reach DESC, sub.id
    LIMIT 12
  ) top12;

  IF v_top_ids IS NULL THEN
    RETURN;
  END IF;

  v_top_ids := (
    SELECT ARRAY_AGG(x ORDER BY -LN(GREATEST(random(), 1e-9)) / (
      CASE
        WHEN p_recent_club_ids IS NOT NULL AND x = ANY(p_recent_club_ids) THEN 0.35
        ELSE 2.0
      END
    ))
    FROM unnest(v_top_ids) AS t(x)
  );

  v_n := array_length(v_top_ids, 1);
  IF v_n IS NULL OR v_n < (p_grid_size * 2) THEN
    RETURN;
  END IF;

  IF p_grid_size = 3 THEN
    FOR v_i IN 1..(v_n - 2) LOOP
      FOR v_j IN (v_i + 1)..(v_n - 1) LOOP
        FOR v_k IN (v_j + 1)..v_n LOOP
          v_rids := ARRAY[v_top_ids[v_i], v_top_ids[v_j], v_top_ids[v_k]];
          v_cids := public.find_col_clubs_for_rows(
            v_rids, p_grid_size, p_min_answers, p_recent_club_ids
          );

          IF v_cids IS NOT NULL AND array_length(v_cids, 1) = p_grid_size THEN
            row_ids := v_rids;
            col_ids := v_cids;
            RETURN NEXT;
            RETURN;
          END IF;
        END LOOP;
      END LOOP;
    END LOOP;
  ELSE
    FOR v_i IN 1..(v_n - 3) LOOP
      FOR v_j IN (v_i + 1)..(v_n - 2) LOOP
        FOR v_k IN (v_j + 1)..(v_n - 1) LOOP
          FOR v_l IN (v_k + 1)..v_n LOOP
            v_rids := ARRAY[
              v_top_ids[v_i],
              v_top_ids[v_j],
              v_top_ids[v_k],
              v_top_ids[v_l]
            ];
            v_cids := public.find_col_clubs_for_rows(
              v_rids, p_grid_size, p_min_answers, p_recent_club_ids
            );

            IF v_cids IS NOT NULL AND array_length(v_cids, 1) = p_grid_size THEN
              row_ids := v_rids;
              col_ids := v_cids;
              RETURN NEXT;
              RETURN;
            END IF;
          END LOOP;
        END LOOP;
      END LOOP;
    END LOOP;
  END IF;
END;
$$;

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
  v_best_quality INT := -1;
  v_best_human INT := -1;
  v_best_eval JSONB;
  v_best_row UUID[];
  v_best_col UUID[];
  v_best_avg NUMERIC;
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
      EXIT;
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

    IF v_quality > v_best_quality
       OR (v_quality = v_best_quality AND v_human > v_best_human) THEN
      v_best_quality := v_quality;
      v_best_human := v_human;
      v_best_eval := v_eval;
      v_best_row := v_row_ids;
      v_best_col := v_col_ids;
      v_best_avg := v_avg_difficulty;
    END IF;

    IF NOT COALESCE((v_eval->>'passed')::BOOLEAN, FALSE) THEN
      v_rejected := v_rejected + 1;
      CONTINUE;
    END IF;

    INSERT INTO puzzles (
      puzzle_date, mode, grid_size, difficulty, difficulty_tier,
      puzzle_hash, quality_score, human_simulation_score, quality_metrics, is_published
    )
    VALUES (
      COALESCE(p_puzzle_date, CASE WHEN p_mode = 'daily' THEN CURRENT_DATE ELSE NULL END),
      p_mode, p_grid_size, v_avg_difficulty, lower(trim(p_difficulty_tier)),
      v_hash, v_quality, v_human, v_eval, TRUE
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

    RAISE NOTICE 'Published puzzle % (quality=%, human=%, attempts=%, rejected=%)',
      v_puzzle_id, v_quality, v_human, v_attempt, v_rejected;

    RETURN v_puzzle_id;
  END LOOP;

  IF p_mode = 'daily'
     AND v_best_row IS NOT NULL
     AND v_best_quality >= 60
     AND v_best_human >= 65 THEN
    v_hash := public.compute_puzzle_hash(v_best_row, v_best_col);
    v_eval := COALESCE(v_best_eval, '{}'::JSONB)
      || jsonb_build_object('relaxed_quality_gate', TRUE);

    INSERT INTO puzzles (
      puzzle_date, mode, grid_size, difficulty, difficulty_tier,
      puzzle_hash, quality_score, human_simulation_score, quality_metrics, is_published
    )
    VALUES (
      COALESCE(p_puzzle_date, CURRENT_DATE),
      p_mode, p_grid_size, v_best_avg, lower(trim(p_difficulty_tier)),
      v_hash, v_best_quality, v_best_human, v_eval, TRUE
    )
    RETURNING id INTO v_puzzle_id;

    FOR v_r IN 0..(p_grid_size - 1) LOOP
      INSERT INTO puzzle_row_clubs (puzzle_id, row_index, club_id)
      VALUES (v_puzzle_id, v_r, v_best_row[v_r + 1]);
    END LOOP;

    FOR v_c IN 0..(p_grid_size - 1) LOOP
      INSERT INTO puzzle_col_clubs (puzzle_id, col_index, club_id)
      VALUES (v_puzzle_id, v_c, v_best_col[v_c + 1]);
    END LOOP;

    FOR v_r IN 0..(p_grid_size - 1) LOOP
      FOR v_c IN 0..(p_grid_size - 1) LOOP
        SELECT * INTO v_rel
        FROM public.get_club_relationship(v_best_row[v_r + 1], v_best_col[v_c + 1]);

        INSERT INTO puzzle_cells (puzzle_id, row_index, col_index, valid_answer_count, difficulty)
        VALUES (v_puzzle_id, v_r, v_c, v_rel.valid_player_count, v_rel.difficulty_score);
      END LOOP;
    END LOOP;

    RAISE NOTICE 'Published daily puzzle % with relaxed quality (quality=%, human=%)',
      v_puzzle_id, v_best_quality, v_best_human;

    RETURN v_puzzle_id;
  END IF;

  RAISE EXCEPTION 'Failed to generate quality puzzle after % attempts (% rejected by quality gate)',
    p_max_attempts, v_rejected;
END;
$$;

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
    'medium'
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
        250
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

GRANT EXECUTE ON FUNCTION public.find_col_clubs_for_rows(UUID[], SMALLINT, INT, UUID[]) TO authenticated;
