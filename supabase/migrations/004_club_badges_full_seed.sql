-- Patch: expand club badge metadata for all top clubs (run if 002 was applied with old 6-club seed)

WITH badge_seed AS (
  SELECT * FROM (VALUES
    ('barcelona', '#A50044', '#004D98', 'BAR', 'vertical', 'Barcelona'),
    ('fc-barcelona', '#A50044', '#004D98', 'BAR', 'vertical', 'Barcelona'),
    ('real-madrid', '#FEBE10', '#FFFFFF', 'RMA', 'horizontal', 'Real Madrid'),
    ('atletico-madrid', '#CB3524', '#FFFFFF', 'ATM', 'vertical', 'Atletico'),
    ('sevilla-fc', '#FFFFFF', '#D50000', 'SEV', 'horizontal', 'Sevilla'),
    ('valencia-cf', '#EE3524', '#000000', 'VAL', 'vertical', 'Valencia'),
    ('manchester-united', '#DA291C', '#FBE122', 'MUN', 'vertical', 'Man United'),
    ('manchester-city', '#6CABDD', '#FFFFFF', 'MCI', 'vertical', 'Man City'),
    ('liverpool-fc', '#C8102E', '#FFFFFF', 'LIV', 'vertical', 'Liverpool'),
    ('chelsea', '#034694', '#FFFFFF', 'CHE', 'horizontal', 'Chelsea'),
    ('chelsea-fc', '#034694', '#FFFFFF', 'CHE', 'horizontal', 'Chelsea'),
    ('arsenal-fc', '#EF0107', '#FFFFFF', 'ARS', 'vertical', 'Arsenal'),
    ('tottenham-hotspur', '#132257', '#FFFFFF', 'TOT', 'vertical', 'Tottenham'),
    ('newcastle-united', '#241F20', '#FFFFFF', 'NEW', 'vertical', 'Newcastle'),
    ('west-ham-united', '#7A263A', '#1BB1E7', 'WHU', 'vertical', 'West Ham'),
    ('aston-villa', '#670E36', '#95BFE5', 'AVL', 'vertical', 'Aston Villa'),
    ('everton-fc', '#003399', '#FFFFFF', 'EVE', 'vertical', 'Everton'),
    ('bayern-munich', '#DC052D', '#0066B2', 'BAY', 'vertical', 'Bayern'),
    ('borussia-dortmund', '#FDE100', '#000000', 'BVB', 'vertical', 'Dortmund'),
    ('rb-leipzig', '#DD0741', '#FFFFFF', 'RBL', 'vertical', 'Leipzig'),
    ('bayer-leverkusen', '#E32221', '#000000', 'B04', 'vertical', 'Leverkusen'),
    ('borussia-monchengladbach', '#000000', '#FFFFFF', 'BMG', 'vertical', 'Gladbach'),
    ('juventus', '#000000', '#FFFFFF', 'JUV', 'horizontal', 'Juventus'),
    ('ac-milan', '#FB090B', '#000000', 'MIL', 'vertical', 'AC Milan'),
    ('inter-milan', '#010E80', '#000000', 'INT', 'vertical', 'Inter'),
    ('as-roma', '#8E1F2F', '#F0BC42', 'ROM', 'vertical', 'Roma'),
    ('napoli', '#12A0D7', '#FFFFFF', 'NAP', 'vertical', 'Napoli'),
    ('lazio', '#87D8F7', '#FFFFFF', 'LAZ', 'vertical', 'Lazio'),
    ('fiorentina', '#482E92', '#FFFFFF', 'FIO', 'vertical', 'Fiorentina'),
    ('paris-saintgermain', '#004170', '#DA020E', 'PSG', 'horizontal', 'PSG'),
    ('psg', '#004170', '#DA020E', 'PSG', 'horizontal', 'PSG'),
    ('lyon', '#103889', '#DA020E', 'OL', 'vertical', 'Lyon'),
    ('marseille', '#2FAEE0', '#FFFFFF', 'OM', 'vertical', 'Marseille'),
    ('monaco', '#E30613', '#FFFFFF', 'MON', 'vertical', 'Monaco'),
    ('lille-osc', '#E01E13', '#FFFFFF', 'LIL', 'vertical', 'Lille'),
    ('ajax', '#D2122E', '#FFFFFF', 'AJA', 'vertical', 'Ajax'),
    ('psv-eindhoven', '#ED1C24', '#FFFFFF', 'PSV', 'vertical', 'PSV'),
    ('feyenoord', '#FF0000', '#FFFFFF', 'FEY', 'vertical', 'Feyenoord'),
    ('benfica', '#FF0000', '#FFFFFF', 'BEN', 'vertical', 'Benfica'),
    ('fc-porto', '#003893', '#FFFFFF', 'POR', 'vertical', 'Porto'),
    ('sporting-cp', '#008057', '#FFFFFF', 'SCP', 'vertical', 'Sporting'),
    ('celtic-fc', '#008050', '#FFFFFF', 'CEL', 'vertical', 'Celtic'),
    ('rangers-fc', '#1B458F', '#FFFFFF', 'RAN', 'vertical', 'Rangers'),
    ('galatasaray', '#FDB912', '#A90432', 'GAL', 'vertical', 'Galatasaray'),
    ('fenerbahce', '#FFED00', '#00205B', 'FEN', 'horizontal', 'Fenerbahce'),
    ('besiktas', '#000000', '#FFFFFF', 'BJK', 'vertical', 'Besiktas'),
    ('trabzonspor', '#7B002C', '#0072BC', 'TRA', 'vertical', 'Trabzonspor'),
    ('river-plate', '#FFFFFF', '#ED1C24', 'RIV', 'horizontal', 'River'),
    ('boca-juniors', '#003087', '#FCB131', 'BOC', 'vertical', 'Boca'),
    ('flamengo', '#C3281E', '#000000', 'FLA', 'vertical', 'Flamengo'),
    ('palmeiras', '#006437', '#FFFFFF', 'PAL', 'vertical', 'Palmeiras'),
    ('santos-fc', '#FFFFFF', '#000000', 'SAN', 'horizontal', 'Santos'),
    ('corinthians', '#000000', '#FFFFFF', 'COR', 'vertical', 'Corinthians'),
    ('club-america', '#FBCC17', '#00265D', 'AME', 'vertical', 'America'),
    ('monterrey', '#004481', '#FFFFFF', 'MTY', 'vertical', 'Monterrey'),
    ('la-galaxy', '#00245D', '#FFD200', 'LAG', 'vertical', 'LA Galaxy'),
    ('inter-miami', '#F7B5CD', '#000000', 'MIA', 'vertical', 'Inter Miami'),
    ('al-hilal', '#004AAC', '#FFFFFF', 'HIL', 'vertical', 'Al Hilal'),
    ('al-nassr', '#FEDC00', '#0E4D92', 'NSR', 'vertical', 'Al Nassr'),
    ('al-ahli', '#00783E', '#FFFFFF', 'AHL', 'vertical', 'Al Ahli'),
    ('shakhtar-donetsk', '#FF7800', '#000000', 'SHA', 'vertical', 'Shakhtar'),
    ('dynamo-kyiv', '#0457A6', '#FFFFFF', 'DYN', 'vertical', 'Dynamo'),
    ('red-star-belgrade', '#D6000F', '#FFFFFF', 'RSB', 'vertical', 'Red Star'),
    ('partizan', '#000000', '#FFFFFF', 'PAR', 'vertical', 'Partizan'),
    ('olympiacos', '#E30613', '#FFFFFF', 'OLY', 'vertical', 'Olympiacos'),
    ('panathinaikos', '#009B4B', '#FFFFFF', 'PAO', 'vertical', 'Panathinaikos'),
    ('copenhagen', '#0054A6', '#FFFFFF', 'FCK', 'vertical', 'Copenhagen'),
    ('brondby', '#FFDD00', '#0066B3', 'BIF', 'vertical', 'Brondby'),
    ('anderlecht', '#4B0082', '#FFFFFF', 'AND', 'vertical', 'Anderlecht'),
    ('club-brugge', '#0080C8', '#000000', 'BRU', 'vertical', 'Club Brugge'),
    ('basel', '#FF0000', '#0000FF', 'BAS', 'vertical', 'Basel'),
    ('young-boys', '#FFDD00', '#000000', 'YB', 'vertical', 'Young Boys'),
    ('salzburg', '#E30613', '#FFFFFF', 'RBS', 'vertical', 'Salzburg'),
    ('rapid-vienna', '#007A33', '#FFFFFF', 'RAP', 'vertical', 'Rapid'),
    ('sparta-prague', '#8B002E', '#FFFFFF', 'SPA', 'vertical', 'Sparta'),
    ('slavia-prague', '#E30613', '#FFFFFF', 'SLA', 'vertical', 'Slavia'),
    ('legia-warsaw', '#007A33', '#FFFFFF', 'LEG', 'vertical', 'Legia'),
    ('steaua-bucharest', '#0066CC', '#CC0000', 'STE', 'vertical', 'Steaua'),
    ('cfr-cluj', '#FF6600', '#000000', 'CFR', 'vertical', 'CFR Cluj'),
    ('dinamo-zagreb', '#0057B8', '#FFFFFF', 'DIN', 'vertical', 'Dinamo'),
    ('hajduk-split', '#FFFFFF', '#004B87', 'HAJ', 'horizontal', 'Hajduk'),
    ('malmo-ff', '#79BFEF', '#FFFFFF', 'MFF', 'vertical', 'Malmo'),
    ('aik', '#000000', '#FFEC00', 'AIK', 'vertical', 'AIK'),
    ('rosenborg', '#000000', '#FFFFFF', 'RBK', 'vertical', 'Rosenborg'),
    ('molde-fk', '#0054A0', '#FFFFFF', 'MOL', 'vertical', 'Molde'),
    ('hjk-helsinki', '#0066CC', '#FFFFFF', 'HJK', 'vertical', 'HJK'),
    ('qarabag-fk', '#000000', '#FFFFFF', 'QAR', 'vertical', 'Qarabag'),
    ('apoel', '#FFD700', '#004799', 'APO', 'vertical', 'APOEL'),
    ('omonia', '#007A33', '#FFFFFF', 'OMO', 'vertical', 'Omonia'),
    ('maccabi-tel-aviv', '#FEDD00', '#004899', 'MTA', 'vertical', 'Maccabi TA'),
    ('maccabi-haifa', '#007A33', '#FFFFFF', 'MHA', 'vertical', 'Maccabi HA'),
    ('sydney-fc', '#88C5EE', '#FFFFFF', 'SYD', 'vertical', 'Sydney'),
    ('melbourne-city', '#6CACDE', '#FFFFFF', 'MCY', 'vertical', 'Melbourne'),
    ('urawa-red-diamonds', '#E60012', '#FFFFFF', 'URA', 'vertical', 'Urawa'),
    ('kashima-antlers', '#E60012', '#0055A4', 'KAS', 'vertical', 'Kashima'),
    ('guangzhou-fc', '#E60012', '#FFFFFF', 'GZ', 'vertical', 'Guangzhou'),
    ('shanghai-sipg', '#E60012', '#FFFFFF', 'SIP', 'vertical', 'SIPG'),
    ('ulsan-hd', '#004689', '#F5A623', 'ULS', 'vertical', 'Ulsan'),
    ('jeonbuk-hyundai', '#006633', '#FFFFFF', 'JHM', 'vertical', 'Jeonbuk'),
    ('wydad-ac', '#E60012', '#FFFFFF', 'WAC', 'vertical', 'Wydad'),
    ('raja-casablanca', '#007A33', '#FFFFFF', 'RAJ', 'vertical', 'Raja'),
    ('esperance-tunis', '#FFD700', '#E60012', 'EST', 'vertical', 'Esperance'),
    ('al-ahly-cairo', '#E60012', '#FFFFFF', 'AHL', 'vertical', 'Al Ahly'),
    ('kaizer-chiefs', '#FFB612', '#000000', 'KAI', 'vertical', 'Kaizer'),
    ('orlando-pirates', '#000000', '#FFFFFF', 'PIR', 'vertical', 'Pirates')
  ) AS v(slug, badge_primary_color, badge_secondary_color, badge_initials, badge_gradient_style, short_name)
)
UPDATE clubs AS c
SET
  badge_primary_color = s.badge_primary_color,
  badge_secondary_color = s.badge_secondary_color,
  badge_initials = s.badge_initials,
  badge_gradient_style = s.badge_gradient_style,
  short_name = s.short_name
FROM badge_seed AS s
WHERE c.slug = s.slug;

UPDATE clubs
SET
  badge_initials = COALESCE(badge_initials, upper(left(replace(name, ' ', ''), 3))),
  badge_primary_color = COALESCE(badge_primary_color, '#333333'),
  badge_secondary_color = COALESCE(badge_secondary_color, '#666666'),
  badge_gradient_style = COALESCE(badge_gradient_style, 'vertical'),
  short_name = COALESCE(short_name, name)
WHERE is_top_club = TRUE
  AND badge_initials IS NULL;

CREATE OR REPLACE FUNCTION public.get_intersection_players(
  p_row_club_id UUID,
  p_col_club_id UUID
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  nationality_code CHAR(2),
  primary_position TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT p.id, p.name, p.nationality_code, p.primary_position
  FROM players p
  WHERE EXISTS (
    SELECT 1 FROM player_career_history h1
    WHERE h1.player_id = p.id
      AND h1.club_id = p_row_club_id
      AND h1.is_senior = TRUE
      AND h1.is_youth = FALSE
      AND h1.is_reserve = FALSE
  )
  AND EXISTS (
    SELECT 1 FROM player_career_history h2
    WHERE h2.player_id = p.id
      AND h2.club_id = p_col_club_id
      AND h2.is_senior = TRUE
      AND h2.is_youth = FALSE
      AND h2.is_reserve = FALSE
  )
  LIMIT 50;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_intersection_players(UUID, UUID) TO anon, authenticated;
