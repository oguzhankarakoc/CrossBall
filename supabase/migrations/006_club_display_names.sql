-- PostgreSQL / Supabase migration
-- Dual club identity: display_name, short_code, league_name for puzzle recognition
-- Safe to re-run.

DO $migration$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'clubs' AND column_name = 'badge_initials'
  ) THEN
    ALTER TABLE public.clubs ADD badge_initials TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'clubs' AND column_name = 'short_name'
  ) THEN
    ALTER TABLE public.clubs ADD short_name TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'clubs' AND column_name = 'display_name'
  ) THEN
    ALTER TABLE public.clubs ADD display_name TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'clubs' AND column_name = 'short_code'
  ) THEN
    ALTER TABLE public.clubs ADD short_code TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'clubs' AND column_name = 'league_name'
  ) THEN
    ALTER TABLE public.clubs ADD league_name TEXT;
  END IF;
END
$migration$;

-- Backfill from existing columns
UPDATE clubs SET display_name = name WHERE display_name IS NULL;
UPDATE clubs SET short_code = badge_initials WHERE short_code IS NULL AND badge_initials IS NOT NULL;

-- Curated display metadata (matches lib/core/club_identity/club_display_resolver.dart)
WITH display_seed AS (
  SELECT * FROM (VALUES
    ('barcelona', 'FC Barcelona', 'Barcelona', 'BAR', 'La Liga'),
    ('fc-barcelona', 'FC Barcelona', 'Barcelona', 'BAR', 'La Liga'),
    ('real-madrid', 'Real Madrid CF', 'Real Madrid', 'RMA', 'La Liga'),
    ('atletico-madrid', 'Atlético Madrid', 'Atletico', 'ATM', 'La Liga'),
    ('sevilla-fc', 'Sevilla FC', 'Sevilla', 'SEV', 'La Liga'),
    ('valencia-cf', 'Valencia CF', 'Valencia', 'VAL', 'La Liga'),
    ('chelsea', 'Chelsea FC', 'Chelsea', 'CHE', 'Premier League'),
    ('chelsea-fc', 'Chelsea FC', 'Chelsea', 'CHE', 'Premier League'),
    ('manchester-united', 'Manchester United', 'Man United', 'MUN', 'Premier League'),
    ('manchester-city', 'Manchester City', 'Man City', 'MCI', 'Premier League'),
    ('liverpool-fc', 'Liverpool FC', 'Liverpool', 'LIV', 'Premier League'),
    ('arsenal-fc', 'Arsenal FC', 'Arsenal', 'ARS', 'Premier League'),
    ('tottenham-hotspur', 'Tottenham Hotspur', 'Tottenham', 'TOT', 'Premier League'),
    ('newcastle-united', 'Newcastle United', 'Newcastle', 'NEW', 'Premier League'),
    ('west-ham-united', 'West Ham United', 'West Ham', 'WHU', 'Premier League'),
    ('aston-villa', 'Aston Villa', 'Aston Villa', 'AVL', 'Premier League'),
    ('everton-fc', 'Everton FC', 'Everton', 'EVE', 'Premier League'),
    ('bayern-munich', 'FC Bayern Munich', 'Bayern', 'BAY', 'Bundesliga'),
    ('borussia-dortmund', 'Borussia Dortmund', 'Dortmund', 'BVB', 'Bundesliga'),
    ('rb-leipzig', 'RB Leipzig', 'Leipzig', 'RBL', 'Bundesliga'),
    ('bayer-leverkusen', 'Bayer Leverkusen', 'Leverkusen', 'B04', 'Bundesliga'),
    ('borussia-monchengladbach', 'Borussia Mönchengladbach', 'Gladbach', 'BMG', 'Bundesliga'),
    ('juventus', 'Juventus FC', 'Juventus', 'JUV', 'Serie A'),
    ('ac-milan', 'AC Milan', 'AC Milan', 'MIL', 'Serie A'),
    ('inter-milan', 'Inter Milan', 'Inter', 'INT', 'Serie A'),
    ('as-roma', 'AS Roma', 'Roma', 'ROM', 'Serie A'),
    ('napoli', 'SSC Napoli', 'Napoli', 'NAP', 'Serie A'),
    ('lazio', 'SS Lazio', 'Lazio', 'LAZ', 'Serie A'),
    ('fiorentina', 'ACF Fiorentina', 'Fiorentina', 'FIO', 'Serie A'),
    ('paris-saintgermain', 'Paris Saint-Germain', 'PSG', 'PSG', 'Ligue 1'),
    ('psg', 'Paris Saint-Germain', 'PSG', 'PSG', 'Ligue 1'),
    ('lyon', 'Olympique Lyonnais', 'Lyon', 'OL', 'Ligue 1'),
    ('marseille', 'Olympique Marseille', 'Marseille', 'OM', 'Ligue 1'),
    ('monaco', 'AS Monaco', 'Monaco', 'MON', 'Ligue 1'),
    ('lille-osc', 'Lille OSC', 'Lille', 'LIL', 'Ligue 1'),
    ('galatasaray', 'Galatasaray SK', 'Galatasaray', 'GAL', 'Süper Lig'),
    ('fenerbahce', 'Fenerbahçe SK', 'Fenerbahce', 'FEN', 'Süper Lig'),
    ('besiktas', 'Beşiktaş JK', 'Besiktas', 'BJK', 'Süper Lig'),
    ('trabzonspor', 'Trabzonspor', 'Trabzonspor', 'TRA', 'Süper Lig'),
    ('ajax', 'AFC Ajax', 'Ajax', 'AJA', 'Eredivisie'),
    ('psv-eindhoven', 'PSV Eindhoven', 'PSV', 'PSV', 'Eredivisie'),
    ('feyenoord', 'Feyenoord', 'Feyenoord', 'FEY', 'Eredivisie'),
    ('benfica', 'SL Benfica', 'Benfica', 'BEN', 'Primeira Liga'),
    ('fc-porto', 'FC Porto', 'Porto', 'POR', 'Primeira Liga'),
    ('sporting-cp', 'Sporting CP', 'Sporting', 'SCP', 'Primeira Liga'),
    ('celtic-fc', 'Celtic FC', 'Celtic', 'CEL', 'Scottish Premiership'),
    ('rangers-fc', 'Rangers FC', 'Rangers', 'RAN', 'Scottish Premiership'),
    ('river-plate', 'Club Atlético River Plate', 'River', 'RIV', 'Liga Profesional'),
    ('boca-juniors', 'Club Atlético Boca Juniors', 'Boca', 'BOC', 'Liga Profesional'),
    ('flamengo', 'CR Flamengo', 'Flamengo', 'FLA', 'Brasileirão'),
    ('palmeiras', 'SE Palmeiras', 'Palmeiras', 'PAL', 'Brasileirão'),
    ('santos-fc', 'Santos FC', 'Santos', 'SAN', 'Brasileirão'),
    ('corinthians', 'SC Corinthians', 'Corinthians', 'COR', 'Brasileirão'),
    ('club-america', 'Club América', 'America', 'AME', 'Liga MX'),
    ('monterrey', 'CF Monterrey', 'Monterrey', 'MTY', 'Liga MX'),
    ('la-galaxy', 'LA Galaxy', 'LA Galaxy', 'LAG', 'MLS'),
    ('inter-miami', 'Inter Miami CF', 'Inter Miami', 'MIA', 'MLS'),
    ('al-hilal', 'Al Hilal', 'Al Hilal', 'HIL', 'Saudi Pro League'),
    ('al-nassr', 'Al Nassr', 'Al Nassr', 'NSR', 'Saudi Pro League'),
    ('al-ahli', 'Al Ahli', 'Al Ahli', 'AHL', 'Saudi Pro League'),
    ('al-ahly-cairo', 'Al Ahly SC', 'Al Ahly', 'AHL', 'Egyptian Premier League'),
    ('shakhtar-donetsk', 'FC Shakhtar Donetsk', 'Shakhtar', 'SHA', 'Ukrainian Premier League'),
    ('dynamo-kyiv', 'FC Dynamo Kyiv', 'Dynamo', 'DYN', 'Ukrainian Premier League'),
    ('red-star-belgrade', 'Red Star Belgrade', 'Red Star', 'RSB', 'Serbian SuperLiga'),
    ('partizan', 'FK Partizan', 'Partizan', 'PAR', 'Serbian SuperLiga'),
    ('olympiacos', 'Olympiacos FC', 'Olympiacos', 'OLY', 'Super League Greece'),
    ('panathinaikos', 'Panathinaikos FC', 'Panathinaikos', 'PAO', 'Super League Greece'),
    ('copenhagen', 'FC Copenhagen', 'Copenhagen', 'FCK', 'Danish Superliga'),
    ('brondby', 'Brøndby IF', 'Brondby', 'BIF', 'Danish Superliga'),
    ('anderlecht', 'RSC Anderlecht', 'Anderlecht', 'AND', 'Belgian Pro League'),
    ('club-brugge', 'Club Brugge', 'Club Brugge', 'BRU', 'Belgian Pro League'),
    ('basel', 'FC Basel', 'Basel', 'BAS', 'Swiss Super League'),
    ('young-boys', 'BSC Young Boys', 'Young Boys', 'YB', 'Swiss Super League'),
    ('salzburg', 'FC Salzburg', 'Salzburg', 'RBS', 'Austrian Bundesliga'),
    ('rapid-vienna', 'SK Rapid Wien', 'Rapid', 'RAP', 'Austrian Bundesliga'),
    ('sparta-prague', 'AC Sparta Prague', 'Sparta', 'SPA', 'Czech First League'),
    ('slavia-prague', 'SK Slavia Prague', 'Slavia', 'SLA', 'Czech First League'),
    ('legia-warsaw', 'Legia Warsaw', 'Legia', 'LEG', 'Ekstraklasa'),
    ('steaua-bucharest', 'FCSB', 'Steaua', 'STE', 'Liga I'),
    ('cfr-cluj', 'CFR Cluj', 'CFR Cluj', 'CFR', 'Liga I'),
    ('dinamo-zagreb', 'GNK Dinamo Zagreb', 'Dinamo', 'DIN', 'HNL'),
    ('hajduk-split', 'HNK Hajduk Split', 'Hajduk', 'HAJ', 'HNL'),
    ('malmo-ff', 'Malmö FF', 'Malmo', 'MFF', 'Allsvenskan'),
    ('aik', 'AIK', 'AIK', 'AIK', 'Allsvenskan'),
    ('rosenborg', 'Rosenborg BK', 'Rosenborg', 'RBK', 'Eliteserien'),
    ('molde-fk', 'Molde FK', 'Molde', 'MOL', 'Eliteserien'),
    ('hjk-helsinki', 'HJK Helsinki', 'HJK', 'HJK', 'Veikkausliiga'),
    ('qarabag-fk', 'Qarabağ FK', 'Qarabag', 'QAR', 'Azerbaijan Premier League'),
    ('apoel', 'APOEL FC', 'APOEL', 'APO', 'Cypriot First Division'),
    ('omonia', 'AC Omonia', 'Omonia', 'OMO', 'Cypriot First Division'),
    ('maccabi-tel-aviv', 'Maccabi Tel Aviv', 'Maccabi TA', 'MTA', 'Israeli Premier League'),
    ('maccabi-haifa', 'Maccabi Haifa', 'Maccabi HA', 'MHA', 'Israeli Premier League'),
    ('sydney-fc', 'Sydney FC', 'Sydney', 'SYD', 'A-League'),
    ('melbourne-city', 'Melbourne City FC', 'Melbourne', 'MCY', 'A-League'),
    ('urawa-red-diamonds', 'Urawa Red Diamonds', 'Urawa', 'URA', 'J1 League'),
    ('kashima-antlers', 'Kashima Antlers', 'Kashima', 'KAS', 'J1 League'),
    ('guangzhou-fc', 'Guangzhou FC', 'Guangzhou', 'GZ', 'Chinese Super League'),
    ('shanghai-sipg', 'Shanghai Port FC', 'SIPG', 'SIP', 'Chinese Super League'),
    ('ulsan-hd', 'Ulsan HD FC', 'Ulsan', 'ULS', 'K League 1'),
    ('jeonbuk-hyundai', 'Jeonbuk Hyundai Motors', 'Jeonbuk', 'JHM', 'K League 1'),
    ('wydad-ac', 'Wydad AC', 'Wydad', 'WAC', 'Botola Pro'),
    ('raja-casablanca', 'Raja CA', 'Raja', 'RAJ', 'Botola Pro'),
    ('esperance-tunis', 'Espérance de Tunis', 'Esperance', 'EST', 'Tunisian Ligue Professionnelle 1'),
    ('kaizer-chiefs', 'Kaizer Chiefs', 'Kaizer', 'KAI', 'Premier Soccer League'),
    ('orlando-pirates', 'Orlando Pirates', 'Pirates', 'PIR', 'Premier Soccer League')
  ) AS v(slug, display_name, short_name, short_code, league_name)
)
UPDATE clubs c
SET
  display_name = s.display_name,
  short_name = s.short_name,
  short_code = s.short_code,
  league_name = s.league_name
FROM display_seed s
WHERE c.slug = s.slug;

-- Fallbacks for remaining top clubs
UPDATE clubs
SET short_name = COALESCE(NULLIF(short_name, ''), display_name, name)
WHERE is_top_club = TRUE AND (short_name IS NULL OR short_name = '');

UPDATE clubs
SET short_code = COALESCE(NULLIF(short_code, ''), NULLIF(badge_initials, ''))
WHERE is_top_club = TRUE AND (short_code IS NULL OR short_code = '');

UPDATE clubs
SET short_code = upper(left(regexp_replace(name, '[^A-Za-z0-9]', '', 'g'), 3))
WHERE is_top_club = TRUE
  AND (short_code IS NULL OR short_code = '')
  AND length(regexp_replace(name, '[^A-Za-z0-9]', '', 'g')) >= 3;
