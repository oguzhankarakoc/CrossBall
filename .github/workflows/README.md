# CrossBall GitHub Actions — Data Automation

Automated data sync keeps career history and daily puzzles fresh without manual terminal runs.

## Required secrets

Repository → **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Required | Description |
|--------|----------|-------------|
| `DATABASE_URL` | Yes | **Transaction pooler** URI for CI (see below) — not the direct `db.*:5432` string |
| `API_FOOTBALL_KEY` | Yes (daily sync) | Free key from [api-football.com](https://www.api-football.com/) |
| `KAGGLE_USERNAME` | No | Enables full Kaggle download in weekly job |
| `KAGGLE_KEY` | No | Kaggle API token |

Never commit `.env` files — secrets only in GitHub Settings.

### DATABASE_URL for GitHub Actions (important)

CrossBall Supabase project region: **ap-south-1**. GitHub runners **cannot** reach direct connection (`db.*.supabase.co:5432` — IPv6 only).

Use **Transaction pooler** (port **6543**) in the `DATABASE_URL` secret:

```
postgresql://postgres.kseqeqpoouneaiymdzpq:[PASSWORD]@aws-0-ap-south-1.pooler.supabase.com:6543/postgres
```

Supabase → **Connect** → URI → **Transaction pooler** → copy. Same DB password as local.

Keep `data_pipeline/.env` on your Mac with direct connection (`db.*:5432`) — that still works locally.

## Workflows

### Data Sync (Daily) — `data-sync-daily.yml`

| | |
|--|--|
| **Schedule** | Every day **00:00 UTC** (03:00 Istanbul / TRT) |
| **Manual** | Actions → Data Sync (Daily) → Run workflow |
| **Script** | `./scripts/run_scheduled_sync.sh` |
| **Steps** | Pending SQL migrations → API-Football transfers (30 teams, rotating offset) → **light** patch load → `ensure_daily_puzzle` |
| **API cost** | ~30 requests/day (free tier: 100/day) |
| **Timeout** | 90 min (light load skips dedupe + graph refresh; weekly ETL rebuilds graph) |

### Data ETL (Weekly) — `data-etl-weekly.yml`

| | |
|--|--|
| **Schedule** | Sunday 05:00 UTC (08:00 Istanbul) |
| **Manual** | Actions → Data ETL (Weekly) → Run workflow |
| **Script** | `./scripts/run_scheduled_etl.sh` |
| **Steps** | Kaggle fetch (if secrets set) or transform committed CSV → full load → patches |

### Career Enrichment (Weekly) — `career-enrichment-weekly.yml`

| | |
|--|--|
| **Schedule** | Saturday 04:00 UTC (07:00 Istanbul) |
| **Manual** | Actions → Career Enrichment (Weekly) → Run workflow |
| **Script** | `./scripts/run_career_enrichment.sh` |
| **Steps** | API-Football sync (all mapped teams) → reconcile stale stints → write `enriched_careers.csv` → apply patches + graph refresh |
| **Artifact** | `reports/career_gaps.csv` (players needing attention) |

Local run (no DB load):

```bash
cd data_pipeline && python -m pipeline career-enrich --skip-api-sync
```

Apply to Supabase after enrichment:

```bash
CAREER_ENRICH_LOAD=1 ./scripts/run_career_enrichment.sh
```

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
| Job cancelled after 45–90 min | Full dedupe + graph refresh on large DB | Daily job uses `PATCH_LOAD_LIGHT=1` (default); run weekly ETL for full rebuild |
| DB deadlock | Two syncs at once (local + Actions) | Run only one sync at a time |
| API quota exceeded | >100 requests/day | Wait 24h; cache reduces repeat calls |
| Daily puzzle unchanged | `ensure_daily_puzzle` already ran today | Expected — one puzzle per UTC date |
