-- Leaderboard display names: nickname when set, otherwise Player #XXXX from UUID.

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
          public.resolve_player_display_name(u.display_name, u.user_uuid) AS display_name,
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

-- Patch weekly leaderboard display_name resolution in ranked CTEs.
CREATE OR REPLACE FUNCTION public.get_weekly_daily_leaderboard(
  p_user_uuid TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := (NOW() AT TIME ZONE 'UTC')::DATE;
  v_week_key TEXT := public.iso_week_key(v_today);
  v_week_start DATE := public.iso_week_start(v_today);
  v_week_end DATE := v_week_start + 6;
  v_limit INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100);
BEGIN
  RETURN jsonb_build_object(
    'ok', TRUE,
    'week_key', v_week_key,
    'week_start', v_week_start,
    'week_end', v_week_end,
    'entries', COALESCE((
      WITH week_dates AS (
        SELECT generate_series(v_week_start, v_week_end, '1 day'::interval)::date AS puzzle_date
      ),
      totals AS (
        SELECT
          wds.user_uuid,
          SUM(wds.daily_score) AS total_score,
          COUNT(*) FILTER (WHERE wds.daily_score > 0) AS days_played,
          SUM(wds.hints_used) AS total_hints,
          SUM(wds.mistakes) AS total_mistakes,
          MAX(wds.completed_at) AS last_completed_at
        FROM public.weekly_daily_scores wds
        WHERE wds.week_key = v_week_key
        GROUP BY wds.user_uuid
        HAVING SUM(wds.daily_score) > 0
      ),
      ranked AS (
        SELECT
          ROW_NUMBER() OVER (
            ORDER BY
              t.total_score DESC,
              t.total_hints ASC,
              t.total_mistakes ASC,
              t.last_completed_at ASC
          ) AS rank,
          t.user_uuid,
          public.resolve_player_display_name(u.display_name, t.user_uuid) AS display_name,
          t.total_score,
          t.days_played,
          t.total_hints,
          t.total_mistakes,
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'date', wd.puzzle_date,
                'score', COALESCE(wds.daily_score, 0)
              )
              ORDER BY wd.puzzle_date
            )
            FROM week_dates wd
            LEFT JOIN public.weekly_daily_scores wds
              ON wds.week_key = v_week_key
             AND wds.user_uuid = t.user_uuid
             AND wds.puzzle_date = wd.puzzle_date
          ) AS daily_scores
        FROM totals t
        JOIN public.users u ON u.user_uuid = t.user_uuid
      )
      SELECT jsonb_agg(
        jsonb_build_object(
          'rank', ranked.rank,
          'user_uuid', ranked.user_uuid,
          'display_name', ranked.display_name,
          'total_score', ranked.total_score,
          'days_played', ranked.days_played,
          'total_hints', ranked.total_hints,
          'total_mistakes', ranked.total_mistakes,
          'daily_scores', ranked.daily_scores
        )
        ORDER BY ranked.rank
      )
      FROM ranked
      WHERE ranked.rank <= v_limit
    ), '[]'::JSONB),
    'my_entry', (
      WITH week_dates AS (
        SELECT generate_series(v_week_start, v_week_end, '1 day'::interval)::date AS puzzle_date
      ),
      totals AS (
        SELECT
          wds.user_uuid,
          SUM(wds.daily_score) AS total_score,
          COUNT(*) FILTER (WHERE wds.daily_score > 0) AS days_played,
          SUM(wds.hints_used) AS total_hints,
          SUM(wds.mistakes) AS total_mistakes,
          MAX(wds.completed_at) AS last_completed_at
        FROM public.weekly_daily_scores wds
        WHERE wds.week_key = v_week_key
        GROUP BY wds.user_uuid
        HAVING SUM(wds.daily_score) > 0
      ),
      ranked AS (
        SELECT
          ROW_NUMBER() OVER (
            ORDER BY
              t.total_score DESC,
              t.total_hints ASC,
              t.total_mistakes ASC,
              t.last_completed_at ASC
          ) AS rank,
          t.user_uuid,
          public.resolve_player_display_name(u.display_name, t.user_uuid) AS display_name,
          t.total_score,
          t.days_played,
          t.total_hints,
          t.total_mistakes,
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'date', wd.puzzle_date,
                'score', COALESCE(wds.daily_score, 0)
              )
              ORDER BY wd.puzzle_date
            )
            FROM week_dates wd
            LEFT JOIN public.weekly_daily_scores wds
              ON wds.week_key = v_week_key
             AND wds.user_uuid = t.user_uuid
             AND wds.puzzle_date = wd.puzzle_date
          ) AS daily_scores
        FROM totals t
        JOIN public.users u ON u.user_uuid = t.user_uuid
      )
      SELECT jsonb_build_object(
        'rank', ranked.rank,
        'user_uuid', ranked.user_uuid,
        'display_name', ranked.display_name,
        'total_score', ranked.total_score,
        'days_played', ranked.days_played,
        'total_hints', ranked.total_hints,
        'total_mistakes', ranked.total_mistakes,
        'daily_scores', ranked.daily_scores
      )
      FROM ranked
      WHERE p_user_uuid IS NOT NULL
        AND ranked.user_uuid = p_user_uuid
      LIMIT 1
    )
  );
END;
$$;
