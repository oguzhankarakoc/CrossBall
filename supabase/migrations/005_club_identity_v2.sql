-- PostgreSQL / Supabase migration
-- Club identity v2: accent color + abstract symbol types (legal-safe metadata)
-- Safe to re-run.

DO $migration$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'clubs' AND column_name = 'badge_icon_type'
  ) THEN
    ALTER TABLE public.clubs ADD badge_icon_type TEXT DEFAULT 'shield';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'clubs' AND column_name = 'badge_gradient_style'
  ) THEN
    ALTER TABLE public.clubs ADD badge_gradient_style TEXT DEFAULT 'vertical';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'clubs' AND column_name = 'badge_accent_color'
  ) THEN
    ALTER TABLE public.clubs ADD badge_accent_color TEXT;
  END IF;
END
$migration$;

-- Curated symbol + accent metadata (matches lib/core/club_identity/club_identity_data.dart)
WITH identity_seed AS (
  SELECT * FROM (VALUES
    ('barcelona', 'abstract_stripes', '#FFD700', 'vertical'),
    ('fc-barcelona', 'abstract_stripes', '#FFD700', 'vertical'),
    ('real-madrid', 'abstract_crown', '#C0C0C0', 'metallic'),
    ('atletico-madrid', 'abstract_waves', '#1A3A6B', 'vertical'),
    ('sevilla-fc', 'abstract_cross', '#FFD700', 'horizontal'),
    ('valencia-cf', 'abstract_diamond', '#FF8C00', 'vertical'),
    ('chelsea', 'abstract_lion', '#FFD700', 'metallic'),
    ('chelsea-fc', 'abstract_lion', '#FFD700', 'metallic'),
    ('manchester-united', 'abstract_orb', '#000000', 'vertical'),
    ('manchester-city', 'abstract_shield', '#1C2C5B', 'radial'),
    ('liverpool-fc', 'abstract_flame', '#FFD700', 'vertical'),
    ('arsenal-fc', 'abstract_chevron', '#FFD700', 'vertical'),
    ('tottenham-hotspur', 'abstract_star', '#C0C0C0', 'vertical'),
    ('newcastle-united', 'abstract_shield', '#888888', 'vertical'),
    ('west-ham-united', 'abstract_cross', '#FFD700', 'vertical'),
    ('aston-villa', 'abstract_star', '#FFD700', 'vertical'),
    ('everton-fc', 'abstract_chevron', '#FFD700', 'vertical'),
    ('bayern-munich', 'abstract_diamond', '#FFFFFF', 'vertical'),
    ('borussia-dortmund', 'abstract_stripes', '#FFFFFF', 'horizontal'),
    ('rb-leipzig', 'abstract_orb', '#002D5C', 'vertical'),
    ('bayer-leverkusen', 'abstract_cross', '#FFFFFF', 'vertical'),
    ('borussia-monchengladbach', 'abstract_diamond', '#1F6841', 'vertical'),
    ('juventus', 'abstract_stripes', '#C0C0C0', 'metallic'),
    ('ac-milan', 'abstract_cross', '#FFFFFF', 'vertical'),
    ('inter-milan', 'abstract_orb', '#FFD700', 'vertical'),
    ('as-roma', 'abstract_flame', '#FFD700', 'vertical'),
    ('napoli', 'abstract_waves', '#FFD700', 'radial'),
    ('lazio', 'abstract_waves', '#FFD700', 'vertical'),
    ('fiorentina', 'abstract_flame', '#FFD700', 'vertical'),
    ('paris-saintgermain', 'abstract_orb', '#FFD700', 'metallic'),
    ('psg', 'abstract_orb', '#FFD700', 'metallic'),
    ('lyon', 'abstract_lion', '#FFFFFF', 'vertical'),
    ('marseille', 'abstract_star', '#FFD700', 'radial'),
    ('monaco', 'abstract_crown', '#FFD700', 'metallic'),
    ('lille-osc', 'abstract_orb', '#002D5C', 'vertical'),
    ('galatasaray', 'abstract_star', '#FFD700', 'vertical'),
    ('fenerbahce', 'abstract_diamond', '#FFFFFF', 'horizontal'),
    ('besiktas', 'abstract_stripes', '#FFD700', 'vertical'),
    ('trabzonspor', 'abstract_waves', '#FFD700', 'vertical'),
    ('ajax', 'abstract_orb', '#FFD700', 'vertical'),
    ('psv-eindhoven', 'abstract_stripes', '#FFD700', 'vertical'),
    ('feyenoord', 'abstract_orb', '#000000', 'vertical'),
    ('benfica', 'abstract_waves', '#FFD700', 'vertical'),
    ('fc-porto', 'abstract_flame', '#FFD700', 'vertical'),
    ('sporting-cp', 'abstract_lion', '#FFD700', 'vertical'),
    ('celtic-fc', 'abstract_cross', '#FFD700', 'vertical'),
    ('rangers-fc', 'abstract_star', '#FFD700', 'vertical'),
    ('river-plate', 'abstract_waves', '#FFD700', 'horizontal'),
    ('boca-juniors', 'abstract_waves', '#FFFFFF', 'horizontal'),
    ('flamengo', 'abstract_stripes', '#FFFFFF', 'vertical'),
    ('palmeiras', 'abstract_diamond', '#FFD700', 'vertical'),
    ('santos-fc', 'abstract_orb', '#FFD700', 'horizontal'),
    ('corinthians', 'abstract_orb', '#FFD700', 'vertical'),
    ('inter-miami', 'abstract_waves', '#FFFFFF', 'radial'),
    ('la-galaxy', 'abstract_star', '#FFFFFF', 'vertical'),
    ('al-hilal', 'abstract_orb', '#FFD700', 'metallic'),
    ('al-nassr', 'abstract_star', '#FFFFFF', 'vertical'),
    ('al-ahli', 'abstract_star', '#FFD700', 'vertical'),
    ('al-ahly-cairo', 'abstract_waves', '#FFD700', 'vertical')
  ) AS v(slug, badge_icon_type, badge_accent_color, badge_gradient_style)
)
UPDATE clubs c
SET
  badge_icon_type = s.badge_icon_type,
  badge_accent_color = s.badge_accent_color,
  badge_gradient_style = s.badge_gradient_style
FROM identity_seed s
WHERE c.slug = s.slug;

-- Default accent for top clubs missing it
UPDATE clubs
SET badge_accent_color = '#FFD700'
WHERE badge_accent_color IS NULL AND is_top_club = TRUE;

-- Generic abstract shield for remaining top clubs still on legacy default
UPDATE clubs
SET badge_icon_type = 'abstract_shield'
WHERE is_top_club = TRUE
  AND (badge_icon_type IS NULL OR badge_icon_type = 'shield');
