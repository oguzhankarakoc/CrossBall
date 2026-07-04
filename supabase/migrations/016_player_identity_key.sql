-- Player identity key for cross-source deduplication (Kaggle + API-Football + patches).

ALTER TABLE players
  ADD COLUMN IF NOT EXISTS identity_key TEXT;

CREATE INDEX IF NOT EXISTS idx_players_identity_key
  ON players (identity_key)
  WHERE identity_key IS NOT NULL AND identity_key <> '';

COMMENT ON COLUMN players.identity_key IS
  'Stable dedup key: surname|first-token (e.g. ibrahimovic|z). See pipeline/player_identity.py';
