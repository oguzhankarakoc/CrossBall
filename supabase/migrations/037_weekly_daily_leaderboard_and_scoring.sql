-- Weekly daily leaderboard (ISO week, Mon–Sun UTC) + mistake-adjusted fair scoring.

-- =============================================================================
-- 1. Fair scoring: hints (-5) and mistakes (-15) reduce final_score
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
  v_rarity_score NUMERIC;
  v_hints INT;
  v_mistakes INT := 0;
  v_expected INT;
  v_completion_bonus INT := 0;
  v_base_cell CONSTANT INT := 12;
  v_rarity_multiplier CONSTANT NUMERIC := 0.45;
  v_completion_bonus_amount CONSTANT INT := 30;
  v_hint_penalty CONSTANT INT := 5;
  v_mistake_penalty CONSTANT INT := 15;
BEGIN
  SELECT ps.grid_size * ps.grid_size, COALESCE(ps.mistakes, 0)
  INTO v_expected, v_mistakes
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
    'mistakes', v_mistakes,
    'completion_bonus', v_completion_bonus,
    'final_score', GREATEST(
      0,
      v_total + v_completion_bonus - (v_hints * v_hint_penalty) - (v_mistakes * v_mistake_penalty)
    ),
    'correct_count', v_correct,
    'rare_count', v_rare,
    'legendary_count', v_legendary,
    'mythic_count', v_mythic,
    'is_perfect', (v_hints = 0 AND v_mistakes = 0 AND v_expected > 0 AND v_correct >= v_expected)
  );
END;
$$;

-- =============================================================================
-- 2. Weekly daily score ledger (resets each ISO week via week_key partition)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.weekly_daily_scores (
  week_key TEXT NOT NULL,
  user_uuid TEXT NOT NULL,
  puzzle_date DATE NOT NULL,
  daily_score NUMERIC NOT NULL DEFAULT 0,
  hints_used INT NOT NULL DEFAULT 0,
  mistakes INT NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (week_key, user_uuid, puzzle_date)
);

CREATE INDEX IF NOT EXISTS idx_weekly_daily_scores_week_user
  ON public.weekly_daily_scores (week_key, user_uuid);

ALTER TABLE public.weekly_daily_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_daily_scores FORCE ROW LEVEL SECURITY;

REVOKE ALL ON public.weekly_daily_scores FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.iso_week_key(p_date DATE DEFAULT (NOW() AT TIME ZONE 'UTC')::DATE)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT to_char(p_date, 'IYYY-"W"IW');
$$;

CREATE OR REPLACE FUNCTION public.iso_week_start(p_date DATE DEFAULT (NOW() AT TIME ZONE 'UTC')::DATE)
RETURNS DATE
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT (date_trunc('week', p_date::timestamp AT TIME ZONE 'UTC'))::date;
$$;

CREATE OR REPLACE FUNCTION public.upsert_weekly_daily_score(
  p_user_uuid TEXT,
  p_puzzle_date DATE,
  p_score NUMERIC,
  p_hints INT DEFAULT 0,
  p_mistakes INT DEFAULT 0,
  p_completed_at TIMESTAMPTZ DEFAULT NOW()
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_week_key TEXT := public.iso_week_key(p_puzzle_date);
BEGIN
  IF p_user_uuid IS NULL OR TRIM(p_user_uuid) = '' OR p_puzzle_date IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.weekly_daily_scores (
    week_key,
    user_uuid,
    puzzle_date,
    daily_score,
    hints_used,
    mistakes,
    completed_at
  )
  VALUES (
    v_week_key,
    p_user_uuid,
    p_puzzle_date,
    GREATEST(0, COALESCE(p_score, 0)),
    GREATEST(0, COALESCE(p_hints, 0)),
    GREATEST(0, COALESCE(p_mistakes, 0)),
    COALESCE(p_completed_at, NOW())
  )
  ON CONFLICT (week_key, user_uuid, puzzle_date) DO UPDATE
  SET
    daily_score = EXCLUDED.daily_score,
    hints_used = EXCLUDED.hints_used,
    mistakes = EXCLUDED.mistakes,
    completed_at = EXCLUDED.completed_at;
END;
$$;

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
          COALESCE(NULLIF(TRIM(u.display_name), ''), 'Player') AS display_name,
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
          COALESCE(NULLIF(TRIM(u.display_name), ''), 'Player') AS display_name,
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

INSERT INTO public.weekly_daily_scores (
  week_key,
  user_uuid,
  puzzle_date,
  daily_score,
  hints_used,
  mistakes,
  completed_at
)
SELECT
  public.iso_week_key(p.puzzle_date),
  u.user_uuid,
  p.puzzle_date,
  ps.final_score,
  COALESCE(ps.hints_used, 0),
  COALESCE(ps.mistakes, 0),
  ps.completed_at
FROM public.puzzle_sessions ps
JOIN public.users u ON u.id = ps.user_id
JOIN public.puzzles p ON p.id = ps.puzzle_id
WHERE ps.mode = 'daily'
  AND ps.status = 'completed'
  AND COALESCE(ps.is_suspicious, FALSE) = FALSE
  AND ps.completed_at IS NOT NULL
  AND p.puzzle_date >= public.iso_week_start((NOW() AT TIME ZONE 'UTC')::DATE)
  AND p.puzzle_date <= public.iso_week_start((NOW() AT TIME ZONE 'UTC')::DATE) + 6
ON CONFLICT (week_key, user_uuid, puzzle_date) DO UPDATE
SET
  daily_score = EXCLUDED.daily_score,
  hints_used = EXCLUDED.hints_used,
  mistakes = EXCLUDED.mistakes,
  completed_at = EXCLUDED.completed_at;

REVOKE ALL ON FUNCTION public.iso_week_key(DATE) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.iso_week_start(DATE) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.upsert_weekly_daily_score(TEXT, DATE, NUMERIC, INT, INT, TIMESTAMPTZ) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.get_weekly_daily_leaderboard(TEXT, INT) FROM anon, authenticated;
