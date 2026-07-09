-- Tournament leaderboard: nickname when set, otherwise Player #XXXX from UUID.

CREATE OR REPLACE FUNCTION public.upsert_tournament_score(
  p_tournament_slug TEXT,
  p_user_uuid TEXT,
  p_score NUMERIC
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
  IF p_tournament_slug IS NULL OR p_user_uuid IS NULL THEN
    RETURN;
  END IF;

  SELECT u.display_name
  INTO v_nickname
  FROM users u
  WHERE u.user_uuid = p_user_uuid
  LIMIT 1;

  v_name := public.resolve_player_display_name(v_nickname, p_user_uuid);

  INSERT INTO tournament_scores (tournament_slug, user_uuid, display_name, best_score, sessions_count)
  VALUES (p_tournament_slug, p_user_uuid, v_name, p_score, 1)
  ON CONFLICT (tournament_slug, user_uuid) DO UPDATE SET
    best_score = GREATEST(tournament_scores.best_score, EXCLUDED.best_score),
    sessions_count = tournament_scores.sessions_count + 1,
    display_name = EXCLUDED.display_name,
    updated_at = NOW();
END;
$$;

CREATE OR REPLACE FUNCTION public.get_tournament_leaderboard(
  p_tournament_slug TEXT,
  p_limit INT DEFAULT 25
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit INT := LEAST(GREATEST(COALESCE(p_limit, 25), 1), 100);
BEGIN
  RETURN jsonb_build_object(
    'ok', TRUE,
    'tournament_slug', p_tournament_slug,
    'entries', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'rank', t.rank,
          'user_uuid', t.user_uuid,
          'display_name', t.display_name,
          'best_score', t.best_score,
          'sessions_count', t.sessions_count
        )
        ORDER BY t.rank
      )
      FROM (
        SELECT
          ROW_NUMBER() OVER (ORDER BY best_score DESC, updated_at ASC)::INT AS rank,
          user_uuid,
          public.resolve_player_display_name(display_name, user_uuid) AS display_name,
          best_score,
          sessions_count
        FROM tournament_scores
        WHERE tournament_slug = p_tournament_slug
        ORDER BY best_score DESC, updated_at ASC
        LIMIT v_limit
      ) t
    ), '[]'::JSONB)
  );
END;
$$;

UPDATE public.tournament_scores
SET display_name = public.resolve_player_display_name(display_name, user_uuid)
WHERE display_name IS NULL
   OR trim(display_name) = ''
   OR display_name = 'Player';
