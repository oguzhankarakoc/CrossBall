-- Consistent player labels: nickname when set, otherwise Player #XXXX from UUID.

CREATE OR REPLACE FUNCTION public.resolve_player_display_name(
  p_display_name TEXT,
  p_user_uuid TEXT
)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN NULLIF(TRIM(p_display_name), '') IS NOT NULL
         AND TRIM(p_display_name) <> 'Player'
    THEN LEFT(TRIM(p_display_name), 20)
    WHEN p_user_uuid IS NOT NULL
         AND length(replace(p_user_uuid, '-', '')) >= 4
    THEN 'Player #' || upper(substring(replace(p_user_uuid, '-', '') FROM 1 FOR 4))
    ELSE 'Player'
  END;
$$;

CREATE OR REPLACE FUNCTION public.log_player_activity(
  p_user_uuid TEXT,
  p_event_type TEXT,
  p_payload JSONB DEFAULT '{}'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_name TEXT := 'Player';
  v_nickname TEXT;
BEGIN
  IF p_user_uuid IS NULL OR length(p_user_uuid) < 8 THEN
    RETURN;
  END IF;

  SELECT u.display_name
  INTO v_nickname
  FROM users u
  WHERE u.user_uuid = p_user_uuid
  LIMIT 1;

  v_name := public.resolve_player_display_name(v_nickname, p_user_uuid);

  INSERT INTO player_activity_events (user_uuid, display_name, event_type, payload)
  VALUES (p_user_uuid, v_name, p_event_type, COALESCE(p_payload, '{}'::JSONB));
END;
$$;

CREATE OR REPLACE FUNCTION public.get_activity_feed(p_limit INT DEFAULT 20)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit INT := LEAST(GREATEST(COALESCE(p_limit, 20), 1), 50);
BEGIN
  RETURN jsonb_build_object(
    'ok', TRUE,
    'events', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', e.id,
          'user_uuid', e.user_uuid,
          'display_name', public.resolve_player_display_name(e.display_name, e.user_uuid),
          'event_type', e.event_type,
          'payload', e.payload,
          'created_at', e.created_at
        )
        ORDER BY e.created_at DESC
      )
      FROM (
        SELECT *
        FROM player_activity_events
        ORDER BY created_at DESC
        LIMIT v_limit
      ) e
    ), '[]'::JSONB)
  );
END;
$$;

UPDATE public.player_activity_events
SET display_name = public.resolve_player_display_name(display_name, user_uuid)
WHERE display_name IS NULL
   OR trim(display_name) = ''
   OR display_name = 'Player';
