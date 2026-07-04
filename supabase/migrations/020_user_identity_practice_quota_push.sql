-- User identity (nickname), server-authoritative practice quota, push token registry.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS timezone_offset_minutes INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS push_opt_in BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN public.users.display_name IS 'Optional player nickname (unique when set).';
COMMENT ON COLUMN public.users.timezone_offset_minutes IS 'Device UTC offset in minutes for local-day quotas.';
COMMENT ON COLUMN public.users.push_opt_in IS 'User consent for marketing/reminder push notifications.';

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_display_name_unique
  ON public.users (lower(trim(display_name)))
  WHERE display_name IS NOT NULL AND trim(display_name) <> '';

CREATE TABLE IF NOT EXISTS public.user_daily_practice_usage (
  user_uuid TEXT NOT NULL,
  usage_date DATE NOT NULL,
  completed_count INT NOT NULL DEFAULT 0 CHECK (completed_count >= 0),
  ad_unlock_granted BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_uuid, usage_date)
);

CREATE INDEX IF NOT EXISTS idx_practice_usage_user_date
  ON public.user_daily_practice_usage (user_uuid, usage_date DESC);

CREATE TABLE IF NOT EXISTS public.user_push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_uuid TEXT NOT NULL,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  app_version TEXT,
  locale TEXT,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_uuid, token)
);

CREATE INDEX IF NOT EXISTS idx_user_push_tokens_user
  ON public.user_push_tokens (user_uuid);

CREATE OR REPLACE FUNCTION public.practice_daily_limit(p_is_premium BOOLEAN)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE WHEN COALESCE(p_is_premium, FALSE) THEN 10 ELSE 5 END;
$$;

CREATE OR REPLACE FUNCTION public.user_local_date(p_timezone_offset_minutes INT DEFAULT 0)
RETURNS DATE
LANGUAGE sql
STABLE
AS $$
  SELECT ((NOW() AT TIME ZONE 'UTC') + make_interval(mins => COALESCE(p_timezone_offset_minutes, 0)))::DATE;
$$;

CREATE OR REPLACE FUNCTION public._practice_usage_row(
  p_user_uuid TEXT,
  p_timezone_offset_minutes INT DEFAULT 0
)
RETURNS public.user_daily_practice_usage
LANGUAGE plpgsql
AS $$
DECLARE
  v_date DATE := public.user_local_date(p_timezone_offset_minutes);
  v_row public.user_daily_practice_usage;
BEGIN
  INSERT INTO public.user_daily_practice_usage (user_uuid, usage_date)
  VALUES (p_user_uuid, v_date)
  ON CONFLICT (user_uuid, usage_date) DO NOTHING;

  SELECT * INTO v_row
  FROM public.user_daily_practice_usage
  WHERE user_uuid = p_user_uuid AND usage_date = v_date;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_practice_quota(p_user_uuid TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_premium BOOLEAN := FALSE;
  v_offset INT := 0;
  v_row public.user_daily_practice_usage;
  v_limit INT;
  v_remaining INT;
  v_needs_ad BOOLEAN;
  v_can_start BOOLEAN;
BEGIN
  SELECT COALESCE(u.is_premium, FALSE), COALESCE(u.timezone_offset_minutes, 0)
  INTO v_is_premium, v_offset
  FROM public.users u
  WHERE u.user_uuid = p_user_uuid
  LIMIT 1;

  v_row := public._practice_usage_row(p_user_uuid, v_offset);
  v_limit := public.practice_daily_limit(v_is_premium);
  v_remaining := GREATEST(0, v_limit - v_row.completed_count);
  v_needs_ad := NOT v_is_premium
    AND v_row.completed_count > 0
    AND NOT v_row.ad_unlock_granted
    AND v_remaining > 0;
  v_can_start := v_remaining > 0 AND (NOT v_needs_ad OR v_row.ad_unlock_granted);

  RETURN jsonb_build_object(
    'user_uuid', p_user_uuid,
    'usage_date', v_row.usage_date,
    'completed_today', v_row.completed_count,
    'daily_limit', v_limit,
    'remaining', v_remaining,
    'is_premium', v_is_premium,
    'needs_ad', v_needs_ad,
    'ad_unlock_granted', v_row.ad_unlock_granted,
    'can_start', v_can_start
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.grant_practice_ad_unlock(p_user_uuid TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_offset INT := 0;
  v_date DATE;
BEGIN
  SELECT COALESCE(timezone_offset_minutes, 0) INTO v_offset
  FROM public.users WHERE user_uuid = p_user_uuid LIMIT 1;

  v_date := public.user_local_date(v_offset);
  PERFORM public._practice_usage_row(p_user_uuid, v_offset);

  UPDATE public.user_daily_practice_usage
  SET ad_unlock_granted = TRUE, updated_at = NOW()
  WHERE user_uuid = p_user_uuid AND usage_date = v_date;

  RETURN public.get_practice_quota(p_user_uuid);
END;
$$;

CREATE OR REPLACE FUNCTION public.consume_practice_ad_unlock(p_user_uuid TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_offset INT := 0;
  v_date DATE;
BEGIN
  SELECT COALESCE(timezone_offset_minutes, 0) INTO v_offset
  FROM public.users WHERE user_uuid = p_user_uuid LIMIT 1;

  v_date := public.user_local_date(v_offset);

  UPDATE public.user_daily_practice_usage
  SET ad_unlock_granted = FALSE, updated_at = NOW()
  WHERE user_uuid = p_user_uuid
    AND usage_date = v_date
    AND ad_unlock_granted = TRUE;

  RETURN public.get_practice_quota(p_user_uuid);
END;
$$;

CREATE OR REPLACE FUNCTION public.consume_practice_session(p_user_uuid TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_premium BOOLEAN := FALSE;
  v_offset INT := 0;
  v_row public.user_daily_practice_usage;
  v_limit INT;
BEGIN
  SELECT COALESCE(u.is_premium, FALSE), COALESCE(u.timezone_offset_minutes, 0)
  INTO v_is_premium, v_offset
  FROM public.users u
  WHERE u.user_uuid = p_user_uuid
  LIMIT 1;

  v_row := public._practice_usage_row(p_user_uuid, v_offset);
  v_limit := public.practice_daily_limit(v_is_premium);

  IF v_row.completed_count >= v_limit THEN
    RAISE EXCEPTION 'practice_daily_limit_reached';
  END IF;

  UPDATE public.user_daily_practice_usage
  SET completed_count = completed_count + 1,
      ad_unlock_granted = FALSE,
      updated_at = NOW()
  WHERE user_uuid = p_user_uuid AND usage_date = v_row.usage_date;

  RETURN public.get_practice_quota(p_user_uuid);
END;
$$;

CREATE OR REPLACE FUNCTION public.assert_practice_can_start(p_user_uuid TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_quota JSONB := public.get_practice_quota(p_user_uuid);
BEGIN
  IF NOT COALESCE((v_quota->>'can_start')::BOOLEAN, FALSE) THEN
    IF COALESCE((v_quota->>'remaining')::INT, 0) <= 0 THEN
      RAISE EXCEPTION 'practice_daily_limit_reached';
    END IF;
    RAISE EXCEPTION 'practice_ad_required';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.upsert_push_token(
  p_user_uuid TEXT,
  p_token TEXT,
  p_platform TEXT,
  p_app_version TEXT DEFAULT NULL,
  p_locale TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.user_push_tokens (
    user_uuid, token, platform, app_version, locale, last_seen_at
  )
  VALUES (
    p_user_uuid, trim(p_token), lower(trim(p_platform)), p_app_version, p_locale, NOW()
  )
  ON CONFLICT (user_uuid, token) DO UPDATE SET
    platform = EXCLUDED.platform,
    app_version = COALESCE(EXCLUDED.app_version, user_push_tokens.app_version),
    locale = COALESCE(EXCLUDED.locale, user_push_tokens.locale),
    last_seen_at = NOW()
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_practice_quota(TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.grant_practice_ad_unlock(TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.consume_practice_ad_unlock(TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.consume_practice_session(TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.assert_practice_can_start(TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.upsert_push_token(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated, service_role;
