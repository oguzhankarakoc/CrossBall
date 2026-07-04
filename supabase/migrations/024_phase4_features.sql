-- Phase 4: timeline mode, activity feed, football facts, tournament, matchday events.

-- =============================================================================
-- 1. Extend puzzle_mode for timeline sessions
-- =============================================================================

ALTER TYPE puzzle_mode ADD VALUE IF NOT EXISTS 'timeline';

-- =============================================================================
-- 2. Community activity feed
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.player_activity_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_uuid TEXT NOT NULL,
  display_name TEXT NOT NULL DEFAULT 'Player',
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_player_activity_created
  ON public.player_activity_events (created_at DESC);

ALTER TABLE public.player_activity_events ENABLE ROW LEVEL SECURITY;

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
BEGIN
  IF p_user_uuid IS NULL OR length(p_user_uuid) < 8 THEN
    RETURN;
  END IF;

  SELECT COALESCE(NULLIF(TRIM(u.display_name), ''), 'Player')
  INTO v_name
  FROM users u
  WHERE u.user_uuid = p_user_uuid
  LIMIT 1;

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
          'display_name', e.display_name,
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

-- =============================================================================
-- 3. Curated football facts (AI-style trivia)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.football_facts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fact_key TEXT NOT NULL UNIQUE,
  fact_en TEXT NOT NULL,
  fact_tr TEXT,
  fact_de TEXT,
  metadata JSONB NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.football_facts (fact_key, fact_en, fact_tr, fact_de, metadata)
VALUES
  (
    'intersection_rare_default',
    'Players who played for both clubs are rarer than you think — that is why uncommon picks score higher.',
    'Her iki kulüpte oynayan futbolcular sandığından daha nadir — nadir seçimler daha çok puan verir.',
    'Spieler, die für beide Vereine spielten, sind seltener als man denkt — deshalb zählen seltene Tipps mehr.',
    '{"type": "intersection"}'::JSONB
  ),
  (
    'timeline_mode_tip',
    'Timeline mode reveals career years after each correct answer — train your football memory.',
    'Zaman çizelgesi modu her doğru cevaptan sonra kariyer yıllarını gösterir.',
    'Timeline-Modus zeigt nach jeder richtigen Antwort Karrierejahre.',
    '{"type": "timeline"}'::JSONB
  ),
  (
    'matchday_boost',
    'Matchday weekends often feature themed puzzles with bonus season points.',
    'Maç günü hafta sonları bonus sezon puanlı temalı bulmacalar sunar.',
    'An Spieltag-Wochenenden gibt es oft thematische Rätsel mit Bonus-Saisonpunkten.',
    '{"type": "matchday"}'::JSONB
  )
ON CONFLICT (fact_key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.get_football_fact(
  p_locale TEXT DEFAULT 'en',
  p_context TEXT DEFAULT 'intersection'
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row football_facts%ROWTYPE;
  v_text TEXT;
BEGIN
  SELECT * INTO v_row
  FROM football_facts
  WHERE is_active = TRUE
    AND (metadata->>'type' = p_context OR p_context = 'any')
  ORDER BY random()
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', FALSE);
  END IF;

  v_text := CASE lower(COALESCE(p_locale, 'en'))
    WHEN 'tr' THEN COALESCE(v_row.fact_tr, v_row.fact_en)
    WHEN 'de' THEN COALESCE(v_row.fact_de, v_row.fact_en)
    ELSE v_row.fact_en
  END;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'fact_key', v_row.fact_key,
    'fact', v_text
  );
END;
$$;

-- =============================================================================
-- 4. Tournament standings
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.tournament_scores (
  tournament_slug TEXT NOT NULL,
  user_uuid TEXT NOT NULL,
  display_name TEXT NOT NULL DEFAULT 'Player',
  best_score NUMERIC NOT NULL DEFAULT 0,
  sessions_count INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (tournament_slug, user_uuid)
);

CREATE INDEX IF NOT EXISTS idx_tournament_scores_rank
  ON public.tournament_scores (tournament_slug, best_score DESC);

ALTER TABLE public.tournament_scores ENABLE ROW LEVEL SECURITY;

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
BEGIN
  IF p_tournament_slug IS NULL OR p_user_uuid IS NULL THEN
    RETURN;
  END IF;

  SELECT COALESCE(NULLIF(TRIM(u.display_name), ''), 'Player')
  INTO v_name
  FROM users u
  WHERE u.user_uuid = p_user_uuid
  LIMIT 1;

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
          'display_name', t.display_name,
          'best_score', t.best_score,
          'sessions_count', t.sessions_count
        )
        ORDER BY t.rank
      )
      FROM (
        SELECT
          ROW_NUMBER() OVER (ORDER BY best_score DESC, updated_at ASC)::INT AS rank,
          display_name,
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

CREATE OR REPLACE FUNCTION public.get_active_tournament()
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
        'slug', e.slug,
        'title', COALESCE(i.title, e.slug),
        'description', COALESCE(i.description, ''),
        'ends_at', e.ends_at
      )
      FROM liveops_events e
      LEFT JOIN liveops_event_i18n i ON i.event_slug = e.slug AND i.locale = 'en'
      WHERE e.is_active = TRUE
        AND e.event_type = 'tournament'
        AND e.starts_at <= NOW()
        AND e.ends_at >= NOW()
      ORDER BY e.sort_order, e.starts_at DESC
      LIMIT 1
    ),
    jsonb_build_object('ok', FALSE)
  );
$$;

-- =============================================================================
-- 5. Career timeline for timeline mode
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_player_career_timeline(
  p_player_id UUID,
  p_row_club_id UUID,
  p_col_club_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_player_name TEXT;
BEGIN
  SELECT name INTO v_player_name FROM players WHERE id = p_player_id;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'player_name', COALESCE(v_player_name, 'Player'),
    'entries', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'club_id', x.club_id,
          'club_name', x.club_name,
          'start_year', x.start_year,
          'end_year', x.end_year,
          'highlight', x.highlight
        )
        ORDER BY x.start_year NULLS LAST, x.club_name
      )
      FROM (
        SELECT
          pch.club_id,
          COALESCE(c.short_name, c.display_name, c.name) AS club_name,
          EXTRACT(YEAR FROM pch.start_date)::INT AS start_year,
          CASE
            WHEN pch.end_date IS NULL THEN NULL
            ELSE EXTRACT(YEAR FROM pch.end_date)::INT
          END AS end_year,
          (pch.club_id = p_row_club_id OR pch.club_id = p_col_club_id) AS highlight
        FROM player_career_history pch
        JOIN clubs c ON c.id = pch.club_id
        WHERE pch.player_id = p_player_id
          AND pch.is_senior = TRUE
          AND pch.is_youth = FALSE
          AND pch.is_reserve = FALSE
      ) x
    ), '[]'::JSONB)
  );
END;
$$;

-- =============================================================================
-- 6. Feature flags + matchday / tournament event seeds
-- =============================================================================

INSERT INTO liveops_feature_flags (slug, label, description, is_enabled, rollout, default_value, sort_order)
VALUES
  ('friend_activity_feed', 'Activity Feed', 'Community activity feed on home', TRUE, '{"type": "global", "enabled": true}', TRUE, 50),
  ('ai_features', 'AI Facts', 'Football trivia facts in gameplay', TRUE, '{"type": "global", "enabled": true}', TRUE, 51),
  ('timeline_mode', 'Timeline Mode', 'Career timeline training mode', TRUE, '{"type": "global", "enabled": true}', TRUE, 52)
ON CONFLICT (slug) DO UPDATE SET is_enabled = EXCLUDED.is_enabled;

UPDATE liveops_feature_flags SET is_enabled = TRUE WHERE slug = 'tournament_mode';

INSERT INTO liveops_events (
  slug, event_type, starts_at, ends_at, is_active, metadata, sort_order
)
VALUES
  (
    'matchday-weekend',
    'calendar',
    TIMESTAMPTZ '2026-01-01 00:00:00+00',
    TIMESTAMPTZ '2027-12-31 23:59:59+00',
    TRUE,
    '{"matchday": true, "bonus_season_points": 25}'::JSONB,
    5
  ),
  (
    'weekly-tournament',
    'tournament',
    TIMESTAMPTZ '2026-01-01 00:00:00+00',
    TIMESTAMPTZ '2027-12-31 23:59:59+00',
    TRUE,
    '{"min_score": 0}'::JSONB,
    10
  )
ON CONFLICT (slug) DO UPDATE SET is_active = EXCLUDED.is_active;

INSERT INTO liveops_event_i18n (event_slug, locale, title, description, cta_label)
VALUES
  ('matchday-weekend', 'en', 'Matchday Weekend', 'Themed puzzles with bonus season points every weekend.', 'Play'),
  ('matchday-weekend', 'tr', 'Maç Günü Hafta Sonu', 'Her hafta sonu bonus sezon puanlı temalı bulmacalar.', 'Oyna'),
  ('matchday-weekend', 'de', 'Spieltag-Wochenende', 'Themenrätsel mit Bonus-Saisonpunkten an Wochenenden.', 'Spielen'),
  ('weekly-tournament', 'en', 'Weekly Tournament', 'Compete for the highest score this week.', 'Leaderboard'),
  ('weekly-tournament', 'tr', 'Haftalık Turnuva', 'Bu haftanın en yüksek skoru için yarış.', 'Sıralama'),
  ('weekly-tournament', 'de', 'Wöchentliches Turnier', 'Wetteifere um die höchste Punktzahl diese Woche.', 'Rangliste')
ON CONFLICT (event_slug, locale) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  cta_label = EXCLUDED.cta_label;
