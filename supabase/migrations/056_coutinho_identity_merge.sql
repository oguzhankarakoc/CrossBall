-- Fix Philippe Coutinho identity split:
-- "Philippe Coutinho" (has Inter 2010–13) vs "Philippe Coutinho Correia"
-- (missing Inter) used different identity_keys, so search preview hid Inter
-- while Match Grid / validate could still accept Inter via the other row.

UPDATE players
SET identity_key = 'coutinho|p'
WHERE normalized_name LIKE '%coutinho%'
  AND (
    normalized_name LIKE '%philippe%'
    OR normalized_name LIKE '%correia%'
  )
  AND (identity_key IS NULL OR identity_key <> 'coutinho|p');

SELECT public.refresh_player_club_intersections();
