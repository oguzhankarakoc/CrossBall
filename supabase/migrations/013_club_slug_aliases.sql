-- Expand club slug aliases so validation matches search UI labels.
-- Fixes false negatives (e.g. Alaba for Real Madrid × Bayern when puzzle uses id "bayern").

CREATE OR REPLACE FUNCTION public.canonical_club_slug(p_slug TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_slug IN ('fc-barcelona') THEN 'barcelona'
    WHEN p_slug IN ('chelsea-fc') THEN 'chelsea'
    WHEN p_slug IN ('paris-saintgermain', 'paris-saint-germain') THEN 'psg'
    WHEN p_slug IN ('bayern', 'fc-bayern-munchen', 'bayern-munchen') THEN 'bayern-munich'
    WHEN p_slug IN ('man-utd', 'man-united', 'manchester-utd', 'manchester_utd') THEN 'manchester-united'
    WHEN p_slug IN ('man-city', 'manchester_city') THEN 'manchester-city'
    WHEN p_slug IN ('arsenal') THEN 'arsenal-fc'
    WHEN p_slug IN ('liverpool') THEN 'liverpool-fc'
    WHEN p_slug IN ('inter', 'internazionale') THEN 'inter-milan'
    WHEN p_slug IN ('atletico', 'atletico-madrigo') THEN 'atletico-madrid'
    WHEN p_slug IN ('porto') THEN 'fc-porto'
    WHEN p_slug IN ('tottenham', 'spurs') THEN 'tottenham-hotspur'
    WHEN p_slug IN ('newcastle') THEN 'newcastle-united'
    WHEN p_slug IN ('west-ham') THEN 'west-ham-united'
    WHEN p_slug IN ('celtic') THEN 'celtic-fc'
    WHEN p_slug IN ('rangers') THEN 'rangers-fc'
    WHEN p_slug IN ('sevilla') THEN 'sevilla-fc'
    WHEN p_slug IN ('valencia') THEN 'valencia-cf'
    WHEN p_slug IN ('dortmund', 'bvb') THEN 'borussia-dortmund'
    WHEN p_slug IN ('gladbach') THEN 'borussia-monchengladbach'
    WHEN p_slug IN ('milan', 'ac-milan') THEN 'ac-milan'
    ELSE p_slug
  END;
$$;

-- Refresh intersections after alias expansion.
SELECT public.refresh_player_club_intersections();
