-- =============================================================================
-- Security lockdown: RLS on all public tables, revoke PostgREST client access.
-- CrossBall clients call Edge Functions (service_role) only — not direct table/RPC API.
-- Addresses Supabase linter: rls_disabled_in_public, sensitive_columns_exposed.
-- =============================================================================

-- 1. Enable RLS on every public table that is missing it
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT c.relname AS tablename
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND NOT c.relrowsecurity
  LOOP
    EXECUTE format(
      'ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',
      r.tablename
    );
  END LOOP;
END $$;

-- 2. Force RLS on tables that store user or auth-adjacent data
ALTER TABLE public.users FORCE ROW LEVEL SECURITY;
ALTER TABLE public.puzzle_sessions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.answers FORCE ROW LEVEL SECURITY;
ALTER TABLE public.session_hints FORCE ROW LEVEL SECURITY;
ALTER TABLE public.user_stats FORCE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_sessions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.user_daily_practice_usage FORCE ROW LEVEL SECURITY;
ALTER TABLE public.user_push_tokens FORCE ROW LEVEL SECURITY;
ALTER TABLE public.iap_verifications FORCE ROW LEVEL SECURITY;
ALTER TABLE public.hint_ad_tokens FORCE ROW LEVEL SECURITY;
ALTER TABLE public.user_hint_taste_usage FORCE ROW LEVEL SECURITY;
ALTER TABLE public.user_practice_history FORCE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_events FORCE ROW LEVEL SECURITY;
ALTER TABLE public.player_progression FORCE ROW LEVEL SECURITY;
ALTER TABLE public.player_missions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.player_achievements FORCE ROW LEVEL SECURITY;
ALTER TABLE public.player_activity_events FORCE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_scores FORCE ROW LEVEL SECURITY;
ALTER TABLE public.economy_events_log FORCE ROW LEVEL SECURITY;
ALTER TABLE public.liveops_ab_assignments FORCE ROW LEVEL SECURITY;
ALTER TABLE public.liveops_analytics_events FORCE ROW LEVEL SECURITY;

-- 3. Remove legacy public-read RLS policies (anon key must not scrape tables)
DROP POLICY IF EXISTS clubs_public_read ON public.clubs;
DROP POLICY IF EXISTS players_public_read ON public.players;
DROP POLICY IF EXISTS puzzles_public_read ON public.puzzles;
DROP POLICY IF EXISTS puzzle_row_clubs_public_read ON public.puzzle_row_clubs;
DROP POLICY IF EXISTS puzzle_col_clubs_public_read ON public.puzzle_col_clubs;
DROP POLICY IF EXISTS puzzle_cells_public_read ON public.puzzle_cells;
DROP POLICY IF EXISTS rarity_stats_public_read ON public.rarity_stats;
DROP POLICY IF EXISTS player_popularity_public_read ON public.player_popularity;
DROP POLICY IF EXISTS daily_puzzle_rollout_read ON public.daily_puzzle_rollout;

-- 4. Revoke direct table access for API roles
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format(
      'REVOKE ALL ON public.%I FROM anon, authenticated',
      r.tablename
    );
  END LOOP;
END $$;

REVOKE ALL ON public.player_club_intersections FROM anon, authenticated;

-- 5. Revoke direct RPC access for API roles (Edge Functions use service_role)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS func
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
  LOOP
    EXECUTE format(
      'REVOKE ALL ON FUNCTION %s FROM anon, authenticated',
      r.func
    );
  END LOOP;
END $$;

-- Keep schema usage so PostgREST can still route Edge Functions; tables stay unreachable.
GRANT USAGE ON SCHEMA public TO anon, authenticated;
