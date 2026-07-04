-- Puzzle Quality Evaluation System — extends Puzzle Intelligence Engine (009).
-- Candidates must pass quality >= 85 AND human_simulation >= 90 before publish.

ALTER TABLE puzzles
  ADD COLUMN IF NOT EXISTS quality_score SMALLINT
    CHECK (quality_score IS NULL OR (quality_score >= 0 AND quality_score <= 100)),
  ADD COLUMN IF NOT EXISTS human_simulation_score SMALLINT
    CHECK (human_simulation_score IS NULL OR (human_simulation_score >= 0 AND human_simulation_score <= 100)),
  ADD COLUMN IF NOT EXISTS quality_metrics JSONB;

CREATE INDEX IF NOT EXISTS idx_puzzles_quality
  ON puzzles (quality_score DESC, human_simulation_score DESC)
  WHERE is_published = TRUE;

-- =============================================================================
-- Scoring helpers
-- =============================================================================

CREATE OR REPLACE FUNCTION public.clamp_score(p_value NUMERIC)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT GREATEST(0, LEAST(100, ROUND(p_value)::INT));
$$;

CREATE OR REPLACE FUNCTION public.puzzle_quality_threshold()
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$ SELECT 85; $$;

CREATE OR REPLACE FUNCTION public.puzzle_human_threshold()
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$ SELECT 90; $$;

-- Bell-curve score: peaks at p_ideal, decays with distance
CREATE OR REPLACE FUNCTION public.bell_score(
  p_value NUMERIC,
  p_ideal NUMERIC,
  p_width NUMERIC DEFAULT 3.0
)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT public.clamp_score(100 - (ABS(p_value - p_ideal) / GREATEST(p_width, 0.1)) * 25);
$$;

-- =============================================================================
-- Evaluate a candidate grid (does NOT persist)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.evaluate_puzzle_candidate(
  p_row_ids UUID[],
  p_col_ids UUID[],
  p_grid_size SMALLINT,
  p_min_answers INT DEFAULT 8
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_r INT;
  v_c INT;
  v_rel club_relationships%ROWTYPE;
  v_counts INT[] := '{}';
  v_diffs NUMERIC[] := '{}';
  v_all_player_ids UUID[] := '{}';
  v_cell_player_ids UUID[];
  v_count INT;
  v_avg NUMERIC;
  v_stddev NUMERIC;
  v_cv NUMERIC;
  v_min_count INT;
  v_max_count INT;
  v_club_ids UUID[];
  v_league_count INT;
  v_country_count INT;
  v_pop_mean NUMERIC;
  v_pop_std NUMERIC;
  v_rare_cells INT := 0;
  v_sweet_cells INT := 0;
  v_recent_club_usage INT := 0;
  v_recent_pair_usage INT := 0;
  v_row_difficulty NUMERIC[] := '{}';
  v_col_difficulty NUMERIC[] := '{}';
  v_row_sum NUMERIC;
  v_col_sum NUMERIC;
  v_quadrant_diffs NUMERIC[] := '{}';
  v_q INT;
  -- Component scores (quality, weights sum to 100)
  v_s_avg_answers INT;
  v_s_consistency INT;
  v_s_club_div INT;
  v_s_league_div INT;
  v_s_country_div INT;
  v_s_pop_variety INT;
  v_s_rare_opp INT;
  v_s_freshness INT;
  v_s_replay INT;
  v_s_visual INT;
  v_s_avoid_clubs INT;
  v_s_avoid_pairs INT;
  v_quality INT;
  -- Human simulation components (weights sum to 100)
  v_h_enjoy INT;
  v_h_not_easy INT;
  v_h_not_hard INT;
  v_h_knowledge INT;
  v_h_aha INT;
  v_h_rare INT;
  v_h_handcrafted INT;
  v_human INT;
  v_total_cells INT;
  v_fresh_clubs INT;
  v_fresh_pairs INT;
  v_pair_key TEXT;
BEGIN
  v_total_cells := p_grid_size * p_grid_size;
  v_club_ids := p_row_ids || p_col_ids;

  -- Collect per-cell metrics
  FOR v_r IN 0..(p_grid_size - 1) LOOP
    v_row_difficulty := array_append(v_row_difficulty, 0);
    FOR v_c IN 0..(p_grid_size - 1) LOOP
      IF v_r = 0 THEN
        v_col_difficulty := array_append(v_col_difficulty, 0);
      END IF;

      SELECT * INTO v_rel
      FROM public.get_club_relationship(p_row_ids[v_r + 1], p_col_ids[v_c + 1]);

      IF v_rel IS NULL THEN
        RETURN jsonb_build_object(
          'quality_score', 0,
          'human_simulation_score', 0,
          'passed', FALSE,
          'reason', 'missing_relationship'
        );
      END IF;

      v_counts := array_append(v_counts, v_rel.valid_player_count);
      v_diffs := array_append(v_diffs, v_rel.difficulty_score);
      v_row_difficulty[v_r + 1] := v_row_difficulty[v_r + 1] + v_rel.difficulty_score;
      v_col_difficulty[v_c + 1] := v_col_difficulty[v_c + 1] + v_rel.difficulty_score;
      v_all_player_ids := v_all_player_ids || v_rel.player_ids;
    END LOOP;
  END LOOP;

  SELECT AVG(x)::NUMERIC, STDDEV_POP(x)::NUMERIC, MIN(x), MAX(x)
  INTO v_avg, v_stddev, v_min_count, v_max_count
  FROM unnest(v_counts) AS x;

  v_cv := CASE WHEN v_avg > 0 THEN COALESCE(v_stddev, 0) / v_avg ELSE 1 END;

  -- League & country diversity from selected clubs
  SELECT COUNT(DISTINCT NULLIF(TRIM(league_name), '')),
         COUNT(DISTINCT NULLIF(TRIM(country_code), ''))
  INTO v_league_count, v_country_count
  FROM clubs
  WHERE id = ANY(v_club_ids);

  -- Popularity spread across all intersection players
  SELECT AVG(COALESCE(pp.global_selection_count, 0))::NUMERIC,
         STDDEV_POP(COALESCE(pp.global_selection_count, 0))::NUMERIC
  INTO v_pop_mean, v_pop_std
  FROM unnest(v_all_player_ids) AS pid(player_id)
  LEFT JOIN player_popularity pp ON pp.player_id = pid.player_id;

  -- Rare opportunity & sweet-spot cells
  FOR v_r IN 0..(p_grid_size - 1) LOOP
    FOR v_c IN 0..(p_grid_size - 1) LOOP
      SELECT * INTO v_rel
      FROM public.get_club_relationship(p_row_ids[v_r + 1], p_col_ids[v_c + 1]);

      SELECT COUNT(*) INTO v_count
      FROM unnest(v_rel.player_ids) AS pid(player_id)
      LEFT JOIN player_popularity pp ON pp.player_id = pid.player_id
      WHERE COALESCE(pp.global_selection_count, 0) <= GREATEST(v_pop_mean * 0.25, 1);

      IF v_count::NUMERIC / GREATEST(v_rel.valid_player_count, 1) >= 0.2 THEN
        v_rare_cells := v_rare_cells + 1;
      END IF;

      IF v_rel.valid_player_count BETWEEN 5 AND 14 THEN
        v_sweet_cells := v_sweet_cells + 1;
      END IF;
    END LOOP;
  END LOOP;

  -- Freshness: clubs not in recent puzzles
  SELECT COUNT(*) INTO v_recent_club_usage
  FROM unnest(v_club_ids) AS cid(club_id)
  WHERE cid.club_id IN (
    SELECT prc.club_id FROM puzzle_row_clubs prc
    JOIN puzzles p ON p.id = prc.puzzle_id
    WHERE p.created_at > NOW() - INTERVAL '14 days'
    UNION
    SELECT pcc.club_id FROM puzzle_col_clubs pcc
    JOIN puzzles p ON p.id = pcc.puzzle_id
    WHERE p.created_at > NOW() - INTERVAL '14 days'
  );

  v_fresh_clubs := cardinality(v_club_ids) - v_recent_club_usage;

  -- Recent pair usage across cells
  v_recent_pair_usage := 0;
  FOR v_r IN 0..(p_grid_size - 1) LOOP
    FOR v_c IN 0..(p_grid_size - 1) LOOP
      v_pair_key := LEAST(p_row_ids[v_r + 1], p_col_ids[v_c + 1])::TEXT
                 || ':' || GREATEST(p_row_ids[v_r + 1], p_col_ids[v_c + 1])::TEXT;
      IF EXISTS (
        SELECT 1
        FROM puzzle_cells pc
        JOIN puzzles p ON p.id = pc.puzzle_id
        JOIN puzzle_row_clubs pr ON pr.puzzle_id = p.id AND pr.row_index = pc.row_index
        JOIN puzzle_col_clubs pc2 ON pc2.puzzle_id = p.id AND pc2.col_index = pc.col_index
        WHERE p.created_at > NOW() - INTERVAL '30 days'
          AND LEAST(pr.club_id, pc2.club_id)::TEXT || ':' || GREATEST(pr.club_id, pc2.club_id)::TEXT = v_pair_key
      ) THEN
        v_recent_pair_usage := v_recent_pair_usage + 1;
      END IF;
    END LOOP;
  END LOOP;

  v_fresh_pairs := v_total_cells - v_recent_pair_usage;

  -- =====================================================================
  -- PUZZLE QUALITY SCORE (weighted components)
  -- =====================================================================

  -- 1. Average valid answers (weight 12) — ideal 9-12
  v_s_avg_answers := public.bell_score(v_avg, 10.5, 4.0);

  -- 2. Difficulty consistency (weight 10) — low CV is better
  v_s_consistency := public.clamp_score(100 - v_cv * 120);

  -- 3. Club diversity (weight 8) — all distinct
  v_s_club_div := CASE
    WHEN cardinality(v_club_ids) = cardinality(ARRAY(SELECT DISTINCT unnest(v_club_ids)))
    THEN 100 ELSE 40
  END;

  -- 4. League diversity (weight 10)
  v_s_league_div := public.clamp_score((v_league_count::NUMERIC / GREATEST(cardinality(v_club_ids), 1)) * 115);

  -- 5. Country diversity (weight 8)
  v_s_country_div := public.clamp_score((v_country_count::NUMERIC / GREATEST(cardinality(v_club_ids), 1)) * 110);

  -- 6. Popularity variety (weight 10)
  v_s_pop_variety := public.clamp_score(
    CASE WHEN v_pop_mean > 0 THEN LEAST(100, (COALESCE(v_pop_std, 0) / v_pop_mean) * 200) ELSE 70 END
  );

  -- 7. Rare player opportunity (weight 10)
  v_s_rare_opp := public.clamp_score((v_rare_cells::NUMERIC / v_total_cells) * 110);

  -- 8. Freshness (weight 10)
  v_s_freshness := public.clamp_score(
    ((v_fresh_clubs::NUMERIC / GREATEST(cardinality(v_club_ids), 1)) * 50)
    + ((v_fresh_pairs::NUMERIC / v_total_cells) * 50)
  );

  -- 9. Replay value (weight 8) — mix of easy/hard cells
  v_s_replay := public.clamp_score(
    CASE WHEN v_max_count - v_min_count >= 3 THEN 85 + LEAST(15, v_max_count - v_min_count)
         ELSE 50 END
  );

  -- 10. Visual balance (weight 8) — row/col difficulty balance
  SELECT GREATEST(
    COALESCE((SELECT STDDEV_POP(x) FROM unnest(v_row_difficulty) AS t(x)), 0),
    COALESCE((SELECT STDDEV_POP(x) FROM unnest(v_col_difficulty) AS t(x)), 0)
  ) INTO v_stddev;

  v_s_visual := public.clamp_score(100 - COALESCE(v_stddev, 0) * 80);

  -- 11. Avoid overused clubs (weight 8)
  v_s_avoid_clubs := public.clamp_score(100 - (v_recent_club_usage::NUMERIC / GREATEST(cardinality(v_club_ids), 1)) * 100);

  -- 12. Avoid overused pairs (weight 8)
  v_s_avoid_pairs := public.clamp_score(100 - (v_recent_pair_usage::NUMERIC / v_total_cells) * 100);

  v_quality := public.clamp_score(
    v_s_avg_answers * 0.12
    + v_s_consistency * 0.10
    + v_s_club_div * 0.08
    + v_s_league_div * 0.10
    + v_s_country_div * 0.08
    + v_s_pop_variety * 0.10
    + v_s_rare_opp * 0.10
    + v_s_freshness * 0.10
    + v_s_replay * 0.08
    + v_s_visual * 0.08
    + v_s_avoid_clubs * 0.08
    + v_s_avoid_pairs * 0.08
  );

  -- =====================================================================
  -- HUMAN SIMULATION SCORE
  -- =====================================================================

  -- Enjoyable: balanced avg, moderate variance
  v_h_enjoy := public.clamp_score(
    (public.bell_score(v_avg, 10, 3) * 0.6)
    + (public.clamp_score(100 - ABS(v_cv - 0.35) * 150) * 0.4)
  );

  -- Not too easy
  v_h_not_easy := public.clamp_score(
    CASE WHEN v_avg > 18 THEN 100 - (v_avg - 18) * 8
         WHEN v_avg > 14 THEN 85
         ELSE 100 END
  );

  -- Not frustratingly difficult
  v_h_not_hard := public.clamp_score(
    CASE WHEN v_min_count <= p_min_answers THEN 55
         WHEN v_min_count <= p_min_answers + 2 THEN 75
         ELSE 95 END
    + CASE WHEN v_min_count >= 5 THEN 5 ELSE 0 END
  );

  -- Rewards football knowledge — mix of popular and obscure available
  v_h_knowledge := public.clamp_score(
    (v_s_pop_variety * 0.4) + (v_s_league_div * 0.3) + (v_s_country_div * 0.3)
  );

  -- "I know this player!" moments — sweet spot cells
  v_h_aha := public.clamp_score((v_sweet_cells::NUMERIC / v_total_cells) * 105);

  -- Encourages rare discoveries
  v_h_rare := public.clamp_score((v_rare_cells::NUMERIC / v_total_cells) * 110);

  -- Handcrafted feel — diversity + freshness + consistency sweet spot
  v_h_handcrafted := public.clamp_score(
    (v_s_league_div * 0.25)
    + (v_s_country_div * 0.20)
    + (v_s_freshness * 0.25)
    + (v_s_avoid_pairs * 0.15)
    + (public.bell_score(v_cv, 0.30, 0.20) * 0.15)
  );

  v_human := public.clamp_score(
    v_h_enjoy * 0.15
    + v_h_not_easy * 0.15
    + v_h_not_hard * 0.15
    + v_h_knowledge * 0.15
    + v_h_aha * 0.15
    + v_h_rare * 0.10
    + v_h_handcrafted * 0.15
  );

  RETURN jsonb_build_object(
    'quality_score', v_quality,
    'human_simulation_score', v_human,
    'passed', v_quality >= public.puzzle_quality_threshold()
              AND v_human >= public.puzzle_human_threshold(),
    'quality_threshold', public.puzzle_quality_threshold(),
    'human_threshold', public.puzzle_human_threshold(),
    'metrics', jsonb_build_object(
      'avg_valid_answers', ROUND(v_avg, 2),
      'min_valid_answers', v_min_count,
      'max_valid_answers', v_max_count,
      'difficulty_cv', ROUND(v_cv, 4),
      'league_count', v_league_count,
      'country_count', v_country_count,
      'rare_cells', v_rare_cells,
      'sweet_spot_cells', v_sweet_cells,
      'fresh_clubs', v_fresh_clubs,
      'fresh_pairs', v_fresh_pairs,
      'recent_club_usage', v_recent_club_usage,
      'recent_pair_usage', v_recent_pair_usage
    ),
    'quality_components', jsonb_build_object(
      'avg_answers', v_s_avg_answers,
      'consistency', v_s_consistency,
      'club_diversity', v_s_club_div,
      'league_diversity', v_s_league_div,
      'country_diversity', v_s_country_div,
      'popularity_variety', v_s_pop_variety,
      'rare_opportunity', v_s_rare_opp,
      'freshness', v_s_freshness,
      'replay_value', v_s_replay,
      'visual_balance', v_s_visual,
      'avoid_overused_clubs', v_s_avoid_clubs,
      'avoid_overused_pairs', v_s_avoid_pairs
    ),
    'human_components', jsonb_build_object(
      'enjoyability', v_h_enjoy,
      'not_too_easy', v_h_not_easy,
      'not_frustrating', v_h_not_hard,
      'rewards_knowledge', v_h_knowledge,
      'aha_moments', v_h_aha,
      'rare_discovery', v_h_rare,
      'handcrafted_feel', v_h_handcrafted
    )
  );
END;
$$;

-- =============================================================================
-- Extend generate_puzzle: evaluate before publish, quality over speed
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

  WHILE v_attempt < p_max_attempts LOOP
    v_attempt := v_attempt + 1;

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

    IF v_row_ids && v_col_ids THEN
      CONTINUE;
    END IF;

    v_hash := public.compute_puzzle_hash(v_row_ids, v_col_ids);

    IF v_hash = ANY(COALESCE(v_recent_hashes, ARRAY[]::TEXT[])) THEN
      CONTINUE;
    END IF;

    -- Structural validation: every cell meets tier minimum
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

    -- Quality evaluation gate
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

GRANT EXECUTE ON FUNCTION public.evaluate_puzzle_candidate(UUID[], UUID[], SMALLINT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.clamp_score(NUMERIC) TO anon, authenticated;

-- Fix enum casts on dependent RPCs (009 compatibility)
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
    v_puzzle_id := public.generate_puzzle(
      'practice'::puzzle_mode, p_grid_size, p_difficulty_tier, NULL::DATE
    );
  END IF;

  INSERT INTO user_practice_history (user_uuid, puzzle_id)
  VALUES (p_user_uuid, v_puzzle_id);

  RETURN v_puzzle_id;
END;
$$;
