-- Migration 025: Curated club identity for remaining top clubs (46 slugs)
-- Matches lib/core/club_identity/club_identity_data.dart

WITH identity_seed AS (
  SELECT * FROM (VALUES
    ('aik', 'abstract_stripes', '#FFFFFF', 'vertical'),
    ('anderlecht', 'abstract_diamond', '#FFD700', 'vertical'),
    ('apoel', 'abstract_cross', '#FFFFFF', 'vertical'),
    ('basel', 'abstract_cross', '#FFFFFF', 'vertical'),
    ('brondby', 'abstract_waves', '#FFFFFF', 'vertical'),
    ('cfr-cluj', 'abstract_flame', '#FFD700', 'vertical'),
    ('club-america', 'abstract_eagle', '#FFFFFF', 'vertical'),
    ('club-brugge', 'abstract_diamond', '#FFD700', 'vertical'),
    ('copenhagen', 'abstract_waves', '#FFD700', 'radial'),
    ('dinamo-zagreb', 'abstract_chevron', '#FFD700', 'vertical'),
    ('dynamo-kyiv', 'abstract_star', '#FFD700', 'vertical'),
    ('esperance-tunis', 'abstract_star', '#FFFFFF', 'metallic'),
    ('guangzhou-fc', 'abstract_flame', '#FFD700', 'vertical'),
    ('hajduk-split', 'abstract_waves', '#FFD700', 'horizontal'),
    ('hjk-helsinki', 'abstract_cross', '#FFD700', 'vertical'),
    ('jeonbuk-hyundai', 'abstract_stripes', '#FFD700', 'vertical'),
    ('kaizer-chiefs', 'abstract_crown', '#FFFFFF', 'metallic'),
    ('kashima-antlers', 'abstract_chevron', '#FFFFFF', 'vertical'),
    ('legia-warsaw', 'abstract_eagle', '#FFD700', 'vertical'),
    ('maccabi-haifa', 'abstract_star', '#FFD700', 'vertical'),
    ('maccabi-tel-aviv', 'abstract_star', '#FFFFFF', 'vertical'),
    ('malmo-ff', 'abstract_waves', '#004799', 'vertical'),
    ('melbourne-city', 'abstract_compass', '#FFD700', 'vertical'),
    ('molde-fk', 'abstract_waves', '#FFD700', 'vertical'),
    ('monterrey', 'abstract_diamond', '#FFD700', 'vertical'),
    ('olympiacos', 'abstract_flame', '#FFD700', 'vertical'),
    ('omonia', 'abstract_orb', '#FFD700', 'vertical'),
    ('orlando-pirates', 'abstract_waves', '#FFD700', 'vertical'),
    ('panathinaikos', 'abstract_oak', '#FFD700', 'vertical'),
    ('partizan', 'abstract_stripes', '#FFD700', 'vertical'),
    ('qarabag-fk', 'abstract_diamond', '#FFD700', 'metallic'),
    ('raja-casablanca', 'abstract_star', '#FFD700', 'vertical'),
    ('rapid-vienna', 'abstract_flame', '#FFD700', 'vertical'),
    ('red-star-belgrade', 'abstract_star', '#FFD700', 'vertical'),
    ('rosenborg', 'abstract_crown', '#FFD700', 'vertical'),
    ('salzburg', 'abstract_diamond', '#FFD700', 'metallic'),
    ('shakhtar-donetsk', 'abstract_flame', '#FFD700', 'vertical'),
    ('shanghai-sipg', 'abstract_compass', '#FFD700', 'vertical'),
    ('slavia-prague', 'abstract_lion', '#FFD700', 'vertical'),
    ('sparta-prague', 'abstract_chevron', '#FFD700', 'vertical'),
    ('steaua-bucharest', 'abstract_star', '#FFD700', 'radial'),
    ('sydney-fc', 'abstract_waves', '#004799', 'radial'),
    ('ulsan-hd', 'abstract_compass', '#FFFFFF', 'vertical'),
    ('urawa-red-diamonds', 'abstract_diamond', '#FFD700', 'vertical'),
    ('wydad-ac', 'abstract_flame', '#FFD700', 'vertical'),
    ('young-boys', 'abstract_stripes', '#FFFFFF', 'horizontal'),
    -- Sync refreshed Flutter symbols for major clubs
    ('liverpool-fc', 'abstract_wings', '#FFD700', 'vertical'),
    ('manchester-city', 'abstract_compass', '#1C2C5B', 'radial'),
    ('galatasaray', 'abstract_lion', '#FFD700', 'vertical'),
    ('fenerbahce', 'abstract_oak', '#FFFFFF', 'horizontal'),
    ('besiktas', 'abstract_eagle', '#FFD700', 'vertical'),
    ('juventus', 'abstract_chevron', '#C0C0C0', 'metallic'),
    ('newcastle-united', 'abstract_star', '#888888', 'vertical')
  ) AS v(slug, badge_icon_type, badge_accent_color, badge_gradient_style)
)
UPDATE clubs c
SET
  badge_icon_type = s.badge_icon_type,
  badge_accent_color = s.badge_accent_color,
  badge_gradient_style = s.badge_gradient_style
FROM identity_seed s
WHERE c.slug = s.slug;
