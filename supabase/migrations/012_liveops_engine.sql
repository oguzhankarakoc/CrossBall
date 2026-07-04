-- LiveOps Engine (LOE) — remote config, events, feature flags, announcements.
-- Independent from Puzzle / Club / Football Knowledge / Game Economy engines.

-- =============================================================================
-- REMOTE CONFIGURATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS liveops_config (
  key         TEXT PRIMARY KEY,
  value       JSONB NOT NULL,
  category    TEXT NOT NULL DEFAULT 'general',
  description TEXT,
  is_emergency BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- FEATURE FLAGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS liveops_feature_flags (
  slug          TEXT PRIMARY KEY,
  label         TEXT NOT NULL,
  description   TEXT,
  is_enabled    BOOLEAN NOT NULL DEFAULT TRUE,
  rollout       JSONB NOT NULL DEFAULT '{"type": "global", "enabled": true}',
  default_value BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order    INT NOT NULL DEFAULT 0,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- EVENTS (daily / weekly / monthly / seasonal / tournament / calendar)
-- =============================================================================

CREATE TYPE liveops_event_type AS ENUM (
  'daily', 'weekly', 'monthly', 'seasonal', 'tournament',
  'calendar', 'limited', 'community', 'global'
);

CREATE TABLE IF NOT EXISTS liveops_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT UNIQUE NOT NULL,
  event_type      liveops_event_type NOT NULL DEFAULT 'limited',
  starts_at       TIMESTAMPTZ NOT NULL,
  ends_at         TIMESTAMPTZ NOT NULL,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  puzzle_pool     JSONB NOT NULL DEFAULT '{}',
  club_filters    JSONB NOT NULL DEFAULT '{}',
  player_filters  JSONB NOT NULL DEFAULT '{}',
  rewards         JSONB NOT NULL DEFAULT '{}',
  leaderboard_config JSONB NOT NULL DEFAULT '{}',
  achievement_slugs JSONB NOT NULL DEFAULT '[]',
  theme           JSONB NOT NULL DEFAULT '{}',
  metadata        JSONB NOT NULL DEFAULT '{}',
  sort_order      INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS liveops_event_i18n (
  event_slug  TEXT NOT NULL REFERENCES liveops_events(slug) ON DELETE CASCADE,
  locale      TEXT NOT NULL,
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  cta_label   TEXT,
  PRIMARY KEY (event_slug, locale)
);

-- =============================================================================
-- FOOTBALL CALENDAR TEMPLATES (auto-activation rules)
-- =============================================================================

CREATE TABLE IF NOT EXISTS liveops_football_calendar (
  slug            TEXT PRIMARY KEY,
  label           TEXT NOT NULL,
  recurrence_rule TEXT NOT NULL,
  event_template  JSONB NOT NULL,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  lead_days       INT NOT NULL DEFAULT 7,
  duration_days   INT NOT NULL DEFAULT 14
);

-- =============================================================================
-- PUZZLE COLLECTIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS liveops_puzzle_collections (
  slug            TEXT PRIMARY KEY,
  is_featured     BOOLEAN NOT NULL DEFAULT FALSE,
  puzzle_ids      JSONB NOT NULL DEFAULT '[]',
  club_slugs      JSONB NOT NULL DEFAULT '[]',
  filters         JSONB NOT NULL DEFAULT '{}',
  rewards         JSONB NOT NULL DEFAULT '{}',
  starts_at       TIMESTAMPTZ,
  ends_at         TIMESTAMPTZ,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS liveops_collection_i18n (
  collection_slug TEXT NOT NULL REFERENCES liveops_puzzle_collections(slug) ON DELETE CASCADE,
  locale          TEXT NOT NULL,
  title           TEXT NOT NULL,
  description     TEXT NOT NULL,
  PRIMARY KEY (collection_slug, locale)
);

-- =============================================================================
-- COMMUNITY GOALS
-- =============================================================================

CREATE TABLE IF NOT EXISTS liveops_community_goals (
  slug            TEXT PRIMARY KEY,
  metric          TEXT NOT NULL,
  target_value    BIGINT NOT NULL,
  current_value   BIGINT NOT NULL DEFAULT 0,
  starts_at       TIMESTAMPTZ NOT NULL,
  ends_at         TIMESTAMPTZ NOT NULL,
  reward_payload  JSONB NOT NULL DEFAULT '{}',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  is_unlocked     BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS liveops_community_goal_i18n (
  goal_slug   TEXT NOT NULL REFERENCES liveops_community_goals(slug) ON DELETE CASCADE,
  locale      TEXT NOT NULL,
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  PRIMARY KEY (goal_slug, locale)
);

-- =============================================================================
-- A/B EXPERIMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS liveops_ab_experiments (
  slug            TEXT PRIMARY KEY,
  label           TEXT NOT NULL,
  description     TEXT,
  variants        JSONB NOT NULL,
  traffic_pct     INT NOT NULL DEFAULT 100 CHECK (traffic_pct BETWEEN 0 AND 100),
  is_active       BOOLEAN NOT NULL DEFAULT FALSE,
  starts_at       TIMESTAMPTZ,
  ends_at         TIMESTAMPTZ,
  metadata        JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS liveops_ab_assignments (
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  experiment_slug TEXT NOT NULL REFERENCES liveops_ab_experiments(slug) ON DELETE CASCADE,
  variant         TEXT NOT NULL,
  assigned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, experiment_slug)
);

-- =============================================================================
-- ANNOUNCEMENTS
-- =============================================================================

CREATE TYPE liveops_announcement_type AS ENUM (
  'info', 'maintenance', 'feature', 'event', 'competition', 'patch', 'promotion'
);

CREATE TABLE IF NOT EXISTS liveops_announcements (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT UNIQUE NOT NULL,
  announcement_type liveops_announcement_type NOT NULL DEFAULT 'info',
  image_url       TEXT,
  deep_link       TEXT,
  button_action   JSONB NOT NULL DEFAULT '{}',
  priority        INT NOT NULL DEFAULT 0,
  starts_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ends_at         TIMESTAMPTZ,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  target_platforms JSONB NOT NULL DEFAULT '["ios", "android"]',
  target_countries JSONB NOT NULL DEFAULT '[]',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS liveops_announcement_i18n (
  announcement_slug TEXT NOT NULL,
  locale            TEXT NOT NULL,
  title             TEXT NOT NULL,
  body              TEXT NOT NULL,
  button_label      TEXT,
  PRIMARY KEY (announcement_slug, locale),
  FOREIGN KEY (announcement_slug) REFERENCES liveops_announcements(slug) ON DELETE CASCADE
);

-- =============================================================================
-- CONTENT ROTATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS liveops_content_rotation (
  slot_slug       TEXT PRIMARY KEY,
  label           TEXT NOT NULL,
  items           JSONB NOT NULL DEFAULT '[]',
  rotation_hours  INT NOT NULL DEFAULT 24,
  last_rotated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

-- =============================================================================
-- ANALYTICS LOG
-- =============================================================================

CREATE TABLE IF NOT EXISTS liveops_analytics_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES users(id) ON DELETE SET NULL,
  event_type    TEXT NOT NULL,
  payload       JSONB NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_liveops_events_active
  ON liveops_events (starts_at, ends_at) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_liveops_announcements_active
  ON liveops_announcements (starts_at, ends_at) WHERE is_active = TRUE;

-- =============================================================================
-- SEED: remote config defaults
-- =============================================================================

INSERT INTO liveops_config (key, value, category, description) VALUES
  ('gameplay', '{
    "available_modes": ["daily", "practice", "challenge"],
    "default_difficulty_tier": "medium",
    "puzzle_frequency_daily": 1,
    "hint_cost_multiplier": 1.0,
    "max_hints_per_cell": 6
  }', 'gameplay', 'Core gameplay parameters'),
  ('rewards', '{
    "xp_multiplier_override": null,
    "daily_reward_enabled": true,
    "challenge_reward_multiplier": 1.0
  }', 'economy', 'LiveOps reward overrides (null = use GEE config)'),
  ('ads', '{
    "interstitial_enabled": true,
    "rewarded_enabled": true,
    "banner_enabled": true,
    "interstitial_every_n_practice": 3
  }', 'monetization', 'Ad placement config'),
  ('themes', '{
    "available": ["light_pitch", "dark_stadium"],
    "featured_theme": "light_pitch"
  }', 'cosmetic', 'Available UI themes'),
  ('clubs', '{
    "featured_club_slugs": ["barcelona", "real-madrid", "manchester-united"],
    "club_pool_override": null
  }', 'content', 'Featured clubs and pool overrides'),
  ('season', '{
    "current_season_slug": null,
    "season_banner_enabled": false
  }', 'season', 'Active season display'),
  ('emergency', '{
    "maintenance_mode": false,
    "disable_new_sessions": false,
    "message": null
  }', 'emergency', 'Emergency overrides')
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = NOW();

-- =============================================================================
-- SEED: feature flags (all enabled globally by default)
-- =============================================================================

INSERT INTO liveops_feature_flags (slug, label, description, rollout) VALUES
  ('friend_challenges', 'Friend Challenges', 'Async friend challenges', '{"type": "global", "enabled": true}'),
  ('grid_4x4', '4×4 Grid Mode', 'Premium 4×4 puzzles', '{"type": "global", "enabled": true}'),
  ('new_themes', 'New Themes', 'Additional UI themes', '{"type": "global", "enabled": true}'),
  ('experimental_puzzle_generator', 'Experimental Generator', 'A/B puzzle generation', '{"type": "percentage", "enabled": true, "percentage": 0}'),
  ('special_events', 'Special Events', 'Limited-time events UI', '{"type": "global", "enabled": true}'),
  ('premium_features', 'Premium Features', 'Premium upsell and features', '{"type": "global", "enabled": true}'),
  ('tournament_mode', 'Tournament Mode', 'Tournament events', '{"type": "global", "enabled": false}'),
  ('leaderboards', 'Leaderboards', 'Competitive leaderboards', '{"type": "global", "enabled": true}'),
  ('achievements', 'Achievements', 'Achievement system display', '{"type": "global", "enabled": true}'),
  ('statistics', 'Statistics', 'Stats screen', '{"type": "global", "enabled": true}'),
  ('ai_features', 'AI Features', 'Future AI capabilities', '{"type": "global", "enabled": false}')
ON CONFLICT (slug) DO NOTHING;

-- =============================================================================
-- SEED: football calendar templates
-- =============================================================================

INSERT INTO liveops_football_calendar (slug, label, recurrence_rule, event_template, lead_days, duration_days) VALUES
  ('world_cup', 'FIFA World Cup', 'every_4_years_june', '{"theme": "world_cup", "event_type": "calendar"}', 14, 30),
  ('euro', 'UEFA European Championship', 'every_4_years_june', '{"theme": "euro", "event_type": "calendar"}', 14, 30),
  ('ucl_final', 'Champions League Final', 'annual_may', '{"theme": "ucl", "event_type": "calendar"}', 7, 7),
  ('transfer_window', 'Transfer Window', 'biannual', '{"theme": "transfers", "event_type": "calendar"}', 0, 60),
  ('ballon_dor', 'Ballon d''Or', 'annual_october', '{"theme": "ballon_dor", "event_type": "calendar"}', 7, 14)
ON CONFLICT (slug) DO NOTHING;

-- =============================================================================
-- SEED: sample limited event + collection + community goal + announcement
-- =============================================================================

INSERT INTO liveops_events (slug, event_type, starts_at, ends_at, theme, metadata) VALUES
  ('champions_league_week', 'limited', NOW() - INTERVAL '1 day', NOW() + INTERVAL '6 days',
   '{"accent_color": "#003399", "banner_key": "ucl"}',
   '{"league_filter": "champions_league"}')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO liveops_event_i18n (event_slug, locale, title, description, cta_label) VALUES
  ('champions_league_week', 'en', 'Champions League Week', 'Special UCL-themed puzzles all week.', 'Play Now'),
  ('champions_league_week', 'tr', 'Şampiyonlar Ligi Haftası', 'Hafta boyunca özel ŞL bulmacaları.', 'Oyna'),
  ('champions_league_week', 'de', 'Champions-League-Woche', 'Spezielle CL-Rätsel die ganze Woche.', 'Spielen')
ON CONFLICT DO NOTHING;

INSERT INTO liveops_puzzle_collections (slug, is_featured, club_slugs, sort_order) VALUES
  ('premier_league_collection', TRUE, '["manchester-united", "liverpool", "arsenal", "chelsea"]', 1),
  ('legends_collection', TRUE, '[]', 2)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO liveops_collection_i18n (collection_slug, locale, title, description) VALUES
  ('premier_league_collection', 'en', 'Premier League Collection', 'Curated puzzles from England''s top flight.'),
  ('premier_league_collection', 'tr', 'Premier League Koleksiyonu', 'İngiltere''nin en üst liginden seçilmiş bulmacalar.'),
  ('premier_league_collection', 'de', 'Premier-League-Sammlung', 'Kuratierte Rätsel aus der Premier League.'),
  ('legends_collection', 'en', 'Club Legends', 'Iconic players across legendary clubs.'),
  ('legends_collection', 'tr', 'Kulüp Efsaneleri', 'Efsanevi kulüplerden ikonik oyuncular.'),
  ('legends_collection', 'de', 'Vereinslegenden', 'Ikone Spieler legendärer Vereine.')
ON CONFLICT DO NOTHING;

INSERT INTO liveops_community_goals (slug, metric, target_value, starts_at, ends_at) VALUES
  ('global_puzzles_1m', 'puzzles_completed', 1000000, NOW(), NOW() + INTERVAL '90 days')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO liveops_community_goal_i18n (goal_slug, locale, title, description) VALUES
  ('global_puzzles_1m', 'en', '1 Million Puzzles', 'Help the community solve 1 million puzzles worldwide.'),
  ('global_puzzles_1m', 'tr', '1 Milyon Bulmaca', 'Dünya genelinde 1 milyon bulmaca çözülmesine katkı sağla.'),
  ('global_puzzles_1m', 'de', '1 Million Rätsel', 'Hilf der Community, 1 Million Rätsel weltweit zu lösen.')
ON CONFLICT DO NOTHING;

INSERT INTO liveops_announcements (slug, announcement_type, priority, deep_link) VALUES
  ('welcome_liveops', 'feature', 10, '/puzzle?mode=daily')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO liveops_announcement_i18n (announcement_slug, locale, title, body, button_label) VALUES
  ('welcome_liveops', 'en', 'CrossBall Live', 'New events and challenges drop regularly — no app update needed.', 'Play Daily'),
  ('welcome_liveops', 'tr', 'CrossBall Canlı', 'Yeni etkinlikler düzenli geliyor — uygulama güncellemesi gerekmez.', 'Günlük Oyna'),
  ('welcome_liveops', 'de', 'CrossBall Live', 'Neue Events erscheinen regelmäßig — kein App-Update nötig.', 'Täglich spielen')
ON CONFLICT DO NOTHING;

INSERT INTO liveops_content_rotation (slot_slug, label, items, rotation_hours) VALUES
  ('featured_clubs', 'Featured Clubs', '["barcelona", "real-madrid", "bayern-munchen", "manchester-city"]', 24),
  ('daily_theme', 'Daily Theme', '["classic", "legends", "transfers", "derbies"]', 24)
ON CONFLICT (slot_slug) DO NOTHING;

-- =============================================================================
-- HELPERS
-- =============================================================================

CREATE OR REPLACE FUNCTION public.loe_config(p_key TEXT)
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE((SELECT value FROM liveops_config WHERE key = p_key), '{}'::JSONB);
$$;

CREATE OR REPLACE FUNCTION public.loe_hash_bucket(p_seed TEXT, p_mod INT DEFAULT 100)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT abs(hashtext(p_seed)) % GREATEST(p_mod, 1);
$$;

CREATE OR REPLACE FUNCTION public.loe_evaluate_flag(
  p_slug TEXT,
  p_user_uuid TEXT,
  p_platform TEXT DEFAULT 'ios',
  p_country TEXT DEFAULT '',
  p_app_version TEXT DEFAULT '1.0.0'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_flag liveops_feature_flags;
  v_rollout JSONB;
  v_type TEXT;
  v_bucket INT;
BEGIN
  SELECT * INTO v_flag FROM liveops_feature_flags WHERE slug = p_slug;
  IF v_flag IS NULL THEN RETURN TRUE; END IF;
  IF NOT v_flag.is_enabled THEN RETURN v_flag.default_value; END IF;

  v_rollout := v_flag.rollout;
  v_type := COALESCE(v_rollout->>'type', 'global');

  IF v_type = 'global' THEN
    RETURN COALESCE((v_rollout->>'enabled')::BOOLEAN, TRUE);
  END IF;

  IF v_type = 'percentage' THEN
    IF NOT COALESCE((v_rollout->>'enabled')::BOOLEAN, FALSE) THEN RETURN FALSE; END IF;
    v_bucket := loe_hash_bucket(p_user_uuid || ':' || p_slug);
    RETURN v_bucket < COALESCE((v_rollout->>'percentage')::INT, 0);
  END IF;

  IF v_type = 'country' THEN
    RETURN p_country <> '' AND v_rollout->'countries' ? p_country;
  END IF;

  IF v_type = 'platform' THEN
    RETURN v_rollout->'platforms' ? lower(p_platform);
  END IF;

  IF v_type = 'version' THEN
    RETURN p_app_version >= COALESCE(v_rollout->>'min_version', '0.0.0')
       AND p_app_version <= COALESCE(v_rollout->>'max_version', '99.99.99');
  END IF;

  RETURN v_flag.default_value;
END;
$$;

CREATE OR REPLACE FUNCTION public.loe_current_rotation_item(p_slot_slug TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_slot liveops_content_rotation;
  v_items JSONB;
  v_count INT;
  v_index INT;
  v_hours INT;
  v_periods INT;
BEGIN
  SELECT * INTO v_slot FROM liveops_content_rotation
  WHERE slot_slug = p_slot_slug AND is_active = TRUE;

  IF v_slot IS NULL THEN RETURN NULL; END IF;

  v_items := v_slot.items;
  v_count := jsonb_array_length(v_items);
  IF v_count = 0 THEN RETURN NULL; END IF;

  v_hours := GREATEST(v_slot.rotation_hours, 1);
  v_periods := EXTRACT(EPOCH FROM (NOW() - v_slot.last_rotated_at))::INT / (v_hours * 3600);
  v_index := (v_periods % v_count);

  RETURN jsonb_build_object(
    'slot', p_slot_slug,
    'item', v_items->v_index,
    'index', v_index,
    'total', v_count
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.loe_assign_experiment(
  p_user_id UUID,
  p_experiment_slug TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_exp liveops_ab_experiments;
  v_existing TEXT;
  v_variants JSONB;
  v_keys TEXT[];
  v_chosen TEXT;
  v_bucket INT;
  v_i INT;
  v_weight INT;
  v_cumulative INT := 0;
BEGIN
  SELECT variant INTO v_existing
  FROM liveops_ab_assignments
  WHERE user_id = p_user_id AND experiment_slug = p_experiment_slug;

  IF v_existing IS NOT NULL THEN RETURN v_existing; END IF;

  SELECT * INTO v_exp FROM liveops_ab_experiments
  WHERE slug = p_experiment_slug AND is_active = TRUE
    AND (starts_at IS NULL OR starts_at <= NOW())
    AND (ends_at IS NULL OR ends_at >= NOW());

  IF v_exp IS NULL THEN RETURN 'control'; END IF;

  v_bucket := loe_hash_bucket(p_user_id::TEXT || ':' || p_experiment_slug);
  IF v_bucket >= v_exp.traffic_pct THEN RETURN 'control'; END IF;

  v_variants := v_exp.variants;
  SELECT array_agg(key ORDER BY key) INTO v_keys FROM jsonb_object_keys(v_variants) AS key;

  v_bucket := loe_hash_bucket(p_user_id::TEXT || ':' || p_experiment_slug || ':variant');
  FOR v_i IN 1..COALESCE(array_length(v_keys, 1), 0) LOOP
    v_chosen := v_keys[v_i];
    v_weight := COALESCE((v_variants->>v_chosen)::INT, 0);
    v_cumulative := v_cumulative + v_weight;
    IF v_bucket < v_cumulative THEN
      INSERT INTO liveops_ab_assignments (user_id, experiment_slug, variant)
      VALUES (p_user_id, p_experiment_slug, v_chosen)
      ON CONFLICT DO NOTHING;
      RETURN v_chosen;
    END IF;
  END LOOP;

  v_chosen := COALESCE(v_keys[1], 'control');
  INSERT INTO liveops_ab_assignments (user_id, experiment_slug, variant)
  VALUES (p_user_id, p_experiment_slug, v_chosen)
  ON CONFLICT DO NOTHING;
  RETURN v_chosen;
END;
$$;

-- =============================================================================
-- CORE: fetch LiveOps snapshot for client
-- =============================================================================

CREATE OR REPLACE FUNCTION public.loe_get_snapshot(
  p_user_uuid TEXT DEFAULT NULL,
  p_locale TEXT DEFAULT 'en',
  p_platform TEXT DEFAULT 'ios',
  p_country TEXT DEFAULT '',
  p_app_version TEXT DEFAULT '1.0.0'
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_locale TEXT := lower(split_part(COALESCE(p_locale, 'en'), '-', 1));
  v_config JSONB := '{}'::JSONB;
  v_flags JSONB := '{}'::JSONB;
  v_flag RECORD;
  v_events JSONB;
  v_announcements JSONB;
  v_collections JSONB;
  v_goals JSONB;
  v_rotation JSONB := '{}'::JSONB;
  v_experiments JSONB := '{}'::JSONB;
  v_exp RECORD;
  v_variant TEXT;
  v_emergency JSONB;
BEGIN
  IF p_user_uuid IS NOT NULL THEN
    SELECT id INTO v_user_id FROM users WHERE user_uuid = p_user_uuid LIMIT 1;
  END IF;

  SELECT COALESCE(jsonb_object_agg(key, value), '{}'::JSONB)
  INTO v_config FROM liveops_config;

  FOR v_flag IN SELECT slug FROM liveops_feature_flags ORDER BY sort_order LOOP
    v_flags := v_flags || jsonb_build_object(
      v_flag.slug,
      loe_evaluate_flag(v_flag.slug, COALESCE(p_user_uuid, 'anonymous'), p_platform, p_country, p_app_version)
    );
  END LOOP;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'slug', e.slug,
    'event_type', e.event_type,
    'starts_at', e.starts_at,
    'ends_at', e.ends_at,
    'title', COALESCE(i.title, e.slug),
    'description', COALESCE(i.description, ''),
    'cta_label', i.cta_label,
    'theme', e.theme,
    'rewards', e.rewards,
    'metadata', e.metadata
  ) ORDER BY e.sort_order), '[]'::JSONB)
  INTO v_events
  FROM liveops_events e
  LEFT JOIN liveops_event_i18n i ON i.event_slug = e.slug AND i.locale = v_locale
  WHERE e.is_active = TRUE AND e.starts_at <= NOW() AND e.ends_at >= NOW();

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'slug', a.slug,
    'type', a.announcement_type,
    'title', COALESCE(i.title, a.slug),
    'body', COALESCE(i.body, ''),
    'button_label', i.button_label,
    'image_url', a.image_url,
    'deep_link', a.deep_link,
    'priority', a.priority
  ) ORDER BY a.priority DESC), '[]'::JSONB)
  INTO v_announcements
  FROM liveops_announcements a
  LEFT JOIN liveops_announcement_i18n i ON i.announcement_slug = a.slug AND i.locale = v_locale
  WHERE a.is_active = TRUE
    AND a.starts_at <= NOW()
    AND (a.ends_at IS NULL OR a.ends_at >= NOW())
    AND (jsonb_array_length(a.target_platforms) = 0 OR a.target_platforms ? lower(p_platform))
    AND (jsonb_array_length(a.target_countries) = 0 OR a.target_countries ? p_country);

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'slug', c.slug,
    'title', COALESCE(i.title, c.slug),
    'description', COALESCE(i.description, ''),
    'club_slugs', c.club_slugs,
    'is_featured', c.is_featured
  ) ORDER BY c.sort_order), '[]'::JSONB)
  INTO v_collections
  FROM liveops_puzzle_collections c
  LEFT JOIN liveops_collection_i18n i ON i.collection_slug = c.slug AND i.locale = v_locale
  WHERE c.is_active = TRUE
    AND (c.starts_at IS NULL OR c.starts_at <= NOW())
    AND (c.ends_at IS NULL OR c.ends_at >= NOW());

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'slug', g.slug,
    'title', COALESCE(i.title, g.slug),
    'description', COALESCE(i.description, ''),
    'metric', g.metric,
    'target_value', g.target_value,
    'current_value', g.current_value,
    'progress_pct', LEAST(100, ROUND(g.current_value::NUMERIC / NULLIF(g.target_value, 0) * 100, 1)),
    'is_unlocked', g.is_unlocked OR g.current_value >= g.target_value
  ) ORDER BY g.starts_at), '[]'::JSONB)
  INTO v_goals
  FROM liveops_community_goals g
  LEFT JOIN liveops_community_goal_i18n i ON i.goal_slug = g.slug AND i.locale = v_locale
  WHERE g.is_active = TRUE AND g.starts_at <= NOW() AND g.ends_at >= NOW();

  v_rotation := jsonb_build_object(
    'featured_clubs', loe_current_rotation_item('featured_clubs'),
    'daily_theme', loe_current_rotation_item('daily_theme')
  );

  IF v_user_id IS NOT NULL THEN
    FOR v_exp IN SELECT slug FROM liveops_ab_experiments WHERE is_active = TRUE LOOP
      v_variant := loe_assign_experiment(v_user_id, v_exp.slug);
      v_experiments := v_experiments || jsonb_build_object(v_exp.slug, v_variant);
    END LOOP;
  END IF;

  v_emergency := loe_config('emergency');

  RETURN jsonb_build_object(
    'ok', TRUE,
    'fetched_at', NOW(),
    'cache_ttl_seconds', 300,
    'locale', v_locale,
    'config', v_config,
    'feature_flags', v_flags,
    'active_events', v_events,
    'announcements', v_announcements,
    'collections', v_collections,
    'community_goals', v_goals,
    'content_rotation', v_rotation,
    'experiments', v_experiments,
    'emergency', v_emergency
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.loe_track_event(
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
  v_user_id UUID;
BEGIN
  IF p_user_uuid IS NOT NULL THEN
    SELECT id INTO v_user_id FROM users WHERE user_uuid = p_user_uuid LIMIT 1;
  END IF;
  INSERT INTO liveops_analytics_events (user_id, event_type, payload)
  VALUES (v_user_id, p_event_type, p_payload);
END;
$$;

GRANT SELECT ON liveops_config TO anon, authenticated;
GRANT SELECT ON liveops_feature_flags TO anon, authenticated;
GRANT SELECT ON liveops_events TO anon, authenticated;
GRANT SELECT ON liveops_event_i18n TO anon, authenticated;
GRANT SELECT ON liveops_puzzle_collections TO anon, authenticated;
GRANT SELECT ON liveops_collection_i18n TO anon, authenticated;
GRANT SELECT ON liveops_community_goals TO anon, authenticated;
GRANT SELECT ON liveops_announcements TO anon, authenticated;
GRANT SELECT ON liveops_announcement_i18n TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.loe_get_snapshot(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.loe_evaluate_flag(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.loe_track_event(TEXT, TEXT, JSONB) TO anon, authenticated;
