-- Fix duplicate rows when a player has multiple stints at the same club.

DROP MATERIALIZED VIEW IF EXISTS player_club_intersections;

CREATE MATERIALIZED VIEW player_club_intersections AS
SELECT DISTINCT
  c1.player_id,
  c1.club_id AS club_a_id,
  c2.club_id AS club_b_id
FROM (
  SELECT DISTINCT player_id, club_id
  FROM player_career_history
  WHERE is_senior = TRUE AND is_youth = FALSE AND is_reserve = FALSE
) c1
JOIN (
  SELECT DISTINCT player_id, club_id
  FROM player_career_history
  WHERE is_senior = TRUE AND is_youth = FALSE AND is_reserve = FALSE
) c2 ON c1.player_id = c2.player_id AND c1.club_id < c2.club_id
WITH NO DATA;

CREATE UNIQUE INDEX idx_intersections_unique
  ON player_club_intersections (player_id, club_a_id, club_b_id);
CREATE INDEX idx_intersections_clubs
  ON player_club_intersections (club_a_id, club_b_id);

CREATE OR REPLACE FUNCTION public.refresh_player_club_intersections()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY player_club_intersections;
  EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
      REFRESH MATERIALIZED VIEW player_club_intersections;
    WHEN unique_violation OR cardinality_violation THEN
      REFRESH MATERIALIZED VIEW player_club_intersections;
  END;
END;
$$;

REFRESH MATERIALIZED VIEW player_club_intersections;
