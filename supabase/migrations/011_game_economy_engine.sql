-- Game Economy Engine (GEE) — independent, data-driven progression system.

-- =============================================================================
-- CONFIG (no hardcoded economy values in app code)
-- =============================================================================

CREATE TABLE IF NOT EXISTS economy_config (
  key         TEXT PRIMARY KEY,
  value       JSONB NOT NULL,
  description TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS economy_reward_types (
  slug        TEXT PRIMARY KEY,
  label       TEXT NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  metadata    JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS economy_leagues (
  slug          TEXT PRIMARY KEY,
  label         TEXT NOT NULL,
  min_rating    NUMERIC(8,2) NOT NULL,
  max_rating    NUMERIC(8,2),
  sort_order    INT NOT NULL DEFAULT 0,
  badge_color   TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS economy_level_thresholds (
  level                 INT PRIMARY KEY CHECK (level >= 1),
  xp_required_total     BIGINT NOT NULL,
  title                 TEXT,
  reward_payload        JSONB NOT NULL DEFAULT '{}'
);

-- =============================================================================
-- ACHIEVEMENTS & MISSIONS (definitions)
-- =============================================================================

CREATE TABLE IF NOT EXISTS economy_achievement_definitions (
  slug              TEXT PRIMARY KEY,
  title             TEXT NOT NULL,
  description       TEXT NOT NULL,
  category          TEXT NOT NULL DEFAULT 'general',
  criteria          JSONB NOT NULL,
  reward_payload    JSONB NOT NULL DEFAULT '{}',
  achievement_points INT NOT NULL DEFAULT 10,
  is_hidden         BOOLEAN NOT NULL DEFAULT FALSE,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order        INT NOT NULL DEFAULT 0
);

CREATE TYPE economy_mission_period AS ENUM ('daily', 'weekly', 'seasonal', 'event');

CREATE TABLE IF NOT EXISTS economy_mission_definitions (
  slug              TEXT PRIMARY KEY,
  title             TEXT NOT NULL,
  description       TEXT NOT NULL,
  period            economy_mission_period NOT NULL,
  criteria          JSONB NOT NULL,
  reward_payload    JSONB NOT NULL DEFAULT '{}',
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order        INT NOT NULL DEFAULT 0
);

-- =============================================================================
-- SEASONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS economy_seasons (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug          TEXT UNIQUE NOT NULL,
  label         TEXT NOT NULL,
  starts_at     TIMESTAMPTZ NOT NULL,
  ends_at       TIMESTAMPTZ NOT NULL,
  is_active     BOOLEAN NOT NULL DEFAULT FALSE,
  reward_tiers  JSONB NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- PLAYER PROGRESSION PROFILE
-- =============================================================================

CREATE TABLE IF NOT EXISTS player_progression (
  user_id                   UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  experience_points         BIGINT NOT NULL DEFAULT 0,
  current_level             INT NOT NULL DEFAULT 1,
  competitive_rating        NUMERIC(8,2) NOT NULL DEFAULT 1000,
  current_league            TEXT NOT NULL DEFAULT 'bronze',
  games_played              INT NOT NULL DEFAULT 0,
  games_completed           INT NOT NULL DEFAULT 0,
  games_won                 INT NOT NULL DEFAULT 0,
  current_streak            INT NOT NULL DEFAULT 0,
  best_streak               INT NOT NULL DEFAULT 0,
  highest_score             NUMERIC(10,2) NOT NULL DEFAULT 0,
  average_score             NUMERIC(10,2) NOT NULL DEFAULT 0,
  average_solve_time_ms     BIGINT NOT NULL DEFAULT 0,
  favorite_difficulty       TEXT,
  favorite_clubs            JSONB NOT NULL DEFAULT '[]',
  rare_answers_found        INT NOT NULL DEFAULT 0,
  legendary_answers_found   INT NOT NULL DEFAULT 0,
  perfect_games             INT NOT NULL DEFAULT 0,
  hints_used                INT NOT NULL DEFAULT 0,
  ads_watched               INT NOT NULL DEFAULT 0,
  premium_status            BOOLEAN NOT NULL DEFAULT FALSE,
  season_points             INT NOT NULL DEFAULT 0,
  achievement_points        INT NOT NULL DEFAULT 0,
  total_correct_answers     INT NOT NULL DEFAULT 0,
  last_active               TIMESTAMPTZ,
  last_daily_date           DATE,
  active_season_id          UUID REFERENCES economy_seasons(id),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_player_progression_league
  ON player_progression (current_league, competitive_rating DESC);
CREATE INDEX IF NOT EXISTS idx_player_progression_level
  ON player_progression (current_level DESC, experience_points DESC);

-- =============================================================================
-- PLAYER STATE (achievements, missions, rewards, season stats)
-- =============================================================================

CREATE TABLE IF NOT EXISTS player_achievements (
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_slug  TEXT NOT NULL REFERENCES economy_achievement_definitions(slug),
  unlocked_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, achievement_slug)
);

CREATE TABLE IF NOT EXISTS player_missions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  mission_slug      TEXT NOT NULL REFERENCES economy_mission_definitions(slug),
  period_key        TEXT NOT NULL,
  progress          JSONB NOT NULL DEFAULT '{}',
  target            JSONB NOT NULL DEFAULT '{}',
  is_completed      BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at      TIMESTAMPTZ,
  reward_claimed    BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at        TIMESTAMPTZ,
  UNIQUE (user_id, mission_slug, period_key)
);

CREATE TABLE IF NOT EXISTS player_season_stats (
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  season_id     UUID NOT NULL REFERENCES economy_seasons(id) ON DELETE CASCADE,
  season_points INT NOT NULL DEFAULT 0,
  games_played  INT NOT NULL DEFAULT 0,
  peak_rating   NUMERIC(8,2) NOT NULL DEFAULT 1000,
  stats         JSONB NOT NULL DEFAULT '{}',
  PRIMARY KEY (user_id, season_id)
);

CREATE TABLE IF NOT EXISTS player_rewards_granted (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reward_type   TEXT NOT NULL REFERENCES economy_reward_types(slug),
  payload       JSONB NOT NULL DEFAULT '{}',
  source        TEXT NOT NULL,
  source_ref    TEXT,
  granted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS economy_events_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES users(id) ON DELETE SET NULL,
  event_type    TEXT NOT NULL,
  payload       JSONB NOT NULL DEFAULT '{}',
  xp_delta      INT NOT NULL DEFAULT 0,
  rating_delta  NUMERIC(8,2) NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_economy_events_user ON economy_events_log (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_economy_events_type ON economy_events_log (event_type, created_at DESC);

-- =============================================================================
-- SEED: reward types
-- =============================================================================

INSERT INTO economy_reward_types (slug, label) VALUES
  ('xp', 'Experience Points'),
  ('rating', 'Competitive Rating'),
  ('achievement_points', 'Achievement Points'),
  ('season_points', 'Season Points'),
  ('title', 'Profile Title'),
  ('badge', 'Profile Badge'),
  ('theme', 'UI Theme'),
  ('frame', 'Profile Frame'),
  ('premium_trial', 'Premium Trial'),
  ('cosmetic', 'Cosmetic Item')
ON CONFLICT (slug) DO NOTHING;

-- =============================================================================
-- SEED: leagues
-- =============================================================================

INSERT INTO economy_leagues (slug, label, min_rating, max_rating, sort_order, badge_color) VALUES
  ('bronze',   'Bronze',   0,    1199, 1, '#CD7F32'),
  ('silver',   'Silver',   1200, 1399, 2, '#C0C0C0'),
  ('gold',     'Gold',     1400, 1599, 3, '#FFD700'),
  ('platinum', 'Platinum', 1600, 1799, 4, '#E5E4E2'),
  ('diamond',  'Diamond',  1800, 1999, 5, '#B9F2FF'),
  ('master',   'Master',   2000, 2199, 6, '#9B59B6'),
  ('legend',   'Legend',   2200, NULL, 7, '#E74C3C')
ON CONFLICT (slug) DO UPDATE SET
  label = EXCLUDED.label,
  min_rating = EXCLUDED.min_rating,
  max_rating = EXCLUDED.max_rating,
  sort_order = EXCLUDED.sort_order;

-- =============================================================================
-- SEED: level curve (levels 1–50 sample; unlimited via admin inserts)
-- =============================================================================

INSERT INTO economy_level_thresholds (level, xp_required_total, title)
SELECT lvl,
       (lvl - 1)::BIGINT * (lvl - 1)::BIGINT * 50 + (lvl - 1) * 100,
       CASE
         WHEN lvl <= 5 THEN 'Rookie'
         WHEN lvl <= 15 THEN 'Regular'
         WHEN lvl <= 30 THEN 'Expert'
         WHEN lvl <= 50 THEN 'Veteran'
         ELSE 'Legend'
       END
FROM generate_series(1, 50) AS lvl
ON CONFLICT (level) DO NOTHING;

-- =============================================================================
-- SEED: economy config
-- =============================================================================

INSERT INTO economy_config (key, value, description) VALUES
  ('xp', '{
    "puzzle_complete_base": 50,
    "daily_complete_bonus": 100,
    "practice_complete_base": 35,
    "challenge_win": 60,
    "challenge_loss": 15,
    "perfect_game_bonus": 75,
    "streak_day_bonus": 25,
    "rare_answer": 12,
    "legendary_answer": 30,
    "mythic_answer": 50,
    "fast_complete_threshold_ms": 180000,
    "fast_complete_bonus": 25,
    "no_hints_bonus": 20
  }', 'XP award amounts'),
  ('rating', '{
    "default_rating": 1000,
    "k_factor": 24,
    "max_delta": 18,
    "min_delta": -18,
    "base_complete_delta": 4,
    "score_factor": 0.012,
    "hint_penalty": 2.5,
    "mistake_penalty": 3.0,
    "perfect_bonus": 6,
    "daily_bonus": 3,
    "quality_factor": 0.02
  }', 'Competitive rating tuning'),
  ('multipliers', '{
    "easy": 0.70,
    "medium": 1.00,
    "hard": 1.35,
    "legend": 1.60
  }', 'Difficulty XP multipliers (not premium-adjusted)'),
  ('premium', '{
    "xp_multiplier": 1.0,
    "rating_multiplier": 1.0,
    "score_multiplier": 1.0
  }', 'Fair play: premium must not affect competitive scoring'),
  ('streak', '{
    "milestones": [3, 7, 30, 100],
    "milestone_xp": {"3": 50, "7": 150, "30": 500, "100": 2000}
  }', 'Daily streak rewards'),
  ('season', '{
    "points_per_xp": 0.1,
    "active_season_slug": null
  }', 'Season point conversion')
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = NOW();

-- =============================================================================
-- SEED: achievements
-- =============================================================================

INSERT INTO economy_achievement_definitions (slug, title, description, category, criteria, reward_payload, achievement_points) VALUES
  ('first_puzzle', 'First Steps', 'Complete your first puzzle', 'general',
   '{"stat": "games_completed", "gte": 1}', '{"xp": 50}', 10),
  ('answers_100', 'Century Club', 'Submit 100 correct answers', 'general',
   '{"stat": "total_correct_answers", "gte": 100}', '{"xp": 200}', 25),
  ('first_rare', 'Rare Find', 'Find your first rare answer', 'rarity',
   '{"stat": "rare_answers_found", "gte": 1}', '{"xp": 75}', 15),
  ('first_legendary', 'Legend Spotter', 'Find your first legendary answer', 'rarity',
   '{"stat": "legendary_answers_found", "gte": 1}', '{"xp": 150}', 30),
  ('perfect_10', 'Perfectionist', 'Complete 10 perfect games', 'skill',
   '{"stat": "perfect_games", "gte": 10}', '{"xp": 300}', 40),
  ('daily_50', 'Daily Devotee', 'Complete 50 daily challenges', 'consistency',
   '{"stat": "daily_completions", "gte": 50}', '{"xp": 500}', 50),
  ('streak_7', 'Week Warrior', 'Reach a 7-day streak', 'consistency',
   '{"stat": "best_streak", "gte": 7}', '{"xp": 200}', 25),
  ('streak_30', 'Monthly Master', 'Reach a 30-day streak', 'consistency',
   '{"stat": "best_streak", "gte": 30}', '{"xp": 800}', 75),
  ('no_hints_5', 'Pure Knowledge', 'Complete 5 puzzles without hints', 'skill',
   '{"stat": "no_hint_completions", "gte": 5}', '{"xp": 250}', 35),
  ('level_10', 'Rising Star', 'Reach level 10', 'progression',
   '{"stat": "current_level", "gte": 10}', '{"xp": 100}', 20),
  ('level_25', 'Grid Veteran', 'Reach level 25', 'progression',
   '{"stat": "current_level", "gte": 25}', '{"xp": 300}', 40),
  ('league_gold', 'Gold League', 'Reach Gold league', 'competitive',
   '{"stat": "current_league", "eq": "gold"}', '{"xp": 400}', 50),
  ('league_diamond', 'Diamond Elite', 'Reach Diamond league', 'competitive',
   '{"stat": "current_league", "eq": "diamond"}', '{"xp": 1000}', 100),
  ('challenge_win_10', 'Challenge Champion', 'Win 10 friend challenges', 'social',
   '{"stat": "games_won", "gte": 10}', '{"xp": 350}', 45),
  ('answers_1000', 'Football Encyclopedia', 'Submit 1000 correct answers', 'general',
   '{"stat": "total_correct_answers", "gte": 1000}', '{"xp": 2000}', 150)
ON CONFLICT (slug) DO NOTHING;

-- Track no-hint completions separately
ALTER TABLE player_progression
  ADD COLUMN IF NOT EXISTS no_hint_completions INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS daily_completions INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS mythic_answers_found INT NOT NULL DEFAULT 0;

-- =============================================================================
-- SEED: missions
-- =============================================================================

INSERT INTO economy_mission_definitions (slug, title, description, period, criteria, reward_payload) VALUES
  ('daily_play_one', 'Daily Player', 'Complete one daily challenge', 'daily',
   '{"event": "daily_completed", "count": 1}', '{"xp": 75}'),
  ('daily_no_hints', 'No Help Needed', 'Complete a puzzle without hints', 'daily',
   '{"hints_used": 0, "games_completed": 1}', '{"xp": 50}'),
  ('daily_legendary', 'Legend Hunter', 'Find one legendary answer today', 'daily',
   '{"legendary_answers": 1}', '{"xp": 100}'),
  ('weekly_hard_3', 'Hard Mode Grinder', 'Complete 3 hard-tier puzzles', 'weekly',
   '{"difficulty_tier": "hard", "count": 3}', '{"xp": 250}'),
  ('weekly_streak', 'Stay Consistent', 'Maintain your daily streak all week', 'weekly',
   '{"streak_days": 7}', '{"xp": 300}')
ON CONFLICT (slug) DO NOTHING;

-- =============================================================================
-- HELPERS
-- =============================================================================

CREATE OR REPLACE FUNCTION public.gee_config(p_key TEXT)
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE((SELECT value FROM economy_config WHERE key = p_key), '{}'::JSONB);
$$;

CREATE OR REPLACE FUNCTION public.gee_league_for_rating(p_rating NUMERIC)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT slug FROM economy_leagues
  WHERE is_active = TRUE
    AND p_rating >= min_rating
    AND (max_rating IS NULL OR p_rating <= max_rating)
  ORDER BY sort_order DESC
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.gee_level_for_xp(p_xp BIGINT)
RETURNS INT
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(MAX(level), 1)
  FROM economy_level_thresholds
  WHERE xp_required_total <= p_xp;
$$;

CREATE OR REPLACE FUNCTION public.gee_ensure_progression(p_user_id UUID)
RETURNS player_progression
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row player_progression;
  v_default_rating NUMERIC := (gee_config('rating')->>'default_rating')::NUMERIC;
BEGIN
  INSERT INTO player_progression (user_id, competitive_rating, current_league, last_active)
  VALUES (
    p_user_id,
    COALESCE(v_default_rating, 1000),
    public.gee_league_for_rating(COALESCE(v_default_rating, 1000)),
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;

  SELECT * INTO v_row FROM player_progression WHERE user_id = p_user_id;
  RETURN v_row;
END;
$$;

-- =============================================================================
-- CORE: process economy event
-- =============================================================================

CREATE OR REPLACE FUNCTION public.gee_process_event(
  p_user_uuid TEXT,
  p_event_type TEXT,
  p_payload JSONB DEFAULT '{}'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_prog player_progression;
  v_xp_cfg JSONB := gee_config('xp');
  v_rating_cfg JSONB := gee_config('rating');
  v_mult_cfg JSONB := gee_config('multipliers');
  v_premium_cfg JSONB := gee_config('premium');
  v_streak_cfg JSONB := gee_config('streak');
  v_xp INT := 0;
  v_rating_delta NUMERIC := 0;
  v_old_level INT;
  v_new_level INT;
  v_leveled_up BOOLEAN := FALSE;
  v_achievements_unlocked TEXT[] := '{}';
  v_missions_completed TEXT[] := '{}';
  v_difficulty TEXT := lower(COALESCE(p_payload->>'difficulty_tier', 'medium'));
  v_mult NUMERIC := COALESCE((v_mult_cfg->>v_difficulty)::NUMERIC, 1.0);
  v_final_score NUMERIC := COALESCE((p_payload->>'final_score')::NUMERIC, 0);
  v_mistakes INT := COALESCE((p_payload->>'mistakes')::INT, 0);
  v_hints INT := COALESCE((p_payload->>'hints_used')::INT, 0);
  v_duration_ms BIGINT := COALESCE((p_payload->>'total_duration_ms')::BIGINT, 0);
  v_is_perfect BOOLEAN := COALESCE((p_payload->>'is_perfect')::BOOLEAN, FALSE);
  v_is_daily BOOLEAN := COALESCE((p_payload->>'mode')::TEXT, '') = 'daily';
  v_rare INT := COALESCE((p_payload->>'rare_count')::INT, 0);
  v_legendary INT := COALESCE((p_payload->>'legendary_count')::INT, 0);
  v_mythic INT := COALESCE((p_payload->>'mythic_count')::INT, 0);
  v_correct INT := COALESCE((p_payload->>'correct_count')::INT, 0);
  v_quality NUMERIC := COALESCE((p_payload->>'puzzle_quality_score')::NUMERIC, 85);
  v_today DATE := CURRENT_DATE;
  v_streak_milestone INT;
  v_ach RECORD;
BEGIN
  SELECT id INTO v_user_id FROM users WHERE user_uuid = p_user_uuid LIMIT 1;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', FALSE, 'reason', 'user_not_found');
  END IF;

  v_prog := gee_ensure_progression(v_user_id);
  v_old_level := v_prog.current_level;

  -- Premium fair-play: multipliers locked at 1.0 for rating/score
  v_mult := v_mult * COALESCE((v_premium_cfg->>'xp_multiplier')::NUMERIC, 1.0);

  IF p_event_type IN ('puzzle_completed', 'daily_completed', 'practice_completed') THEN
    v_xp := COALESCE((v_xp_cfg->>'puzzle_complete_base')::INT, 50);

    IF v_is_daily OR p_event_type = 'daily_completed' THEN
      v_xp := v_xp + COALESCE((v_xp_cfg->>'daily_complete_bonus')::INT, 100);
    ELSIF p_event_type = 'practice_completed' THEN
      v_xp := COALESCE((v_xp_cfg->>'practice_complete_base')::INT, 35);
    END IF;

    IF v_is_perfect THEN
      v_xp := v_xp + COALESCE((v_xp_cfg->>'perfect_game_bonus')::INT, 75);
    END IF;

    IF v_hints = 0 THEN
      v_xp := v_xp + COALESCE((v_xp_cfg->>'no_hints_bonus')::INT, 20);
    END IF;

    v_xp := v_xp + v_rare * COALESCE((v_xp_cfg->>'rare_answer')::INT, 12);
    v_xp := v_xp + v_legendary * COALESCE((v_xp_cfg->>'legendary_answer')::INT, 30);
    v_xp := v_xp + v_mythic * COALESCE((v_xp_cfg->>'mythic_answer')::INT, 50);

    IF v_duration_ms > 0 AND v_duration_ms <= COALESCE((v_xp_cfg->>'fast_complete_threshold_ms')::INT, 180000) THEN
      v_xp := v_xp + COALESCE((v_xp_cfg->>'fast_complete_bonus')::INT, 25);
    END IF;

    v_xp := ROUND(v_xp * v_mult)::INT;

    -- Rating delta
    v_rating_delta := COALESCE((v_rating_cfg->>'base_complete_delta')::NUMERIC, 4);
    v_rating_delta := v_rating_delta + v_final_score * COALESCE((v_rating_cfg->>'score_factor')::NUMERIC, 0.012);
    v_rating_delta := v_rating_delta + (v_quality - 85) * COALESCE((v_rating_cfg->>'quality_factor')::NUMERIC, 0.02);
    v_rating_delta := v_rating_delta - v_hints * COALESCE((v_rating_cfg->>'hint_penalty')::NUMERIC, 2.5);
    v_rating_delta := v_rating_delta - v_mistakes * COALESCE((v_rating_cfg->>'mistake_penalty')::NUMERIC, 3.0);
    IF v_is_perfect THEN
      v_rating_delta := v_rating_delta + COALESCE((v_rating_cfg->>'perfect_bonus')::NUMERIC, 6);
    END IF;
    IF v_is_daily THEN
      v_rating_delta := v_rating_delta + COALESCE((v_rating_cfg->>'daily_bonus')::NUMERIC, 3);
    END IF;

    v_rating_delta := v_rating_delta * COALESCE((v_premium_cfg->>'rating_multiplier')::NUMERIC, 1.0);
    v_rating_delta := GREATEST(
      COALESCE((v_rating_cfg->>'min_delta')::NUMERIC, -18),
      LEAST(COALESCE((v_rating_cfg->>'max_delta')::NUMERIC, 18), v_rating_delta)
    );

    -- Update progression stats
    UPDATE player_progression SET
      experience_points = experience_points + v_xp,
      competitive_rating = GREATEST(0, competitive_rating + v_rating_delta),
      games_played = games_played + 1,
      games_completed = games_completed + 1,
      highest_score = GREATEST(highest_score, v_final_score),
      average_score = CASE WHEN games_completed > 0
        THEN ((average_score * games_completed) + v_final_score) / (games_completed + 1)
        ELSE v_final_score END,
      average_solve_time_ms = CASE WHEN games_completed > 0 AND v_duration_ms > 0
        THEN ((average_solve_time_ms * games_completed) + v_duration_ms) / (games_completed + 1)
        ELSE v_duration_ms END,
      favorite_difficulty = COALESCE(p_payload->>'difficulty_tier', favorite_difficulty),
      rare_answers_found = rare_answers_found + v_rare,
      legendary_answers_found = legendary_answers_found + v_legendary,
      mythic_answers_found = mythic_answers_found + v_mythic,
      total_correct_answers = total_correct_answers + v_correct,
      perfect_games = perfect_games + CASE WHEN v_is_perfect THEN 1 ELSE 0 END,
      hints_used = hints_used + v_hints,
      no_hint_completions = no_hint_completions + CASE WHEN v_hints = 0 THEN 1 ELSE 0 END,
      daily_completions = daily_completions + CASE WHEN v_is_daily THEN 1 ELSE 0 END,
      season_points = season_points + ROUND(v_xp * COALESCE((gee_config('season')->>'points_per_xp')::NUMERIC, 0.1))::INT,
      last_active = NOW(),
      updated_at = NOW()
    WHERE user_id = v_user_id;

    -- Daily streak
    IF v_is_daily THEN
      UPDATE player_progression SET
        current_streak = CASE
          WHEN last_daily_date = v_today - 1 THEN current_streak + 1
          WHEN last_daily_date = v_today THEN current_streak
          ELSE 1
        END,
        best_streak = GREATEST(best_streak, CASE
          WHEN last_daily_date = v_today - 1 THEN current_streak + 1
          WHEN last_daily_date = v_today THEN current_streak
          ELSE 1
        END),
        last_daily_date = v_today
      WHERE user_id = v_user_id;

      SELECT current_streak INTO v_streak_milestone FROM player_progression WHERE user_id = v_user_id;
      IF v_streak_cfg->'milestone_xp' ? v_streak_milestone::TEXT THEN
        v_xp := v_xp + COALESCE((v_streak_cfg->'milestone_xp'->>v_streak_milestone::TEXT)::INT, 0);
        UPDATE player_progression SET
          experience_points = experience_points + COALESCE((v_streak_cfg->'milestone_xp'->>v_streak_milestone::TEXT)::INT, 0)
        WHERE user_id = v_user_id;
      ELSIF v_streak_milestone > 1 THEN
        UPDATE player_progression SET
          experience_points = experience_points + COALESCE((v_xp_cfg->>'streak_day_bonus')::INT, 25)
        WHERE user_id = v_user_id;
        v_xp := v_xp + COALESCE((v_xp_cfg->>'streak_day_bonus')::INT, 25);
      END IF;
    END IF;

  ELSIF p_event_type = 'challenge_won' THEN
    v_xp := COALESCE((v_xp_cfg->>'challenge_win')::INT, 60);
    v_rating_delta := COALESCE((v_rating_cfg->>'base_complete_delta')::NUMERIC, 4) * 1.5;
    UPDATE player_progression SET
      experience_points = experience_points + v_xp,
      competitive_rating = competitive_rating + v_rating_delta,
      games_played = games_played + 1,
      games_completed = games_completed + 1,
      games_won = games_won + 1,
      last_active = NOW(),
      updated_at = NOW()
    WHERE user_id = v_user_id;

  ELSIF p_event_type = 'challenge_lost' THEN
    v_xp := COALESCE((v_xp_cfg->>'challenge_loss')::INT, 15);
    v_rating_delta := COALESCE((v_rating_cfg->>'min_delta')::NUMERIC, -18) * 0.5;
    UPDATE player_progression SET
      experience_points = experience_points + v_xp,
      competitive_rating = GREATEST(0, competitive_rating + v_rating_delta),
      games_played = games_played + 1,
      games_completed = games_completed + 1,
      last_active = NOW(),
      updated_at = NOW()
    WHERE user_id = v_user_id;
  END IF;

  -- Recalculate level & league
  SELECT * INTO v_prog FROM player_progression WHERE user_id = v_user_id;
  v_new_level := gee_level_for_xp(v_prog.experience_points);
  v_leveled_up := v_new_level > v_old_level;

  UPDATE player_progression SET
    current_level = v_new_level,
    current_league = gee_league_for_rating(competitive_rating),
    updated_at = NOW()
  WHERE user_id = v_user_id;

  SELECT * INTO v_prog FROM player_progression WHERE user_id = v_user_id;

  -- Check achievements
  FOR v_ach IN
    SELECT d.slug, d.reward_payload, d.achievement_points
    FROM economy_achievement_definitions d
    WHERE d.is_active = TRUE
      AND NOT EXISTS (
        SELECT 1 FROM player_achievements pa
        WHERE pa.user_id = v_user_id AND pa.achievement_slug = d.slug
      )
  LOOP
    IF public.gee_check_achievement_criteria(v_user_id, v_ach.slug) THEN
      INSERT INTO player_achievements (user_id, achievement_slug)
      VALUES (v_user_id, v_ach.slug)
      ON CONFLICT DO NOTHING;

      UPDATE player_progression SET
        achievement_points = achievement_points + COALESCE(
          (SELECT achievement_points FROM economy_achievement_definitions WHERE slug = v_ach.slug), 10),
        experience_points = experience_points + COALESCE((v_ach.reward_payload->>'xp')::INT, 0)
      WHERE user_id = v_user_id;

      v_achievements_unlocked := array_append(v_achievements_unlocked, v_ach.slug);
    END IF;
  END LOOP;

  v_missions_completed := public.gee_update_missions(v_user_id, p_event_type, p_payload);

  -- Log event
  INSERT INTO economy_events_log (user_id, event_type, payload, xp_delta, rating_delta)
  VALUES (v_user_id, p_event_type, p_payload, v_xp, v_rating_delta);

  RETURN jsonb_build_object(
    'ok', TRUE,
    'xp_earned', v_xp,
    'rating_delta', ROUND(v_rating_delta, 2),
    'leveled_up', v_leveled_up,
    'new_level', v_prog.current_level,
    'old_level', v_old_level,
    'competitive_rating', v_prog.competitive_rating,
    'current_league', v_prog.current_league,
    'current_streak', v_prog.current_streak,
    'best_streak', v_prog.best_streak,
    'achievements_unlocked', to_jsonb(v_achievements_unlocked),
    'missions_completed', to_jsonb(v_missions_completed),
    'progression', jsonb_build_object(
      'experience_points', v_prog.experience_points,
      'current_level', v_prog.current_level,
      'competitive_rating', v_prog.competitive_rating,
      'current_league', v_prog.current_league,
      'season_points', v_prog.season_points,
      'achievement_points', v_prog.achievement_points
    )
  );
END;
$$;

-- Achievement criteria checker
CREATE OR REPLACE FUNCTION public.gee_update_missions(
  p_user_id UUID,
  p_event_type TEXT,
  p_payload JSONB
)
RETURNS TEXT[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_completed TEXT[] := '{}';
  v_period_key TEXT := to_char(CURRENT_DATE, 'IYYY-"W"IW');
  v_daily_key TEXT := CURRENT_DATE::TEXT;
  v_m RECORD;
  v_hints INT := COALESCE((p_payload->>'hints_used')::INT, 0);
  v_legendary INT := COALESCE((p_payload->>'legendary_count')::INT, 0);
  v_difficulty TEXT := lower(COALESCE(p_payload->>'difficulty_tier', 'medium'));
BEGIN
  FOR v_m IN
    SELECT slug, period, criteria, reward_payload
    FROM economy_mission_definitions
    WHERE is_active = TRUE
  LOOP
    IF v_m.period = 'daily' THEN
      IF v_m.slug = 'daily_play_one' AND p_event_type = 'daily_completed' THEN
        INSERT INTO player_missions (user_id, mission_slug, period_key, progress, target, is_completed, completed_at, expires_at)
        VALUES (p_user_id, v_m.slug, v_daily_key, '{"count": 1}'::JSONB, v_m.criteria, TRUE, NOW(), CURRENT_DATE + 1)
        ON CONFLICT (user_id, mission_slug, period_key) DO UPDATE SET
          is_completed = TRUE, completed_at = NOW(), progress = '{"count": 1}'::JSONB
        WHERE player_missions.is_completed = FALSE;
        IF FOUND THEN v_completed := array_append(v_completed, v_m.slug); END IF;
      ELSIF v_m.slug = 'daily_no_hints' AND v_hints = 0
        AND p_event_type IN ('daily_completed', 'practice_completed', 'puzzle_completed') THEN
        INSERT INTO player_missions (user_id, mission_slug, period_key, progress, target, is_completed, completed_at, expires_at)
        VALUES (p_user_id, v_m.slug, v_daily_key, '{"done": true}'::JSONB, v_m.criteria, TRUE, NOW(), CURRENT_DATE + 1)
        ON CONFLICT (user_id, mission_slug, period_key) DO UPDATE SET
          is_completed = TRUE, completed_at = NOW()
        WHERE player_missions.is_completed = FALSE;
        IF FOUND THEN v_completed := array_append(v_completed, v_m.slug); END IF;
      ELSIF v_m.slug = 'daily_legendary' AND v_legendary >= 1 THEN
        INSERT INTO player_missions (user_id, mission_slug, period_key, progress, target, is_completed, completed_at, expires_at)
        VALUES (p_user_id, v_m.slug, v_daily_key, '{"legendary": 1}'::JSONB, v_m.criteria, TRUE, NOW(), CURRENT_DATE + 1)
        ON CONFLICT (user_id, mission_slug, period_key) DO UPDATE SET
          is_completed = TRUE, completed_at = NOW()
        WHERE player_missions.is_completed = FALSE;
        IF FOUND THEN v_completed := array_append(v_completed, v_m.slug); END IF;
      END IF;
    ELSIF v_m.period = 'weekly' AND v_m.slug = 'weekly_hard_3' AND v_difficulty = 'hard'
      AND p_event_type IN ('daily_completed', 'practice_completed', 'puzzle_completed') THEN
      INSERT INTO player_missions (user_id, mission_slug, period_key, progress, target, expires_at)
      VALUES (p_user_id, v_m.slug, v_period_key, '{"count": 1}'::JSONB, v_m.criteria, date_trunc('week', CURRENT_DATE)::DATE + 7)
      ON CONFLICT (user_id, mission_slug, period_key) DO UPDATE SET
        progress = jsonb_set(
          COALESCE(player_missions.progress, '{}'::JSONB),
          '{count}',
          to_jsonb(COALESCE((player_missions.progress->>'count')::INT, 0) + 1)
        ),
        is_completed = COALESCE((player_missions.progress->>'count')::INT, 0) + 1 >= COALESCE((v_m.criteria->>'count')::INT, 3),
        completed_at = CASE WHEN COALESCE((player_missions.progress->>'count')::INT, 0) + 1 >= COALESCE((v_m.criteria->>'count')::INT, 3)
          THEN NOW() ELSE player_missions.completed_at END;
      IF (SELECT is_completed FROM player_missions WHERE user_id = p_user_id AND mission_slug = v_m.slug AND period_key = v_period_key) THEN
        v_completed := array_append(v_completed, v_m.slug);
      END IF;
    END IF;
  END LOOP;

  RETURN v_completed;
END;
$$;

CREATE OR REPLACE FUNCTION public.gee_check_achievement_criteria(
  p_user_id UUID,
  p_achievement_slug TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_criteria JSONB;
  v_stat TEXT;
  v_gte NUMERIC;
  v_eq TEXT;
  v_val NUMERIC;
  v_prog player_progression;
BEGIN
  SELECT criteria INTO v_criteria
  FROM economy_achievement_definitions
  WHERE slug = p_achievement_slug AND is_active = TRUE;

  IF v_criteria IS NULL THEN RETURN FALSE; END IF;

  SELECT * INTO v_prog FROM player_progression WHERE user_id = p_user_id;
  IF v_prog IS NULL THEN RETURN FALSE; END IF;

  v_stat := v_criteria->>'stat';

  v_val := CASE v_stat
    WHEN 'games_completed' THEN v_prog.games_completed
    WHEN 'total_correct_answers' THEN v_prog.total_correct_answers
    WHEN 'rare_answers_found' THEN v_prog.rare_answers_found
    WHEN 'legendary_answers_found' THEN v_prog.legendary_answers_found
    WHEN 'perfect_games' THEN v_prog.perfect_games
    WHEN 'daily_completions' THEN v_prog.daily_completions
    WHEN 'best_streak' THEN v_prog.best_streak
    WHEN 'no_hint_completions' THEN v_prog.no_hint_completions
    WHEN 'current_level' THEN v_prog.current_level
    WHEN 'games_won' THEN v_prog.games_won
    ELSE 0
  END;

  IF v_criteria ? 'gte' THEN
    RETURN v_val >= (v_criteria->>'gte')::NUMERIC;
  END IF;

  IF v_criteria ? 'eq' AND v_stat = 'current_league' THEN
    v_eq := v_criteria->>'eq';
    RETURN v_prog.current_league = v_eq;
  END IF;

  RETURN FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION public.gee_get_profile(p_user_uuid TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
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

GRANT SELECT ON economy_config TO anon, authenticated;
GRANT SELECT ON economy_leagues TO anon, authenticated;
GRANT SELECT ON economy_level_thresholds TO anon, authenticated;
GRANT SELECT ON economy_achievement_definitions TO anon, authenticated;
GRANT SELECT ON economy_mission_definitions TO anon, authenticated;
GRANT SELECT ON economy_reward_types TO anon, authenticated;
GRANT SELECT ON player_progression TO anon, authenticated;
GRANT SELECT ON player_achievements TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.gee_process_event(TEXT, TEXT, JSONB) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.gee_get_profile(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.gee_config(TEXT) TO anon, authenticated;
