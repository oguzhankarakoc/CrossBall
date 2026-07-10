-- Stats rarity always-zero + missing player nationality (e.g. Gyökeres).
-- 1) Backfill user_stats rarity counters from correct answers
-- 2) Return common/epic counts from compute_session_score (for live increments)
-- 3) Patch high-visibility nationality gaps

-- =============================================================================
-- 1. Backfill rarity breakdown from historical correct answers
-- =============================================================================

WITH tallies AS (
  SELECT
    ps.user_id,
    COUNT(*) FILTER (WHERE COALESCE(a.rarity_tier::TEXT, 'common') = 'common')::INT AS common_count,
    COUNT(*) FILTER (WHERE a.rarity_tier::TEXT = 'rare')::INT AS rare_count,
    COUNT(*) FILTER (WHERE a.rarity_tier::TEXT = 'epic')::INT AS epic_count,
    COUNT(*) FILTER (WHERE a.rarity_tier::TEXT = 'legendary')::INT AS legendary_count,
    COUNT(*) FILTER (WHERE a.rarity_tier::TEXT = 'mythic')::INT AS mythic_count
  FROM public.answers a
  JOIN public.puzzle_sessions ps ON ps.id = a.session_id
  WHERE a.is_correct = TRUE
    AND ps.user_id IS NOT NULL
  GROUP BY ps.user_id
)
UPDATE public.user_stats us
SET
  common_count = tallies.common_count,
  rare_count = tallies.rare_count,
  epic_count = tallies.epic_count,
  legendary_count = tallies.legendary_count,
  mythic_count = tallies.mythic_count,
  updated_at = NOW()
FROM tallies
WHERE us.user_id = tallies.user_id;

-- =============================================================================
-- 2. Session score: expose common + epic separately for user_stats increments
-- =============================================================================

CREATE OR REPLACE FUNCTION public.compute_session_score(p_session_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cell RECORD;
  v_cell_score NUMERIC;
  v_total NUMERIC := 0;
  v_common INT := 0;
  v_rare INT := 0;
  v_epic INT := 0;
  v_legendary INT := 0;
  v_mythic INT := 0;
  v_correct INT := 0;
  v_tier TEXT;
  v_speed_bonus NUMERIC;
  v_quality NUMERIC;
  v_quality_factor NUMERIC;
  v_hints INT := 0;
  v_hint_penalty_sum INT := 0;
  v_mistakes INT := 0;
  v_expected INT;
  v_completion_bonus INT := 0;
  v_duration_ms BIGINT := 0;
  v_pace NUMERIC := 1.0;
  v_minutes NUMERIC;
  v_base_cell CONSTANT INT := 10;
  v_completion_bonus_amount CONSTANT INT := 25;
  v_mistake_penalty CONSTANT INT := 15;
  v_session_raw NUMERIC;
  v_final NUMERIC;
BEGIN
  SELECT
    ps.grid_size * ps.grid_size,
    COALESCE(ps.mistakes, 0),
    GREATEST(
      0,
      EXTRACT(EPOCH FROM (COALESCE(ps.completed_at, NOW()) - ps.started_at)) * 1000
    )::BIGINT
  INTO v_expected, v_mistakes, v_duration_ms
  FROM public.puzzle_sessions ps
  WHERE ps.id = p_session_id;

  FOR v_cell IN
    SELECT
      a.usage_percentage,
      a.response_time_ms,
      a.rarity_tier,
      a.is_correct,
      COALESCE(pl.obscurity_score, 50)::NUMERIC AS obscurity_score
    FROM public.answers a
    LEFT JOIN public.players pl ON pl.id = a.player_id
    WHERE a.session_id = p_session_id AND a.is_correct = TRUE
  LOOP
    v_correct := v_correct + 1;
    v_quality := public.answer_quality_score(
      v_cell.obscurity_score,
      v_cell.usage_percentage
    );
    v_quality_factor := 0.7 + (v_quality / 100.0) * 0.8;
    v_speed_bonus := CASE
      WHEN COALESCE(v_cell.response_time_ms, 60000) < 30000 THEN 1.25
      WHEN COALESCE(v_cell.response_time_ms, 60000) < 60000 THEN 1.10
      WHEN COALESCE(v_cell.response_time_ms, 60000) < 120000 THEN 1.00
      ELSE 0.90
    END;
    v_cell_score := GREATEST(
      8,
      v_base_cell * v_quality_factor * v_speed_bonus
    );
    v_total := v_total + v_cell_score;

    v_tier := public.rarity_tier_from_quality(v_quality);
    CASE v_tier
      WHEN 'common' THEN v_common := v_common + 1;
      WHEN 'rare' THEN v_rare := v_rare + 1;
      WHEN 'epic' THEN v_epic := v_epic + 1;
      WHEN 'legendary' THEN v_legendary := v_legendary + 1;
      WHEN 'mythic' THEN v_mythic := v_mythic + 1;
      ELSE v_common := v_common + 1;
    END CASE;
  END LOOP;

  SELECT
    COUNT(*)::INT,
    COALESCE(SUM(public.hint_penalty_for_type(sh.hint_type::TEXT)), 0)::INT
  INTO v_hints, v_hint_penalty_sum
  FROM public.session_hints sh
  WHERE sh.session_id = p_session_id;

  IF v_expected > 0 AND v_correct >= v_expected THEN
    v_completion_bonus := v_completion_bonus_amount;
  END IF;

  v_minutes := COALESCE(v_duration_ms, 0) / 60000.0;
  v_pace := GREATEST(0.75, LEAST(1.10, 1.10 - (v_minutes - 6) * 0.015));

  v_session_raw := v_total + v_completion_bonus - v_hint_penalty_sum - (v_mistakes * v_mistake_penalty);
  v_final := GREATEST(0, ROUND(v_session_raw * v_pace, 2));

  RETURN jsonb_build_object(
    'cell_score_sum', ROUND(v_total, 2),
    'hints_used', v_hints,
    'hint_penalty', v_hint_penalty_sum,
    'mistakes', v_mistakes,
    'completion_bonus', v_completion_bonus,
    'pace_multiplier', ROUND(v_pace, 3),
    'duration_ms', v_duration_ms,
    'final_score', v_final,
    'correct_count', v_correct,
    'common_count', v_common,
    'rare_count', v_rare,
    'epic_count', v_epic,
    'legendary_count', v_legendary,
    'mythic_count', v_mythic,
    'is_perfect', (v_hints = 0 AND v_mistakes = 0 AND v_expected > 0 AND v_correct >= v_expected),
    'scoring_version', 2
  );
END;
$$;

REVOKE ALL ON FUNCTION public.compute_session_score(UUID) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.compute_session_score(UUID) TO service_role;

-- =============================================================================
-- 3. Nationality patches for high-visibility players missing ISO codes
-- =============================================================================

UPDATE public.players
SET
  nationality_code = 'SE',
  primary_position = COALESCE(NULLIF(primary_position, ''), 'ST'),
  updated_at = NOW()
WHERE normalized_name LIKE '%gyokeres%'
  AND (nationality_code IS NULL OR nationality_code = '');
