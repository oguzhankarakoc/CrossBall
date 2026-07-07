-- Fair daily scoring: base points per cell + rarity bonus + completion bonus.

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
  v_rarity_score NUMERIC;
  v_hints INT;
  v_expected INT;
  v_completion_bonus INT := 0;
  v_base_cell CONSTANT INT := 12;
  v_rarity_multiplier CONSTANT NUMERIC := 0.45;
  v_completion_bonus_amount CONSTANT INT := 30;
BEGIN
  SELECT ps.grid_size * ps.grid_size INTO v_expected
  FROM public.puzzle_sessions ps
  WHERE ps.id = p_session_id;

  FOR v_cell IN
    SELECT a.usage_percentage, a.response_time_ms, a.rarity_tier, a.is_correct
    FROM public.answers a
    WHERE a.session_id = p_session_id AND a.is_correct = TRUE
  LOOP
    v_correct := v_correct + 1;
    v_rarity_score := GREATEST(0, 100 - COALESCE(v_cell.usage_percentage, 0));
    v_speed_bonus := CASE
      WHEN COALESCE(v_cell.response_time_ms, 60000) < 30000 THEN 1.3
      WHEN COALESCE(v_cell.response_time_ms, 60000) < 60000 THEN 1.15
      WHEN COALESCE(v_cell.response_time_ms, 60000) < 120000 THEN 1.0
      ELSE 0.85
    END;
    v_cell_score := GREATEST(
      v_base_cell * 0.5,
      (v_base_cell + v_rarity_score * v_rarity_multiplier) * v_speed_bonus
    );
    v_total := v_total + v_cell_score;

    v_tier := COALESCE(v_cell.rarity_tier::TEXT, 'common');
    IF v_tier IN ('rare', 'epic') THEN
      v_rare := v_rare + 1;
    ELSIF v_tier = 'legendary' THEN
      v_legendary := v_legendary + 1;
    ELSIF v_tier = 'mythic' THEN
      v_mythic := v_mythic + 1;
    END IF;
  END LOOP;

  SELECT COUNT(*)::INT INTO v_hints
  FROM public.session_hints sh
  WHERE sh.session_id = p_session_id;

  IF v_expected > 0 AND v_correct >= v_expected THEN
    v_completion_bonus := v_completion_bonus_amount;
  END IF;

  RETURN jsonb_build_object(
    'cell_score_sum', v_total,
    'hints_used', v_hints,
    'completion_bonus', v_completion_bonus,
    'final_score', GREATEST(0, v_total + v_completion_bonus - (v_hints * 5)),
    'correct_count', v_correct,
    'rare_count', v_rare,
    'legendary_count', v_legendary,
    'mythic_count', v_mythic,
    'is_perfect', (v_hints = 0)
  );
END;
$$;
