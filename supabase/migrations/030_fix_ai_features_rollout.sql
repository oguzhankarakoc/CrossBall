-- Fix stale rollout JSON that kept ai_features disabled after 024 enabled the flag.

UPDATE liveops_feature_flags
SET
  is_enabled = TRUE,
  default_value = TRUE,
  rollout = '{"type": "global", "enabled": true}'::jsonb
WHERE slug IN ('ai_features', 'friend_activity_feed', 'timeline_mode');

UPDATE public.football_facts
SET
  fact_en = 'The rarest names at a club crossing often score highest — bold picks beat obvious ones.',
  fact_tr = 'İki kulübün kesişiminde az bilinen isimler çoğu zaman daha yüksek puan getirir — cesur tahminler seni öne taşır.',
  fact_de = 'Seltene Namen an einer Vereins-Kreuzung bringen oft mehr Punkte — mutige Tipps schlagen offensichtliche.'
WHERE fact_key = 'intersection_rare_default';
