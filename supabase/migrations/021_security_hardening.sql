-- Phase 0 security: lock down RPC grants, server sessions, authoritative scoring.

-- =============================================================================
-- 1. Revoke direct client access to economy / quota / push RPCs
-- =============================================================================

REVOKE EXECUTE ON FUNCTION public.gee_process_event(TEXT, TEXT, JSONB) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.gee_get_profile(TEXT) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.grant_practice_ad_unlock(TEXT) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.consume_practice_ad_unlock(TEXT) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.consume_practice_session(TEXT) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.assert_practice_can_start(TEXT) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_practice_quota(TEXT) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.upsert_push_token(TEXT, TEXT, TEXT, TEXT, TEXT) FROM anon, authenticated;

REVOKE SELECT ON public.player_progression FROM anon, authenticated;
REVOKE SELECT ON public.player_achievements FROM anon, authenticated;

ALTER TABLE public.user_daily_practice_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 2. Premium helpers (edge functions only via service role)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.user_is_premium(p_user_uuid TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (
      SELECT u.is_premium
        AND (u.premium_until IS NULL OR u.premium_until > NOW())
      FROM public.users u
      WHERE u.user_uuid = p_user_uuid
      LIMIT 1
    ),
    FALSE
  );
$$;

CREATE OR REPLACE FUNCTION public.set_user_premium(
  p_user_uuid TEXT,
  p_is_premium BOOLEAN,
  p_premium_until TIMESTAMPTZ DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users
  SET is_premium = p_is_premium,
      premium_until = CASE WHEN p_is_premium THEN p_premium_until ELSE NULL END,
      updated_at = NOW()
  WHERE user_uuid = p_user_uuid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.iap_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_uuid TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'dev')),
  product_id TEXT NOT NULL,
  verification_hash TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_iap_verifications_user ON public.iap_verifications (user_uuid, created_at DESC);

ALTER TABLE public.iap_verifications ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 3. Server-authoritative puzzle sessions
-- =============================================================================

CREATE OR REPLACE FUNCTION public.start_puzzle_session(
  p_user_uuid TEXT,
  p_puzzle_id UUID,
  p_mode puzzle_mode,
  p_grid_size SMALLINT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session_id UUID := gen_random_uuid();
BEGIN
  SELECT id INTO v_user_id
  FROM public.users
  WHERE user_uuid = p_user_uuid
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.puzzles p WHERE p.id = p_puzzle_id AND p.is_published = TRUE
  ) THEN
    RAISE EXCEPTION 'puzzle_not_found';
  END IF;

  INSERT INTO public.puzzle_sessions (
    id, user_id, puzzle_id, mode, grid_size, status
  )
  VALUES (v_session_id, v_user_id, p_puzzle_id, p_mode, p_grid_size, 'active');

  RETURN v_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.assert_active_session(
  p_session_id UUID,
  p_user_uuid TEXT DEFAULT NULL
)
RETURNS public.puzzle_sessions
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.puzzle_sessions;
  v_user_id UUID;
BEGIN
  SELECT ps.* INTO v_row
  FROM public.puzzle_sessions ps
  WHERE ps.id = p_session_id;

  IF v_row.id IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;

  IF v_row.status <> 'active' THEN
    RAISE EXCEPTION 'session_not_active';
  END IF;

  IF p_user_uuid IS NOT NULL THEN
    SELECT u.id INTO v_user_id
    FROM public.users u
    WHERE u.user_uuid = p_user_uuid
    LIMIT 1;

    IF v_user_id IS NULL OR v_user_id <> v_row.user_id THEN
      RAISE EXCEPTION 'session_forbidden';
    END IF;
  END IF;

  RETURN v_row;
END;
$$;

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
BEGIN
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
    v_cell_score := GREATEST(0, v_rarity_score * v_speed_bonus);
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

  RETURN jsonb_build_object(
    'cell_score_sum', v_total,
    'hints_used', v_hints,
    'final_score', GREATEST(0, v_total - (v_hints * 5)),
    'correct_count', v_correct,
    'rare_count', v_rare,
    'legendary_count', v_legendary,
    'mythic_count', v_mythic,
    'is_perfect', (v_hints = 0)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.user_completed_daily_today(p_user_uuid TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.puzzle_sessions ps
    JOIN public.users u ON u.id = ps.user_id
    JOIN public.puzzles p ON p.id = ps.puzzle_id
    WHERE u.user_uuid = p_user_uuid
      AND ps.mode = 'daily'
      AND ps.status = 'completed'
      AND p.puzzle_date = (NOW() AT TIME ZONE 'UTC')::DATE
  );
$$;

REVOKE ALL ON FUNCTION public.user_is_premium(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_user_premium(TEXT, BOOLEAN, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.start_puzzle_session(TEXT, UUID, puzzle_mode, SMALLINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.assert_active_session(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.compute_session_score(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.user_completed_daily_today(TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.user_is_premium(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.set_user_premium(TEXT, BOOLEAN, TIMESTAMPTZ) TO service_role;
GRANT EXECUTE ON FUNCTION public.start_puzzle_session(TEXT, UUID, puzzle_mode, SMALLINT) TO service_role;
GRANT EXECUTE ON FUNCTION public.assert_active_session(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.compute_session_score(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.user_completed_daily_today(TEXT) TO service_role;
