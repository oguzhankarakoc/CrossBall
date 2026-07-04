-- Puzzle Generation Engine: club relationship graph, puzzle hash, generation RPCs.

-- =============================================================================
-- ENUM extensions for hints
-- =============================================================================

DO $$ BEGIN
  ALTER TYPE hint_type ADD VALUE IF NOT EXISTS 'career_league';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TYPE hint_type ADD VALUE IF NOT EXISTS 'retired_status';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TYPE hint_type ADD VALUE IF NOT EXISTS 'career_club';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =============================================================================
-- CLUB RELATIONSHIP GRAPH (precomputed, refreshed on ETL)
-- =============================================================================

CREATE TABLE IF NOT EXISTS club_relationships (
  club_a_id           UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  club_b_id           UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  valid_player_count  INT NOT NULL CHECK (valid_player_count >= 1),
  player_ids          UUID[] NOT NULL DEFAULT '{}',
  difficulty_score    NUMERIC(4,2) NOT NULL DEFAULT 0.5,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (club_a_id, club_b_id),
  CHECK (club_a_id < club_b_id)
);

CREATE INDEX IF NOT EXISTS idx_club_relationships_count
  ON club_relationships (valid_player_count DESC);
CREATE INDEX IF NOT EXISTS idx_club_relationships_clubs
  ON club_relationships (club_a_id, club_b_id);

-- =============================================================================
-- PUZZLE METADATA
-- =============================================================================

ALTER TABLE puzzles
  ADD COLUMN IF NOT EXISTS puzzle_hash TEXT,
  ADD COLUMN IF NOT EXISTS difficulty_tier TEXT DEFAULT 'medium';

CREATE UNIQUE INDEX IF NOT EXISTS idx_puzzles_hash ON puzzles (puzzle_hash)
  WHERE puzzle_hash IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_puzzles_hash_recent
  ON puzzles (created_at DESC)
  WHERE puzzle_hash IS NOT NULL;

-- =============================================================================
-- PRACTICE HISTORY (per user, no recent repeats)
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_practice_history (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_uuid   TEXT NOT NULL,
  puzzle_id   UUID NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
  played_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_practice_history_user
  ON user_practice_history (user_uuid, played_at DESC);

-- =============================================================================
-- HELPERS
-- =============================================================================

CREATE OR REPLACE FUNCTION public.tier_min_answers(p_tier TEXT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE lower(trim(p_tier))
    WHEN 'easy' THEN 15
    WHEN 'medium' THEN 8
    WHEN 'hard' THEN 5
    WHEN 'legend' THEN 3
    ELSE 8
  END;
$$;

CREATE OR REPLACE FUNCTION public.relationship_difficulty_score(p_count INT)
RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT GREATEST(0.05, LEAST(1.0, 1.0 - (p_count::NUMERIC / 20.0)));
$$;

CREATE OR REPLACE FUNCTION public.compute_puzzle_hash(
  p_row_club_ids UUID[],
  p_col_club_ids UUID[]
)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT md5(
    COALESCE(
      (
        SELECT string_agg(x::TEXT, '|' ORDER BY x)
        FROM unnest(p_row_club_ids || p_col_club_ids) AS x
      ),
      ''
    )
  );
$$;

CREATE OR REPLACE FUNCTION public.get_club_relationship(
  p_club_x UUID,
  p_club_y UUID
)
RETURNS club_relationships
LANGUAGE sql
STABLE
AS $$
  SELECT cr.*
  FROM club_relationships cr
  WHERE cr.club_a_id = LEAST(p_club_x, p_club_y)
    AND cr.club_b_id = GREATEST(p_club_x, p_club_y);
$$;

-- =============================================================================
-- STEP 1 & 2: Refresh club relationship graph
-- =============================================================================

CREATE OR REPLACE FUNCTION public.refresh_club_relationships()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  TRUNCATE club_relationships;

  INSERT INTO club_relationships (
    club_a_id,
    club_b_id,
    valid_player_count,
    player_ids,
    difficulty_score
  )
  SELECT
    LEAST(pch1.club_id, pch2.club_id),
    GREATEST(pch1.club_id, pch2.club_id),
    COUNT(DISTINCT pch1.player_id)::INT,
    ARRAY_AGG(DISTINCT pch1.player_id ORDER BY pch1.player_id),
    public.relationship_difficulty_score(COUNT(DISTINCT pch1.player_id)::INT)
  FROM player_career_history pch1
  JOIN player_career_history pch2
    ON pch1.player_id = pch2.player_id
   AND pch1.club_id <> pch2.club_id
  WHERE pch1.is_senior = TRUE AND pch1.is_youth = FALSE AND pch1.is_reserve = FALSE
    AND pch2.is_senior = TRUE AND pch2.is_youth = FALSE AND pch2.is_reserve = FALSE
  GROUP BY LEAST(pch1.club_id, pch2.club_id), GREATEST(pch1.club_id, pch2.club_id)
  HAVING COUNT(DISTINCT pch1.player_id) >= 3;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- =============================================================================
-- STEP 3–6: Generate puzzle from relationships
-- =============================================================================

CREATE OR REPLACE FUNCTION public.generate_puzzle(
  p_mode puzzle_mode DEFAULT 'daily',
  p_grid_size SMALLINT DEFAULT 3,
  p_difficulty_tier TEXT DEFAULT 'medium',
  p_puzzle_date DATE DEFAULT NULL,
  p_max_attempts INT DEFAULT 500
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
BEGIN
  IF p_grid_size NOT IN (3, 4) THEN
    RAISE EXCEPTION 'grid_size must be 3 or 4';
  END IF;

  SELECT ARRAY_AGG(puzzle_hash)
  INTO v_recent_hashes
  FROM puzzles
  WHERE puzzle_hash IS NOT NULL
    AND created_at > NOW() - INTERVAL '30 days';

  WHILE v_attempt < p_max_attempts LOOP
    v_attempt := v_attempt + 1;

    -- Weighted random: prefer clubs not used in recent puzzles
    WITH recent_clubs AS (
      SELECT DISTINCT prc.club_id AS id
      FROM puzzle_row_clubs prc
      JOIN puzzles p ON p.id = prc.puzzle_id
      WHERE p.created_at > NOW() - INTERVAL '14 days'
      UNION
      SELECT DISTINCT pcc.club_id
      FROM puzzle_col_clubs pcc
      JOIN puzzles p ON p.id = pcc.puzzle_id
      WHERE p.created_at > NOW() - INTERVAL '14 days'
    ),
    weighted AS (
      SELECT
        c.id,
        CASE WHEN rc.id IS NULL THEN 2.0 ELSE 0.35 END AS weight
      FROM clubs c
      LEFT JOIN recent_clubs rc ON rc.id = c.id
      WHERE c.is_top_club = TRUE
    ),
    row_picked AS (
      SELECT id
      FROM weighted
      ORDER BY -LN(GREATEST(random(), 1e-9)) / weight
      LIMIT p_grid_size
    ),
    col_picked AS (
      SELECT w.id
      FROM weighted w
      WHERE w.id NOT IN (SELECT id FROM row_picked)
      ORDER BY -LN(GREATEST(random(), 1e-9)) / w.weight
      LIMIT p_grid_size
    )
    SELECT
      (SELECT ARRAY_AGG(id ORDER BY id) FROM row_picked),
      (SELECT ARRAY_AGG(id ORDER BY id) FROM col_picked)
    INTO v_row_ids, v_col_ids;

    IF v_row_ids IS NULL OR v_col_ids IS NULL
       OR array_length(v_row_ids, 1) <> p_grid_size
       OR array_length(v_col_ids, 1) <> p_grid_size THEN
      CONTINUE;
    END IF;

    -- Row and column clubs must be disjoint
    IF v_row_ids && v_col_ids THEN
      CONTINUE;
    END IF;

    v_hash := public.compute_puzzle_hash(v_row_ids, v_col_ids);

    IF v_hash = ANY(COALESCE(v_recent_hashes, ARRAY[]::TEXT[])) THEN
      CONTINUE;
    END IF;

    -- Validate every cell
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

    INSERT INTO puzzles (
      puzzle_date,
      mode,
      grid_size,
      difficulty,
      difficulty_tier,
      puzzle_hash,
      is_published
    )
    VALUES (
      COALESCE(p_puzzle_date, CASE WHEN p_mode = 'daily' THEN CURRENT_DATE ELSE NULL END),
      p_mode,
      p_grid_size,
      v_avg_difficulty,
      lower(trim(p_difficulty_tier)),
      v_hash,
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

    RETURN v_puzzle_id;
  END LOOP;

  RAISE EXCEPTION 'Failed to generate puzzle after % attempts', p_max_attempts;
END;
$$;

-- =============================================================================
-- STEP 7: Daily challenge
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

  BEGIN
    RETURN public.generate_puzzle('daily'::puzzle_mode, 3::SMALLINT, p_difficulty_tier, p_date);
  EXCEPTION WHEN unique_violation THEN
    SELECT id INTO v_id
    FROM puzzles
    WHERE puzzle_date = p_date AND mode = 'daily' AND grid_size = 3
    LIMIT 1;
    RETURN v_id;
  END;
END;
$$;

-- =============================================================================
-- STEP 8: Practice mode (weighted, no recent repeats)
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
BEGIN
  SELECT ARRAY_AGG(DISTINCT puzzle_id)
  INTO v_recent_ids
  FROM user_practice_history
  WHERE user_uuid = p_user_uuid
    AND played_at > NOW() - (p_lookback_days || ' days')::INTERVAL;

  SELECT p.id INTO v_puzzle_id
  FROM puzzles p
  WHERE p.mode = 'practice'
    AND p.grid_size = p_grid_size
    AND p.is_published = TRUE
    AND (v_recent_ids IS NULL OR NOT (p.id = ANY(v_recent_ids)))
  ORDER BY -LN(GREATEST(random(), 1e-9)) / (1.0 + COALESCE((
    SELECT COUNT(*)::NUMERIC FROM user_practice_history h WHERE h.puzzle_id = p.id
  ), 0))
  LIMIT 1;

  IF v_puzzle_id IS NULL THEN
    v_puzzle_id := public.generate_puzzle('practice'::puzzle_mode, p_grid_size, p_difficulty_tier, NULL::DATE);
  END IF;

  INSERT INTO user_practice_history (user_uuid, puzzle_id)
  VALUES (p_user_uuid, v_puzzle_id);

  RETURN v_puzzle_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_practice_puzzle(
  p_user_uuid TEXT,
  p_puzzle_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO user_practice_history (user_uuid, puzzle_id)
  VALUES (p_user_uuid, p_puzzle_id);
END;
$$;

-- =============================================================================
-- Grants
-- =============================================================================

GRANT SELECT ON club_relationships TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_club_relationships() TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_daily_puzzle(DATE, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.select_practice_puzzle(TEXT, SMALLINT, TEXT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.generate_puzzle(puzzle_mode, SMALLINT, TEXT, DATE, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.compute_puzzle_hash(UUID[], UUID[]) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_club_relationship(UUID, UUID) TO anon, authenticated;

-- Initial relationship build from existing career data
SELECT public.refresh_club_relationships();

-- Optional: seed today's daily if graph has data (non-fatal)
DO $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_existing UUID;
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM club_relationships;
  IF v_count = 0 THEN
    RAISE NOTICE 'No club relationships yet — run ETL first';
    RETURN;
  END IF;

  SELECT id INTO v_existing
  FROM puzzles
  WHERE puzzle_date = v_today AND mode = 'daily' AND grid_size = 3;

  IF v_existing IS NOT NULL AND (
    SELECT puzzle_hash IS NULL FROM puzzles WHERE id = v_existing
  ) THEN
    DELETE FROM puzzle_cells WHERE puzzle_id = v_existing;
    DELETE FROM puzzle_row_clubs WHERE puzzle_id = v_existing;
    DELETE FROM puzzle_col_clubs WHERE puzzle_id = v_existing;
    DELETE FROM puzzles WHERE id = v_existing;
  END IF;

  BEGIN
    PERFORM public.ensure_daily_puzzle(v_today, 'medium');
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Daily puzzle auto-seed skipped: %', SQLERRM;
  END;
END;
$$;
