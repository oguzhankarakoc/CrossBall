-- Free practice: rewarded ad every 2 sessions (not every session).
-- Sessions 1, 3, 5… require an ad unlock; 2, 4, 6… are free after the prior ad.

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
  v_ad_every INT := 2;
BEGIN
  SELECT COALESCE(u.is_premium, FALSE), COALESCE(u.timezone_offset_minutes, 0)
  INTO v_is_premium, v_offset
  FROM public.users u
  WHERE u.user_uuid = p_user_uuid
  LIMIT 1;

  v_row := public._practice_usage_row(p_user_uuid, v_offset);
  v_limit := public.practice_daily_limit(v_is_premium);
  v_remaining := GREATEST(0, v_limit - v_row.completed_count);
  -- Ad cadence: completed_count % 2 = 0 → need unlock (1st, 3rd, 5th session…).
  v_needs_ad := NOT v_is_premium
    AND NOT v_row.ad_unlock_granted
    AND (v_row.completed_count % v_ad_every = 0);
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
    'ad_every_n_sessions', v_ad_every,
    'can_start', v_can_start
  );
END;
$$;
