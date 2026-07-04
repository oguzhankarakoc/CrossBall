-- Phase 3: club mastery, season seed, career hint taste, active season helpers.

-- =============================================================================
-- 1. Active season seed
-- =============================================================================

INSERT INTO economy_seasons (slug, label, starts_at, ends_at, is_active, reward_tiers)
VALUES (
  '2026-s1',
  'Season 1',
  TIMESTAMPTZ '2026-01-01 00:00:00+00',
  TIMESTAMPTZ '2026-06-30 23:59:59+00',
  TRUE,
  '{"tiers": [{"points": 100, "reward": "badge"}, {"points": 500, "reward": "frame"}, {"points": 1500, "reward": "theme"}]}'::JSONB
)
ON CONFLICT (slug) DO UPDATE SET is_active = EXCLUDED.is_active;

-- =============================================================================
-- 2. Weekly free career-club hint taste (1 per ISO week)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.user_hint_taste_usage (
  user_uuid TEXT NOT NULL,
  week_key TEXT NOT NULL,
  used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_uuid, week_key)
);

ALTER TABLE public.user_hint_taste_usage ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.consume_career_hint_taste(p_user_uuid TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_week TEXT := to_char(CURRENT_DATE, 'IYYY-"W"IW');
BEGIN
  IF p_user_uuid IS NULL OR length(p_user_uuid) < 8 THEN
    RETURN FALSE;
  END IF;

  INSERT INTO user_hint_taste_usage (user_uuid, week_key)
  VALUES (p_user_uuid, v_week)
  ON CONFLICT (user_uuid, week_key) DO NOTHING;

  RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION public.career_hint_taste_available(p_user_uuid TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM user_hint_taste_usage
    WHERE user_uuid = p_user_uuid
      AND week_key = to_char(CURRENT_DATE, 'IYYY-"W"IW')
  );
$$;

-- =============================================================================
-- 3. Club mastery — intersections solved per club
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_club_mastery(
  p_user_uuid TEXT,
  p_limit INT DEFAULT 12
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_limit INT := LEAST(GREATEST(COALESCE(p_limit, 12), 1), 50);
BEGIN
  SELECT id INTO v_user_id FROM users WHERE user_uuid = p_user_uuid LIMIT 1;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'clubs', '[]'::JSONB);
  END IF;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'clubs', COALESCE((
      WITH club_hits AS (
        SELECT c.id AS club_id,
               COALESCE(c.display_name, c.name) AS club_name,
               COALESCE(c.short_name, c.name) AS short_name
        FROM answers a
        JOIN puzzle_sessions ps ON ps.id = a.session_id
        JOIN puzzle_cells pc ON pc.id = a.puzzle_cell_id
        JOIN puzzle_row_clubs prc ON prc.puzzle_id = pc.puzzle_id AND prc.row_index = pc.row_index
        JOIN clubs c ON c.id = prc.club_id
        WHERE ps.user_id = v_user_id AND a.is_correct = TRUE
        UNION ALL
        SELECT c.id,
               COALESCE(c.display_name, c.name),
               COALESCE(c.short_name, c.name)
        FROM answers a
        JOIN puzzle_sessions ps ON ps.id = a.session_id
        JOIN puzzle_cells pc ON pc.id = a.puzzle_cell_id
        JOIN puzzle_col_clubs pcc ON pcc.puzzle_id = pc.puzzle_id AND pcc.col_index = pc.col_index
        JOIN clubs c ON c.id = pcc.club_id
        WHERE ps.user_id = v_user_id AND a.is_correct = TRUE
      )
      SELECT jsonb_agg(
        jsonb_build_object(
          'club_id', t.club_id,
          'club_name', t.club_name,
          'short_name', t.short_name,
          'intersections_solved', t.cnt
        )
        ORDER BY t.cnt DESC, t.club_name
      )
      FROM (
        SELECT club_id, club_name, short_name, COUNT(*)::INT AS cnt
        FROM club_hits
        GROUP BY club_id, club_name, short_name
        ORDER BY cnt DESC, club_name
        LIMIT v_limit
      ) t
    ), '[]'::JSONB)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_active_season()
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (
      SELECT jsonb_build_object(
        'ok', TRUE,
        'slug', s.slug,
        'label', s.label,
        'starts_at', s.starts_at,
        'ends_at', s.ends_at,
        'reward_tiers', s.reward_tiers
      )
      FROM economy_seasons s
      WHERE s.is_active = TRUE
      ORDER BY s.starts_at DESC
      LIMIT 1
    ),
    jsonb_build_object('ok', FALSE)
  );
$$;
