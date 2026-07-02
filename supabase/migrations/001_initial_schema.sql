-- CrossBall Production Schema v1.0.0
-- PostgreSQL 15+ / Supabase

SET search_path TO public, extensions;

-- =============================================================================
-- EXTENSIONS (Supabase: extensions schema)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA extensions;

-- =============================================================================
-- ENUMS (idempotent)
-- =============================================================================

DO $$ BEGIN
  CREATE TYPE rarity_tier AS ENUM ('common', 'rare', 'epic', 'legendary', 'mythic');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE puzzle_mode AS ENUM ('daily', 'practice', 'challenge');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE hint_type AS ENUM ('nationality', 'position', 'first_letter');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE session_status AS ENUM ('active', 'completed', 'abandoned', 'suspicious');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =============================================================================
-- USERS
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_uuid       TEXT UNIQUE NOT NULL,
  display_name    TEXT,
  is_premium      BOOLEAN NOT NULL DEFAULT FALSE,
  premium_until   TIMESTAMPTZ,
  onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE,
  locale          TEXT DEFAULT 'system',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_user_uuid ON users (user_uuid);

-- =============================================================================
-- CLUBS
-- =============================================================================

CREATE TABLE IF NOT EXISTS clubs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  slug            TEXT UNIQUE NOT NULL,
  country_code    CHAR(2),
  logo_url        TEXT,
  is_top_club     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clubs_slug ON clubs (slug);
CREATE INDEX IF NOT EXISTS idx_clubs_top ON clubs (is_top_club) WHERE is_top_club = TRUE;
CREATE INDEX IF NOT EXISTS idx_clubs_name_trgm ON clubs USING gin (name gin_trgm_ops);

-- =============================================================================
-- PLAYERS
-- =============================================================================

CREATE TABLE IF NOT EXISTS players (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id       TEXT UNIQUE,
  name              TEXT NOT NULL,
  normalized_name   TEXT NOT NULL,
  nationality_code  CHAR(2),
  primary_position  TEXT,
  birth_date        DATE,
  search_vector     TSVECTOR,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_players_normalized_trgm
  ON players USING gin (normalized_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_players_search_vector ON players USING gin (search_vector);
CREATE INDEX IF NOT EXISTS idx_players_nationality ON players (nationality_code);

-- Auto-update search vector
CREATE OR REPLACE FUNCTION public.players_search_vector_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('simple', coalesce(NEW.normalized_name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(NEW.name, '')), 'B');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_players_search_vector ON players;
CREATE TRIGGER trg_players_search_vector
  BEFORE INSERT OR UPDATE ON players
  FOR EACH ROW EXECUTE FUNCTION public.players_search_vector_update();

-- =============================================================================
-- PLAYER CAREER HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS player_career_history (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  club_id         UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  start_date      DATE,
  end_date        DATE,
  is_loan         BOOLEAN NOT NULL DEFAULT FALSE,
  is_senior       BOOLEAN NOT NULL DEFAULT TRUE,
  is_youth        BOOLEAN NOT NULL DEFAULT FALSE,
  is_reserve      BOOLEAN NOT NULL DEFAULT FALSE,
  appearances     INT DEFAULT 0,
  source          TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (player_id, club_id, start_date, is_loan)
);

CREATE INDEX IF NOT EXISTS idx_career_player ON player_career_history (player_id);
CREATE INDEX IF NOT EXISTS idx_career_club ON player_career_history (club_id);
CREATE INDEX IF NOT EXISTS idx_career_senior ON player_career_history (club_id, player_id)
  WHERE is_senior = TRUE AND is_youth = FALSE AND is_reserve = FALSE;

-- Materialized view for fast intersection lookups
CREATE MATERIALIZED VIEW IF NOT EXISTS player_club_intersections AS
SELECT
  pch1.player_id,
  pch1.club_id AS club_a_id,
  pch2.club_id AS club_b_id
FROM player_career_history pch1
JOIN player_career_history pch2
  ON pch1.player_id = pch2.player_id
  AND pch1.club_id < pch2.club_id
WHERE pch1.is_senior = TRUE AND pch1.is_youth = FALSE AND pch1.is_reserve = FALSE
  AND pch2.is_senior = TRUE AND pch2.is_youth = FALSE AND pch2.is_reserve = FALSE
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS idx_intersections_unique
  ON player_club_intersections (player_id, club_a_id, club_b_id);
CREATE INDEX IF NOT EXISTS idx_intersections_clubs
  ON player_club_intersections (club_a_id, club_b_id);

-- =============================================================================
-- PUZZLES
-- =============================================================================

CREATE TABLE IF NOT EXISTS puzzles (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  puzzle_date     DATE,
  mode            puzzle_mode NOT NULL DEFAULT 'daily',
  grid_size       SMALLINT NOT NULL CHECK (grid_size IN (3, 4)),
  difficulty      NUMERIC(4,2) DEFAULT 0.5,
  is_published    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (puzzle_date, mode, grid_size)
);

CREATE INDEX IF NOT EXISTS idx_puzzles_date ON puzzles (puzzle_date) WHERE is_published = TRUE;

CREATE TABLE IF NOT EXISTS puzzle_row_clubs (
  puzzle_id       UUID NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
  row_index       SMALLINT NOT NULL,
  club_id         UUID NOT NULL REFERENCES clubs(id),
  PRIMARY KEY (puzzle_id, row_index)
);

CREATE TABLE IF NOT EXISTS puzzle_col_clubs (
  puzzle_id       UUID NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
  col_index       SMALLINT NOT NULL,
  club_id         UUID NOT NULL REFERENCES clubs(id),
  PRIMARY KEY (puzzle_id, col_index)
);

CREATE TABLE IF NOT EXISTS puzzle_cells (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  puzzle_id       UUID NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
  row_index       SMALLINT NOT NULL,
  col_index       SMALLINT NOT NULL,
  valid_answer_count INT NOT NULL DEFAULT 0,
  difficulty      NUMERIC(4,2) DEFAULT 0.5,
  UNIQUE (puzzle_id, row_index, col_index)
);

CREATE INDEX IF NOT EXISTS idx_puzzle_cells_puzzle ON puzzle_cells (puzzle_id);

-- =============================================================================
-- GAME SESSIONS & ANSWERS
-- =============================================================================

CREATE TABLE IF NOT EXISTS puzzle_sessions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  puzzle_id             UUID NOT NULL REFERENCES puzzles(id),
  mode                  puzzle_mode NOT NULL,
  status                session_status NOT NULL DEFAULT 'active',
  grid_size             SMALLINT NOT NULL,
  started_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at          TIMESTAMPTZ,
  total_duration_ms     BIGINT DEFAULT 0,
  background_duration_ms BIGINT DEFAULT 0,
  inactive_periods      SMALLINT DEFAULT 0,
  is_suspicious         BOOLEAN NOT NULL DEFAULT FALSE,
  hints_used            SMALLINT DEFAULT 0,
  mistakes              SMALLINT DEFAULT 0,
  final_score           NUMERIC(10,2) DEFAULT 0,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON puzzle_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_puzzle ON puzzle_sessions (puzzle_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON puzzle_sessions (status);

CREATE TABLE IF NOT EXISTS answers (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id        UUID NOT NULL REFERENCES puzzle_sessions(id) ON DELETE CASCADE,
  puzzle_cell_id    UUID NOT NULL REFERENCES puzzle_cells(id),
  player_id         UUID NOT NULL REFERENCES players(id),
  is_correct        BOOLEAN NOT NULL,
  usage_percentage  NUMERIC(5,2),
  rarity_tier       rarity_tier,
  rarity_score      NUMERIC(6,2),
  response_time_ms  INT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, puzzle_cell_id)
);

CREATE INDEX IF NOT EXISTS idx_answers_session ON answers (session_id);
CREATE INDEX IF NOT EXISTS idx_answers_player ON answers (player_id);

CREATE TABLE IF NOT EXISTS session_hints (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      UUID NOT NULL REFERENCES puzzle_sessions(id) ON DELETE CASCADE,
  puzzle_cell_id  UUID NOT NULL REFERENCES puzzle_cells(id),
  hint_type       hint_type NOT NULL,
  hint_value      TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, puzzle_cell_id, hint_type)
);

-- =============================================================================
-- CHALLENGES
-- =============================================================================

CREATE TABLE IF NOT EXISTS challenge_sessions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_code    TEXT UNIQUE NOT NULL,
  puzzle_id         UUID NOT NULL REFERENCES puzzles(id),
  creator_user_id   UUID NOT NULL REFERENCES users(id),
  creator_session_id UUID REFERENCES puzzle_sessions(id),
  creator_score     NUMERIC(10,2) NOT NULL DEFAULT 0,
  challenger_user_id UUID REFERENCES users(id),
  challenger_session_id UUID REFERENCES puzzle_sessions(id),
  challenger_score  NUMERIC(10,2),
  winner_user_id    UUID REFERENCES users(id),
  status            TEXT NOT NULL DEFAULT 'open',
  expires_at        TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_challenges_code ON challenge_sessions (challenge_code);
CREATE INDEX IF NOT EXISTS idx_challenges_creator ON challenge_sessions (creator_user_id);

-- =============================================================================
-- STATS & RARITY
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_stats (
  user_id           UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  games_played      INT NOT NULL DEFAULT 0,
  games_won         INT NOT NULL DEFAULT 0,
  current_streak    INT NOT NULL DEFAULT 0,
  best_streak       INT NOT NULL DEFAULT 0,
  total_score       NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_correct     INT NOT NULL DEFAULT 0,
  total_mistakes    INT NOT NULL DEFAULT 0,
  hints_used        INT NOT NULL DEFAULT 0,
  common_count      INT NOT NULL DEFAULT 0,
  rare_count        INT NOT NULL DEFAULT 0,
  epic_count        INT NOT NULL DEFAULT 0,
  legendary_count   INT NOT NULL DEFAULT 0,
  mythic_count      INT NOT NULL DEFAULT 0,
  avg_solve_time_ms BIGINT DEFAULT 0,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rarity_stats (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  puzzle_cell_id    UUID NOT NULL REFERENCES puzzle_cells(id) ON DELETE CASCADE,
  player_id         UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  selection_count   INT NOT NULL DEFAULT 0,
  usage_percentage  NUMERIC(5,2) NOT NULL DEFAULT 0,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (puzzle_cell_id, player_id)
);

CREATE INDEX IF NOT EXISTS idx_rarity_cell ON rarity_stats (puzzle_cell_id);
CREATE INDEX IF NOT EXISTS idx_rarity_player ON rarity_stats (player_id);
CREATE INDEX IF NOT EXISTS idx_rarity_popular ON rarity_stats (selection_count DESC);

CREATE TABLE IF NOT EXISTS player_popularity (
  player_id         UUID PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  global_selection_count INT NOT NULL DEFAULT 0,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_popularity_count ON player_popularity (global_selection_count DESC);

-- =============================================================================
-- ANALYTICS
-- =============================================================================

CREATE TABLE IF NOT EXISTS analytics_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
  event_name      TEXT NOT NULL,
  properties      JSONB NOT NULL DEFAULT '{}',
  client_timestamp TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analytics_event ON analytics_events (event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_user ON analytics_events (user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_created ON analytics_events (created_at DESC);

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

CREATE OR REPLACE FUNCTION public.normalize_player_name(input TEXT)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT lower(extensions.unaccent(trim(input)));
$$;

CREATE OR REPLACE FUNCTION public.rarity_tier_from_usage(usage_pct NUMERIC)
RETURNS rarity_tier
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  IF usage_pct > 50 THEN RETURN 'common'::rarity_tier;
  ELSIF usage_pct > 25 THEN RETURN 'rare'::rarity_tier;
  ELSIF usage_pct > 10 THEN RETURN 'epic'::rarity_tier;
  ELSIF usage_pct > 3 THEN RETURN 'legendary'::rarity_tier;
  ELSE RETURN 'mythic'::rarity_tier;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.find_intersection_players(
  p_club_a UUID,
  p_club_b UUID,
  p_limit INT DEFAULT 100
)
RETURNS TABLE (player_id UUID, player_name TEXT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.name
  FROM player_club_intersections pci
  JOIN players p ON p.id = pci.player_id
  WHERE (pci.club_a_id = p_club_a AND pci.club_b_id = p_club_b)
     OR (pci.club_a_id = p_club_b AND pci.club_b_id = p_club_a)
  LIMIT p_limit;
END;
$$;

-- Used by validate-answer edge function
CREATE OR REPLACE FUNCTION public.increment_rarity_stat(
  p_cell_id UUID,
  p_player_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total INT;
BEGIN
  INSERT INTO rarity_stats (puzzle_cell_id, player_id, selection_count, usage_percentage)
  VALUES (p_cell_id, p_player_id, 1, 0)
  ON CONFLICT (puzzle_cell_id, player_id)
  DO UPDATE SET
    selection_count = rarity_stats.selection_count + 1,
    updated_at = NOW();

  SELECT COALESCE(SUM(selection_count), 0)::INT INTO v_total
  FROM rarity_stats
  WHERE puzzle_cell_id = p_cell_id;

  UPDATE rarity_stats rs
  SET usage_percentage = CASE
    WHEN v_total > 0 THEN (rs.selection_count::NUMERIC / v_total * 100)
    ELSE 0
  END
  WHERE rs.puzzle_cell_id = p_cell_id;

  INSERT INTO player_popularity (player_id, global_selection_count)
  VALUES (p_player_id, 1)
  ON CONFLICT (player_id)
  DO UPDATE SET
    global_selection_count = player_popularity.global_selection_count + 1,
    updated_at = NOW();
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_player_club_intersections()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY player_club_intersections;
EXCEPTION
  WHEN object_not_in_prerequisite_state THEN
    REFRESH MATERIALIZED VIEW player_club_intersections;
END;
$$;

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE puzzle_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE puzzles ENABLE ROW LEVEL SECURITY;
ALTER TABLE puzzle_row_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE puzzle_col_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE puzzle_cells ENABLE ROW LEVEL SECURITY;
ALTER TABLE rarity_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_popularity ENABLE ROW LEVEL SECURITY;

-- Public read policies
DROP POLICY IF EXISTS clubs_public_read ON clubs;
CREATE POLICY clubs_public_read ON clubs FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS players_public_read ON players;
CREATE POLICY players_public_read ON players FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS puzzles_public_read ON puzzles;
CREATE POLICY puzzles_public_read ON puzzles FOR SELECT TO anon, authenticated
  USING (is_published = true);

DROP POLICY IF EXISTS puzzle_row_clubs_public_read ON puzzle_row_clubs;
CREATE POLICY puzzle_row_clubs_public_read ON puzzle_row_clubs FOR SELECT TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM puzzles p
      WHERE p.id = puzzle_row_clubs.puzzle_id AND p.is_published = true
    )
  );

DROP POLICY IF EXISTS puzzle_col_clubs_public_read ON puzzle_col_clubs;
CREATE POLICY puzzle_col_clubs_public_read ON puzzle_col_clubs FOR SELECT TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM puzzles p
      WHERE p.id = puzzle_col_clubs.puzzle_id AND p.is_published = true
    )
  );

DROP POLICY IF EXISTS puzzle_cells_public_read ON puzzle_cells;
CREATE POLICY puzzle_cells_public_read ON puzzle_cells FOR SELECT TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM puzzles p
      WHERE p.id = puzzle_cells.puzzle_id AND p.is_published = true
    )
  );

DROP POLICY IF EXISTS rarity_stats_public_read ON rarity_stats;
CREATE POLICY rarity_stats_public_read ON rarity_stats FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS player_popularity_public_read ON player_popularity;
CREATE POLICY player_popularity_public_read ON player_popularity FOR SELECT TO anon, authenticated USING (true);

-- Service role / edge functions write via SECURITY DEFINER RPCs

-- =============================================================================
-- GRANTS
-- =============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON clubs, players, puzzles TO anon, authenticated;
GRANT SELECT ON puzzle_row_clubs, puzzle_col_clubs, puzzle_cells TO anon, authenticated;
GRANT SELECT ON rarity_stats, player_popularity TO anon, authenticated;
GRANT SELECT ON player_club_intersections TO anon, authenticated;

GRANT EXECUTE ON FUNCTION public.normalize_player_name(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rarity_tier_from_usage(NUMERIC) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.find_intersection_players(UUID, UUID, INT) TO anon, authenticated;

-- =============================================================================
-- SEED: Demo clubs (development)
-- =============================================================================

INSERT INTO clubs (name, slug, country_code, is_top_club) VALUES
  ('FC Barcelona', 'barcelona', 'ES', true),
  ('Chelsea FC', 'chelsea', 'GB', true),
  ('Real Madrid', 'real-madrid', 'ES', true),
  ('Manchester United', 'manchester-united', 'GB', true),
  ('Bayern Munich', 'bayern-munich', 'DE', true),
  ('Juventus', 'juventus', 'IT', true),
  ('AC Milan', 'ac-milan', 'IT', true),
  ('Inter Milan', 'inter-milan', 'IT', true),
  ('Paris Saint-Germain', 'psg', 'FR', true)
ON CONFLICT (slug) DO NOTHING;

-- Refresh intersections after seed (no-op until career data exists)
REFRESH MATERIALIZED VIEW player_club_intersections;
