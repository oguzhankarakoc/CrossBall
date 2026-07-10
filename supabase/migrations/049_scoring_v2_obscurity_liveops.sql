-- Scoring v2: player obscurity, hybrid answer quality, weighted hints, session pace.
-- LiveOps: refresh UCL window + soft-launch community goal scale.

-- =============================================================================
-- 1. Player obscurity (0 = superstar, 100 = obscure)
-- =============================================================================

ALTER TABLE public.players
  ADD COLUMN IF NOT EXISTS obscurity_score SMALLINT NOT NULL DEFAULT 50
    CHECK (obscurity_score >= 0 AND obscurity_score <= 100);

COMMENT ON COLUMN public.players.obscurity_score IS
  '0–100 football-IQ obscurity; higher = less famous. Used in hybrid answer quality.';

CREATE INDEX IF NOT EXISTS idx_players_obscurity
  ON public.players (obscurity_score DESC);

-- Backfill from global pick popularity (log-scaled inverse).
WITH pop AS (
  SELECT
    p.id AS player_id,
    COALESCE(pp.global_selection_count, 0)::NUMERIC AS picks
  FROM public.players p
  LEFT JOIN public.player_popularity pp ON pp.player_id = p.id
),
stats AS (
  SELECT GREATEST(MAX(picks), 1) AS max_picks FROM pop
)
UPDATE public.players pl
SET obscurity_score = GREATEST(
  0,
  LEAST(
    100,
    ROUND(
      100 - (LN(1 + pop.picks) / LN(1 + stats.max_picks)) * 100
    )::INT
  )
)::SMALLINT
FROM pop, stats
WHERE pl.id = pop.player_id;

-- Unknown / never-picked players stay high-obscurity (already default 50;
-- bump never-picked toward 75 for cold-start fairness).
UPDATE public.players pl
SET obscurity_score = 75
WHERE NOT EXISTS (
  SELECT 1 FROM public.player_popularity pp
  WHERE pp.player_id = pl.id AND pp.global_selection_count > 0
)
AND pl.obscurity_score = 50;

CREATE OR REPLACE FUNCTION public.answer_quality_score(
  p_obscurity NUMERIC,
  p_usage_percentage NUMERIC
)
RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT GREATEST(
    0,
    LEAST(
      100,
      COALESCE(p_obscurity, 50) * 0.55
        + GREATEST(0, 100 - COALESCE(p_usage_percentage, 100)) * 0.45
    )
  );
$$;

CREATE OR REPLACE FUNCTION public.rarity_tier_from_quality(p_quality NUMERIC)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_quality >= 80 THEN 'mythic'
    WHEN p_quality >= 65 THEN 'legendary'
    WHEN p_quality >= 50 THEN 'epic'
    WHEN p_quality >= 35 THEN 'rare'
    ELSE 'common'
  END;
$$;

CREATE OR REPLACE FUNCTION public.hint_penalty_for_type(p_hint_type TEXT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_hint_type
    WHEN 'nationality' THEN 4
    WHEN 'position' THEN 6
    WHEN 'first_letter' THEN 9
    WHEN 'career_league' THEN 12
    WHEN 'retired_status' THEN 14
    WHEN 'career_club' THEN 18
    ELSE 5
  END;
$$;

-- =============================================================================
-- 2. Session score v2
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
  v_rare INT := 0;
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
    IF v_tier IN ('rare', 'epic') THEN
      v_rare := v_rare + 1;
    ELSIF v_tier = 'legendary' THEN
      v_legendary := v_legendary + 1;
    ELSIF v_tier = 'mythic' THEN
      v_mythic := v_mythic + 1;
    END IF;
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
  -- Ideal ~6 minutes for 3x3; bonus under 6m, soft decay after.
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
    'rare_count', v_rare,
    'legendary_count', v_legendary,
    'mythic_count', v_mythic,
    'is_perfect', (v_hints = 0 AND v_mistakes = 0 AND v_expected > 0 AND v_correct >= v_expected),
    'scoring_version', 2
  );
END;
$$;

REVOKE ALL ON FUNCTION public.compute_session_score(UUID) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.compute_session_score(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.answer_quality_score(NUMERIC, NUMERIC) TO service_role;
GRANT EXECUTE ON FUNCTION public.rarity_tier_from_quality(NUMERIC) TO service_role;
GRANT EXECUTE ON FUNCTION public.hint_penalty_for_type(TEXT) TO service_role;

-- =============================================================================
-- 3. LiveOps: UCL visible again + soft-launch community goal
-- =============================================================================

UPDATE public.liveops_events
SET
  starts_at = NOW() - INTERVAL '1 day',
  ends_at = NOW() + INTERVAL '14 days',
  is_active = TRUE
WHERE slug = 'champions_league_week';

UPDATE public.liveops_community_goals
SET
  target_value = 1000,
  starts_at = NOW() - INTERVAL '1 day',
  ends_at = NOW() + INTERVAL '60 days'
WHERE slug = 'global_puzzles_1m';

UPDATE public.liveops_community_goal_i18n
SET
  title = CASE locale
    WHEN 'tr' THEN '1.000 Bulmaca'
    WHEN 'de' THEN '1.000 Rätsel'
    ELSE '1,000 Puzzles'
  END,
  description = CASE locale
    WHEN 'tr' THEN 'Topluluk olarak 1.000 bulmaca çözelim — soft launch hedefi.'
    WHEN 'de' THEN 'Lasst uns gemeinsam 1.000 Rätsel lösen — Soft-Launch-Ziel.'
    ELSE 'Help the community solve 1,000 puzzles — soft launch goal.'
  END
WHERE goal_slug = 'global_puzzles_1m';
