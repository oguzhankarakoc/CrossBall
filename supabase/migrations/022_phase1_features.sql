-- Phase 1: missions API, leaderboard, hint ad tokens, RLS hardening.

-- =============================================================================
-- 1. Daily / weekly missions fetch (service role via edge functions)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.gee_get_missions(p_user_uuid TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_daily_key TEXT := CURRENT_DATE::TEXT;
  v_weekly_key TEXT := to_char(CURRENT_DATE, 'IYYY-"W"IW');
BEGIN
  SELECT id INTO v_user_id FROM users WHERE user_uuid = p_user_uuid LIMIT 1;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'missions', '[]'::JSONB);
  END IF;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'missions', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'slug', d.slug,
          'title', d.title,
          'description', d.description,
          'period', d.period::TEXT,
          'progress', COALESCE(pm.progress, '{}'::JSONB),
          'target', d.criteria,
          'is_completed', COALESCE(pm.is_completed, FALSE),
          'completed_at', pm.completed_at,
          'reward_xp', COALESCE((d.reward_payload->>'xp')::INT, 0),
          'progress_current', CASE
            WHEN COALESCE(pm.is_completed, FALSE) THEN COALESCE((d.criteria->>'count')::INT, 1)
            WHEN d.slug = 'weekly_hard_3' THEN COALESCE((pm.progress->>'count')::INT, 0)
            ELSE 0
          END,
          'progress_target', COALESCE((d.criteria->>'count')::INT, 1)
        )
        ORDER BY d.period, d.slug
      )
      FROM economy_mission_definitions d
      LEFT JOIN player_missions pm ON pm.mission_slug = d.slug
        AND pm.user_id = v_user_id
        AND pm.period_key = CASE
          WHEN d.period = 'daily' THEN v_daily_key
          WHEN d.period = 'weekly' THEN v_weekly_key
          ELSE v_daily_key
        END
      WHERE d.is_active = TRUE
        AND d.period IN ('daily', 'weekly')
    ), '[]'::JSONB)
  );
END;
$$;

-- =============================================================================
-- 2. Rating leaderboard
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_rating_leaderboard(
  p_league TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100);
BEGIN
  RETURN jsonb_build_object(
    'ok', TRUE,
    'entries', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'rank', ranked.rank,
          'user_uuid', ranked.user_uuid,
          'display_name', ranked.display_name,
          'competitive_rating', ranked.competitive_rating,
          'current_league', ranked.current_league,
          'current_level', ranked.current_level
        )
        ORDER BY ranked.rank
      )
      FROM (
        SELECT
          ROW_NUMBER() OVER (ORDER BY pp.competitive_rating DESC, pp.experience_points DESC) AS rank,
          u.user_uuid,
          COALESCE(NULLIF(TRIM(u.display_name), ''), 'Player') AS display_name,
          pp.competitive_rating,
          pp.current_league,
          pp.current_level
        FROM player_progression pp
        JOIN users u ON u.id = pp.user_id
        WHERE pp.games_completed > 0
          AND (p_league IS NULL OR pp.current_league = p_league)
        ORDER BY pp.competitive_rating DESC, pp.experience_points DESC
        LIMIT v_limit
      ) ranked
    ), '[]'::JSONB)
  );
END;
$$;

-- =============================================================================
-- 3. Hint ad token gate (one-time tokens after rewarded ad)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.hint_ad_tokens (
  token UUID PRIMARY KEY,
  user_uuid TEXT NOT NULL,
  session_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  used_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_hint_ad_tokens_user ON public.hint_ad_tokens (user_uuid, created_at DESC);

ALTER TABLE public.hint_ad_tokens ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.grant_hint_ad_token(
  p_token UUID,
  p_user_uuid TEXT,
  p_session_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_token IS NULL OR p_user_uuid IS NULL OR length(p_user_uuid) < 8 THEN
    RETURN FALSE;
  END IF;

  INSERT INTO hint_ad_tokens (token, user_uuid, session_id)
  VALUES (p_token, p_user_uuid, p_session_id)
  ON CONFLICT (token) DO NOTHING;

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.consume_hint_ad_token(
  p_token UUID,
  p_user_uuid TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated INT;
BEGIN
  UPDATE hint_ad_tokens
  SET used_at = NOW()
  WHERE token = p_token
    AND user_uuid = p_user_uuid
    AND used_at IS NULL
    AND created_at > NOW() - INTERVAL '10 minutes';

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated = 1;
END;
$$;

-- =============================================================================
-- 4. RLS policies (defense in depth)
-- =============================================================================

ALTER TABLE public.player_progression ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_achievements ENABLE ROW LEVEL SECURITY;

-- No direct client policies: access only via service-role edge functions.

REVOKE SELECT ON public.player_missions FROM anon, authenticated;
