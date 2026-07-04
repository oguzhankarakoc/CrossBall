# CrossBall GitHub Actions — Data Automation

Automated data sync keeps career history and daily puzzles fresh without manual terminal runs.

## Required secrets

Repository → **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Required | Description |
|--------|----------|-------------|
| `DATABASE_URL` | Yes | Supabase Postgres URI (`data_pipeline/.env`) |
| `API_FOOTBALL_KEY` | Yes (daily sync) | Free key from [api-football.com](https://www.api-football.com/) |
| `KAGGLE_USERNAME` | No | Enables full Kaggle download in weekly job |
| `KAGGLE_KEY` | No | Kaggle API token |

Never commit `.env` files — secrets only in GitHub Settings.

## Workflows

### Data Sync (Daily) — `data-sync-daily.yml`

| | |
|--|--|
| **Schedule** | Every day 04:00 UTC (07:00 Istanbul) |
| **Manual** | Actions → Data Sync (Daily) → Run workflow |
| **Script** | `./scripts/run_scheduled_sync.sh` |
| **Steps** | API-Football transfers (30 teams, rotating offset) → patch load → `ensure_daily_puzzle` |
| **API cost** | ~30 requests/day (free tier: 100/day) |

### Data ETL (Weekly) — `data-etl-weekly.yml`

| | |
|--|--|
| **Schedule** | Sunday 05:00 UTC (08:00 Istanbul) |
| **Manual** | Actions → Data ETL (Weekly) → Run workflow |
| **Script** | `./scripts/run_scheduled_etl.sh` |
| **Steps** | Kaggle fetch (if secrets set) or transform committed CSV → full load → patches |

### CI — `ci.yml`

Runs on push/PR to `main` and `feature/**`: Flutter analyze/test + pipeline pytest. **Does not** run data sync.

## First-time setup checklist

1. Push this repo to GitHub (includes workflow YAML files)
2. Add `DATABASE_URL` and `API_FOOTBALL_KEY` secrets
3. Actions → **Data Sync (Daily)** → **Run workflow** (test)
4. Check workflow logs for green status
5. Verify in Supabase:
   ```sql
   SELECT COUNT(*) FROM club_relationships;
   SELECT puzzle_date, difficulty_tier FROM puzzles WHERE mode = 'daily' ORDER BY puzzle_date DESC LIMIT 3;
   ```

## Local alternative

If you prefer Mac cron instead of GitHub Actions:

```bash
./scripts/install_local_cron.sh --install
```

Requires `data_pipeline/.env` on the machine. Mac must stay on at scheduled times.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Workflow fails: missing secret | Secrets not configured | Add `DATABASE_URL` + `API_FOOTBALL_KEY` |
| DB deadlock | Two syncs at once (local + Actions) | Run only one sync at a time |
| API quota exceeded | >100 requests/day | Wait 24h; cache reduces repeat calls |
| Daily puzzle unchanged | `ensure_daily_puzzle` already ran today | Expected — one puzzle per UTC date |
