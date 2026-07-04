-- LiveOps admin SQL examples
-- Run in Supabase SQL Editor or: psql "$DATABASE_URL" -f scripts/liveops_admin.sql
--
-- Do NOT paste into zsh/macOS terminal directly.

-- =============================================================================
-- 1. Feature flag: disable friend challenges (test)
-- =============================================================================
-- UPDATE liveops_feature_flags
-- SET rollout = '{"type": "global", "enabled": false}', updated_at = NOW()
-- WHERE slug = 'friend_challenges';

-- Re-enable:
-- UPDATE liveops_feature_flags
-- SET rollout = '{"type": "global", "enabled": true}', updated_at = NOW()
-- WHERE slug = 'friend_challenges';

-- =============================================================================
-- 2. Emergency maintenance banner (shows notice; puzzles still playable)
-- =============================================================================
-- UPDATE liveops_config
-- SET value = '{"maintenance_mode": true, "disable_new_sessions": false, "message": "Kısa süreli bakım yapılıyor."}',
--     updated_at = NOW()
-- WHERE key = 'emergency';

-- Clear maintenance:
-- UPDATE liveops_config
-- SET value = '{"maintenance_mode": false, "disable_new_sessions": false, "message": null}',
--     updated_at = NOW()
-- WHERE key = 'emergency';

-- =============================================================================
-- 3. New announcement (EN / TR / DE) — ready to run
-- =============================================================================

INSERT INTO liveops_announcements (slug, announcement_type, priority, deep_link, starts_at, ends_at)
VALUES (
  'season_kickoff_2026',
  'event',
  20,
  '/puzzle?mode=daily',
  NOW(),
  NOW() + INTERVAL '14 days'
)
ON CONFLICT (slug) DO UPDATE SET
  is_active = TRUE,
  starts_at = NOW(),
  ends_at = NOW() + INTERVAL '14 days';

INSERT INTO liveops_announcement_i18n (announcement_slug, locale, title, body, button_label) VALUES
  ('season_kickoff_2026', 'en', 'New Season Live', 'Fresh events and challenges — no app update needed.', 'Play Daily'),
  ('season_kickoff_2026', 'tr', 'Yeni Sezon Başladı', 'Yeni etkinlikler ve mücadeleler — uygulama güncellemesi gerekmez.', 'Günlük Oyna'),
  ('season_kickoff_2026', 'de', 'Neue Saison live', 'Neue Events und Herausforderungen — kein App-Update nötig.', 'Täglich spielen')
ON CONFLICT (announcement_slug, locale) DO UPDATE SET
  title = EXCLUDED.title,
  body = EXCLUDED.body,
  button_label = EXCLUDED.button_label;

-- =============================================================================
-- 4. Verify snapshot (optional)
-- =============================================================================
-- SELECT loe_get_snapshot(NULL, 'tr', 'ios', 'TR', '1.0.0');
