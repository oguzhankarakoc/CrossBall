-- Fix home level / season points showing defaults (level 1, 0 SP) while
-- rating leaderboard shows the real progression (e.g. level 7).
--
-- Root cause: gee_get_profile was STABLE but calls gee_ensure_progression
-- (INSERT). Edge Functions run STABLE RPCs in a read-only transaction, so
-- economy-profile returned 500: "cannot execute INSERT in a read-only transaction".
-- The client then fell back to PlayerProgression() defaults.
-- Same pattern as 042_daily_rollout_readonly_peek.sql.

CREATE OR REPLACE FUNCTION public.gee_get_profile(p_user_uuid TEXT)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_prog player_progression;
  v_next_level_xp BIGINT;
  v_achievements JSONB;
BEGIN
  SELECT id INTO v_user_id FROM users WHERE user_uuid = p_user_uuid LIMIT 1;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE);
  END IF;

  v_prog := gee_ensure_progression(v_user_id);

  SELECT MIN(xp_required_total) INTO v_next_level_xp
  FROM economy_level_thresholds
  WHERE level > v_prog.current_level;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'slug', pa.achievement_slug,
    'unlocked_at', pa.unlocked_at,
    'title', d.title,
    'description', d.description
  ) ORDER BY pa.unlocked_at DESC), '[]'::JSONB)
  INTO v_achievements
  FROM player_achievements pa
  JOIN economy_achievement_definitions d ON d.slug = pa.achievement_slug
  WHERE pa.user_id = v_user_id;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'user_id', v_user_id,
    'experience_points', v_prog.experience_points,
    'current_level', v_prog.current_level,
    'xp_to_next_level', COALESCE(v_next_level_xp, v_prog.experience_points) - v_prog.experience_points,
    'competitive_rating', v_prog.competitive_rating,
    'current_league', v_prog.current_league,
    'games_played', v_prog.games_played,
    'games_completed', v_prog.games_completed,
    'games_won', v_prog.games_won,
    'current_streak', v_prog.current_streak,
    'best_streak', v_prog.best_streak,
    'highest_score', v_prog.highest_score,
    'average_score', v_prog.average_score,
    'average_solve_time_ms', v_prog.average_solve_time_ms,
    'favorite_difficulty', v_prog.favorite_difficulty,
    'rare_answers_found', v_prog.rare_answers_found,
    'legendary_answers_found', v_prog.legendary_answers_found,
    'perfect_games', v_prog.perfect_games,
    'hints_used', v_prog.hints_used,
    'season_points', v_prog.season_points,
    'achievement_points', v_prog.achievement_points,
    'achievements', v_achievements,
    'last_active', v_prog.last_active
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.gee_get_profile(TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.gee_get_profile(TEXT) TO service_role;
