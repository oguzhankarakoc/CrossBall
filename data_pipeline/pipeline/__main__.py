"""CLI entry point for CrossBall data pipeline."""

import argparse
import csv
import os
import uuid
from pathlib import Path
from typing import Optional

from .api_football_client import ApiFootballClient, ApiFootballError
from .api_football_sync import (
    DEFAULT_OUTPUT as API_FOOTBALL_OUTPUT,
    ApiFootballSyncError,
    sync_transfers_to_career_rows,
    write_career_csv,
)
from .career_enrichment import run_career_enrichment
from .career_gap_report import detect_career_gaps, write_gap_report
from .career_patches import (
    DEFAULT_PATCHES_PATH,
    ENRICHED_PATCHES_PATH,
    load_all_career_patches,
    load_career_patches,
)
from .fetch_kaggle import fetch_kaggle_dataset
from .kaggle_transform import transform_kaggle_files, write_pipeline_csv
from .load import (
    compute_content_hash,
    dedupe_players,
    get_connection,
    refresh_club_relationships,
    refresh_intersections,
    remap_career_club_ids,
    upsert_clubs,
    upsert_players,
)
from .club_metadata import LEGACY_CLUB_SLUGS, canonical_club_name
from .normalize import is_youth_or_reserve, normalize_name, slugify
from .player_identity import player_identity_key
from .validate import validate_players


def ingest_csv(path: Path) -> list[dict]:
    with path.open(newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))


def normalize_clubs(raw_clubs: list[dict]) -> list[dict]:
    clubs = []
    for row in raw_clubs:
        slug = LEGACY_CLUB_SLUGS.get(row['name'], slugify(row['name']))
        clubs.append({
            'id': str(uuid.uuid4()),
            'name': row['name'],
            'slug': slug,
            'country_code': (row.get('country_code') or '')[:2] or None,
            'is_top_club': str(row.get('is_top_club', 'true')).lower() == 'true',
            'badge_primary_color': row.get('badge_primary_color') or None,
            'badge_secondary_color': row.get('badge_secondary_color') or None,
            'badge_initials': row.get('badge_initials') or None,
            'badge_gradient_style': row.get('badge_gradient_style') or 'vertical',
            'short_name': row.get('short_name') or None,
        })
    return clubs


def normalize_raw(raw_players: list[dict], club_slug_map: dict[str, str]) -> list[dict]:
    players: list[dict] = []
    players_by_external_id: dict[str, dict] = {}

    for row in raw_players:
        team = row.get('team', '')
        if is_youth_or_reserve(team):
            continue

        team_canonical = canonical_club_name(team)
        club_slug = LEGACY_CLUB_SLUGS.get(team_canonical, slugify(team_canonical))
        club_id = club_slug_map.get(club_slug)
        if not club_id:
            continue

        name = row['name']
        player_id = row.get('id') or str(uuid.uuid5(uuid.NAMESPACE_DNS, name))

        career = {
            'club_id': club_id,
            'start_date': row.get('start_date') or None,
            'end_date': row.get('end_date') or None,
            'is_loan': str(row.get('is_loan', '')).lower() == 'true',
            'is_senior': True,
            'appearances': int(row.get('appearances', 0) or 0),
            'source': row.get('source') or 'kaggle_sofifa',
        }

        existing = players_by_external_id.get(player_id)
        if existing:
            existing['careers'].append(career)
        else:
            player = {
                'id': str(uuid.uuid4()),
                'external_id': player_id,
                'name': name,
                'normalized_name': normalize_name(name),
                'identity_key': player_identity_key(name),
                'nationality_code': (row.get('nationality') or '')[:2] or None,
                'primary_position': row.get('position') or None,
                'careers': [career],
            }
            players_by_external_id[player_id] = player
            players.append(player)

    return players


def run_pipeline(input_path: Path, clubs_path: Path) -> None:
    print('CrossBall Pipeline v1.0.0')
    print(f'  Input:  {input_path}')
    print(f'  Clubs:  {clubs_path}')

    raw_clubs = ingest_csv(clubs_path)
    clubs = normalize_clubs(raw_clubs)
    club_slug_map = {c['slug']: c['id'] for c in clubs}

    raw_players = ingest_csv(input_path)
    players = normalize_raw(raw_players, club_slug_map)

    result = validate_players(players, clubs)
    if result.warnings:
        print(f'  Warnings: {len(result.warnings)}')
        for w in result.warnings[:5]:
            print(f'    - {w}')

    if not result.valid:
        print(f'  ERRORS: {len(result.errors)}')
        for e in result.errors[:10]:
            print(f'    - {e}')
        raise SystemExit(1)

    content_hash = compute_content_hash({'clubs': clubs, 'players': players})
    print(f'  Content hash: {content_hash}')
    print(f'  Clubs:   {len(clubs)}')
    print(f'  Players: {len(players)}')
    print(f'  Career rows: {sum(len(p.get("careers", [])) for p in players)}')

    conn = get_connection()
    try:
        slug_to_id = upsert_clubs(conn, clubs)
        remap_career_club_ids(players, clubs, slug_to_id)
        upsert_players(conn, players)
        merged = dedupe_players(conn)
        if merged:
            print(f'  Merged {merged} duplicate player record(s).')
        refresh_intersections(conn)
        refresh_club_relationships(conn)
        print('  Load complete.')
    finally:
        conn.close()


def cmd_fetch_kaggle(output: Path) -> None:
    fetch_kaggle_dataset(output)


def cmd_transform_kaggle(input_path: Path, players_out: Path, clubs_out: Path) -> None:
    print(f'  Transforming Kaggle/SoFIFA data from {input_path}')
    players, clubs = transform_kaggle_files(input_path)
    if not players:
        raise SystemExit(
            '  Transform produced 0 career rows. '
            'Ensure CSV has club_name + joined columns (SoFIFA / FIFA 23 legacy format).'
        )
    write_pipeline_csv(players, clubs, players_out, clubs_out)
    print(f'  Wrote {len(players)} career rows, {len(clubs)} clubs')
    print(f'  Output: {players_out}, {clubs_out}')


def _patch_load_light() -> bool:
    return os.environ.get('PATCH_LOAD_LIGHT', '').strip().lower() in ('1', 'true', 'yes')


def cmd_apply_patches(
    patches_path: Path,
    clubs_path: Path,
    *,
    light: Optional[bool] = None,
    enriched_only: bool = False,
) -> None:
    """Apply curated career patches to PostgreSQL without a full Kaggle re-download."""
    light = _patch_load_light() if light is None else light
    include_enriched = not light
    if enriched_only:
        mode = 'enriched deltas only (weekly reconcile output)'
        patches = load_career_patches(ENRICHED_PATCHES_PATH)
    elif light:
        mode = 'light (manual + API-Football; refresh club graph; skip enriched + dedupe)'
        patches = load_all_career_patches(
            manual_path=patches_path,
            include_enriched=False,
        )
    else:
        mode = 'full (manual + API-Football + enriched)'
        patches = load_all_career_patches(
            manual_path=patches_path,
            include_enriched=include_enriched,
        )
    print(f'  Applying career patches — {mode}')
    if not patches:
        source = ENRICHED_PATCHES_PATH if enriched_only else patches_path
        raise SystemExit(f'No patches found at {source}')

    raw_clubs = ingest_csv(clubs_path)
    clubs = normalize_clubs(raw_clubs)
    club_slug_map = {c['slug']: c['id'] for c in clubs}
    players = normalize_raw(patches, club_slug_map)

    if not players:
        raise SystemExit('No patch rows matched known clubs — check club names in patches CSV')

    print(f'  Patch players: {len(players)}')
    print(f'  Patch career rows: {sum(len(p.get("careers", [])) for p in players)}')

    conn = get_connection()
    try:
        slug_to_id = upsert_clubs(conn, clubs)
        print(f'  Upserted {len(slug_to_id)} clubs', flush=True)
        remap_career_club_ids(players, clubs, slug_to_id)
        print(f'  Upserting {len(players)} players...', flush=True)
        upsert_players(conn, players)
        if light:
            refresh_intersections(conn)
            refresh_club_relationships(conn)
            print('  Skipped dedupe; refreshed intersections + club graph for daily puzzles.')
        else:
            merged = dedupe_players(conn)
            if merged:
                print(f'  Merged {merged} duplicate player record(s).')
            refresh_intersections(conn)
            refresh_club_relationships(conn)
        print('  Patch load complete.')
    finally:
        conn.close()


def cmd_sync_api_football(
    *,
    offset: int,
    limit: int,
    output: Path,
    players_csv: Path,
    load_db: bool,
    clubs_path: Path,
    no_cache: bool,
    cache_only: bool,
) -> None:
    print('  Syncing transfers from API-Football (free tier: 100 req/day)')
    try:
        rows, stats = sync_transfers_to_career_rows(
            offset=offset,
            limit=limit,
            use_cache=not no_cache,
            cache_only=cache_only,
            min_remaining=limit,
            players_csv=players_csv,
        )
    except ApiFootballSyncError as exc:
        raise SystemExit(str(exc)) from exc
    except ApiFootballError as exc:
        raise SystemExit(str(exc)) from exc

    write_career_csv(rows, output, preserve_existing=False)
    print(f'  Wrote {len(rows)} career rows → {output}')
    print(
        '  Stats: '
        f"teams={stats['teams_requested']} ok={stats.get('teams_ok', 0)} "
        f"failed={stats.get('teams_failed', 0)} empty={stats.get('teams_empty', 0)} "
        f"players={stats['players_seen']} unresolved={stats.get('players_unresolved', 0)} "
        f"api_requests={stats['api_requests']} cache_hits={stats['cache_hits']} "
        f"remaining_today={stats['remaining_daily']}"
    )

    if (
        not rows
        and int(stats.get('teams_ok', 0) or 0) == 0
        and int(stats.get('cache_hits', 0) or 0) == 0
    ):
        raise SystemExit(
            'API-Football sync produced no career rows. '
            'Likely causes: daily quota exhausted, invalid API key, or network failure. '
            'Check logs above for per-team errors.'
        )

    if load_db:
        cmd_apply_patches(DEFAULT_PATCHES_PATH, clubs_path, light=False)


def cmd_api_football_status() -> None:
    try:
        client = ApiFootballClient()
        status = client.fetch_status(use_cache=False)
    except ApiFootballError as exc:
        raise SystemExit(str(exc)) from exc

    requests_info = status.get('requests') or {}
    subscription = status.get('subscription') or {}
    current = int(requests_info.get('current') or 0)
    limit_day = int(requests_info.get('limit_day') or 0)
    remaining = client.remaining_daily
    if remaining is None and limit_day:
        remaining = max(limit_day - current, 0)

    print('  API-Football status OK')
    print(f'  plan={subscription.get("plan")} active={subscription.get("active")}')
    print(f'  requests_today={current}/{limit_day} remaining={remaining}')


def cmd_daily_rollout_fail() -> None:
    """Mark today's rollout as failed (CI recovery / timeout handler)."""
    message = os.environ.get('ROLLOUT_FAIL_MESSAGE', 'Scheduled sync failed or timed out')[:500]
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT public.fail_daily_puzzle_rollout(CURRENT_DATE, %s, %s)",
                (message, 'pipeline'),
            )
            row = cur.fetchone()
        conn.commit()
        print(f'  Daily rollout marked failed: {row[0] if row else "ok"}')
    finally:
        conn.close()


def cmd_daily_sync_gate() -> None:
    """Print SKIP when today's sync already succeeded; otherwise PROCEED."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT status FROM public.daily_puzzle_rollout
                WHERE puzzle_date = CURRENT_DATE
                """
            )
            rollout = cur.fetchone()
            if rollout and rollout[0] == 'ready':
                print('SKIP')
                return

            cur.execute(
                """
                SELECT 1 FROM public.puzzles
                WHERE puzzle_date = CURRENT_DATE
                  AND mode = 'daily'
                  AND grid_size = 3
                  AND is_published = TRUE
                LIMIT 1
                """
            )
            if cur.fetchone():
                print('SKIP')
                return
    finally:
        conn.close()
    print('PROCEED')


def cmd_daily_rollout_begin() -> None:
    """Mark today's daily puzzle as generating (called at UTC midnight before long sync)."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT public.begin_daily_puzzle_rollout(CURRENT_DATE, %s)", ('pipeline',))
            row = cur.fetchone()
        conn.commit()
        print(f'  Daily rollout started: {row[0] if row else "ok"}')
    finally:
        conn.close()


def cmd_ensure_daily() -> None:
    """Ensure today's global daily puzzle exists (after data refresh)."""
    tier = os.environ.get('ENSURE_DAILY_TIER', 'hard').strip() or 'hard'
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id FROM puzzles
                WHERE puzzle_date = CURRENT_DATE
                  AND mode = 'daily'
                  AND grid_size = 3
                  AND is_published = TRUE
                LIMIT 1
                """
            )
            existing = cur.fetchone()
            if existing:
                cur.execute(
                    "SELECT public.complete_daily_puzzle_rollout(CURRENT_DATE, %s, %s)",
                    (existing[0], 'pipeline'),
                )
                conn.commit()
                print(f'  Daily puzzle already exists: {existing[0]} (marked ready)')
                return

            cur.execute(
                "SELECT status FROM public.daily_puzzle_rollout WHERE puzzle_date = CURRENT_DATE"
            )
            rollout = cur.fetchone()
            if rollout is None or rollout[0] != 'generating':
                cur.execute(
                    "SELECT public.begin_daily_puzzle_rollout(CURRENT_DATE, %s)",
                    ('pipeline',),
                )

            print('  Refreshing club graph for puzzle generation...')
            refresh_intersections(conn)
            refresh_club_relationships(conn)
            cur.execute('SELECT COUNT(*) FROM club_relationships')
            rel_count = cur.fetchone()[0]
            print(f'  club_relationships pairs: {rel_count}')
            if rel_count < 50:
                raise SystemExit(
                    f'club_relationships too sparse ({rel_count} pairs) after graph refresh'
                )

            print(f'  Generating daily puzzle (tier={tier})...')
            try:
                cur.execute("SELECT public.ensure_daily_puzzle(CURRENT_DATE, %s)", (tier,))
                puzzle_id = cur.fetchone()[0]
                cur.execute(
                    "SELECT public.complete_daily_puzzle_rollout(CURRENT_DATE, %s, %s)",
                    (puzzle_id, 'pipeline'),
                )
            except Exception as exc:
                conn.rollback()
                with conn.cursor() as fail_cur:
                    fail_cur.execute(
                        "SELECT public.fail_daily_puzzle_rollout(CURRENT_DATE, %s, %s)",
                        (str(exc)[:500], 'pipeline'),
                    )
                conn.commit()
                raise
        conn.commit()
        print(f'  Daily puzzle ready: {puzzle_id}')
    finally:
        conn.close()


def cmd_run_all(kaggle_dir: Path, raw_dir: Path) -> None:
    """Fetch (if possible) → transform → load."""
    players_csv = raw_dir / 'players.csv'
    clubs_csv = raw_dir / 'clubs.csv'
    kaggle_input = kaggle_dir

    try:
        cmd_fetch_kaggle(kaggle_dir)
    except RuntimeError as e:
        print(f'  fetch-kaggle skipped: {e}')
        if not list(kaggle_dir.glob('**/*.csv')):
            print('  Place SoFIFA CSV files in data/raw/kaggle/ and retry.')
            raise SystemExit(1) from e

    cmd_transform_kaggle(kaggle_input, players_csv, clubs_csv)
    run_pipeline(players_csv, clubs_csv)


def cmd_refresh_intersections() -> None:
    conn = get_connection()
    try:
        refresh_intersections(conn)
        refresh_club_relationships(conn)
    finally:
        conn.close()


def cmd_dedupe_players() -> None:
    """Merge duplicate player rows (same identity_key) and refresh graph views."""
    conn = get_connection()
    try:
        merged = dedupe_players(conn)
        print(f'  Merged {merged} duplicate player record(s).')
        refresh_intersections(conn)
        refresh_club_relationships(conn)
    finally:
        conn.close()


def main():
    parser = argparse.ArgumentParser(description='CrossBall data pipeline')
    sub = parser.add_subparsers(dest='command')

    run_parser = sub.add_parser('run', help='Run full pipeline (load to PostgreSQL)')
    run_parser.add_argument('--input', required=True, type=Path)
    run_parser.add_argument('--clubs', required=True, type=Path)

    fetch_parser = sub.add_parser('fetch-kaggle', help='Download Kaggle dataset (needs API token)')
    fetch_parser.add_argument(
        '--output',
        type=Path,
        default=Path('data/raw/kaggle'),
    )

    transform_parser = sub.add_parser('transform-kaggle', help='Transform SoFIFA CSV → pipeline format')
    transform_parser.add_argument('--input', required=True, type=Path, help='CSV file or directory')
    transform_parser.add_argument(
        '--players-out',
        type=Path,
        default=Path('data/raw/players.csv'),
    )
    transform_parser.add_argument(
        '--clubs-out',
        type=Path,
        default=Path('data/raw/clubs.csv'),
    )

    run_all_parser = sub.add_parser('run-all', help='Fetch + transform + load (full ETL)')
    run_all_parser.add_argument('--kaggle-dir', type=Path, default=Path('data/raw/kaggle'))
    run_all_parser.add_argument('--raw-dir', type=Path, default=Path('data/raw'))

    ingest_parser = sub.add_parser('ingest', help='Count rows in CSV')
    ingest_parser.add_argument('--input', required=True, type=Path)

    sub.add_parser('refresh-intersections', help='Refresh player_club_intersections view')
    sub.add_parser('dedupe-players', help='Merge duplicate players by identity_key')

    patch_parser = sub.add_parser(
        'apply-patches',
        help='Load curated career patches (loans/transfers) without full Kaggle fetch',
    )
    patch_parser.add_argument(
        '--patches',
        type=Path,
        default=DEFAULT_PATCHES_PATH,
    )
    patch_parser.add_argument(
        '--clubs',
        type=Path,
        default=Path('data/raw/clubs.csv'),
    )
    patch_parser.add_argument(
        '--light',
        action='store_true',
        help='Daily sync: manual + API-Football only (skip enriched, dedupe, graph refresh)',
    )
    patch_parser.add_argument(
        '--enriched-only',
        action='store_true',
        help='Weekly enrichment: load reconciled enriched_careers.csv only (daily sync covers manual+API)',
    )

    af_parser = sub.add_parser(
        'sync-api-football',
        help='Fetch recent transfers from API-Football free API (100 req/day)',
    )
    af_parser.add_argument('--offset', type=int, default=0, help='Skip first N mapped teams')
    af_parser.add_argument('--limit', type=int, default=30, help='Max teams to fetch this run')
    af_parser.add_argument('--output', type=Path, default=API_FOOTBALL_OUTPUT)
    af_parser.add_argument('--players-csv', type=Path, default=Path('data/raw/players.csv'))
    af_parser.add_argument('--clubs', type=Path, default=Path('data/raw/clubs.csv'))
    af_parser.add_argument(
        '--load',
        action='store_true',
        help='After fetch, apply all patches to PostgreSQL',
    )
    af_parser.add_argument('--no-cache', action='store_true', help='Ignore cached API responses')
    af_parser.add_argument(
        '--cache-only',
        action='store_true',
        help='Never call live API; use on-disk cache and fail on cache miss',
    )

    sub.add_parser('api-football-status', help='Check API-Football key and daily request quota')

    sub.add_parser('daily-rollout-begin', help='Mark today\'s daily puzzle rollout as generating')
    sub.add_parser(
        'daily-rollout-fail',
        help='Mark today\'s daily puzzle rollout as failed (CI recovery)',
    )
    sub.add_parser(
        'daily-sync-gate',
        help='Print SKIP when today\'s sync is done, else PROCEED',
    )
    sub.add_parser('ensure-daily', help='Ensure today\'s global daily puzzle exists in PostgreSQL')

    gap_parser = sub.add_parser(
        'career-gap-report',
        help='Detect stale/missing career rows from base CSV + patch sources',
    )
    gap_parser.add_argument('--players-csv', type=Path, default=Path('data/raw/players.csv'))
    gap_parser.add_argument(
        '--output',
        type=Path,
        default=Path('../reports/career_gaps.csv'),
    )

    enrich_parser = sub.add_parser(
        'career-enrich',
        help='Sync API-Football, reconcile careers, write enriched patch deltas + gap report',
    )
    enrich_parser.add_argument('--players-csv', type=Path, default=Path('data/raw/players.csv'))
    enrich_parser.add_argument(
        '--output',
        type=Path,
        default=Path('data/raw/patches/enriched_careers.csv'),
    )
    enrich_parser.add_argument(
        '--gap-report',
        type=Path,
        default=Path('../reports/career_gaps.csv'),
    )
    enrich_parser.add_argument('--skip-api-sync', action='store_true')
    enrich_parser.add_argument('--api-offset', type=int, default=0)
    enrich_parser.add_argument('--api-limit', type=int, default=0, help='0 = all mapped teams')
    enrich_parser.add_argument('--no-cache', action='store_true')
    enrich_parser.add_argument(
        '--cache-only',
        action='store_true',
        help='Use cached API responses only (for low daily quota days)',
    )
    enrich_parser.add_argument(
        '--load',
        action='store_true',
        help='After enrichment, apply all patches to PostgreSQL',
    )
    enrich_parser.add_argument('--clubs', type=Path, default=Path('data/raw/clubs.csv'))

    args = parser.parse_args()

    if args.command == 'run':
        run_pipeline(args.input, args.clubs)
    elif args.command == 'fetch-kaggle':
        cmd_fetch_kaggle(args.output)
    elif args.command == 'transform-kaggle':
        cmd_transform_kaggle(args.input, args.players_out, args.clubs_out)
    elif args.command == 'run-all':
        cmd_run_all(args.kaggle_dir, args.raw_dir)
    elif args.command == 'ingest':
        rows = ingest_csv(args.input)
        print(f'Ingested {len(rows)} rows from {args.input}')
    elif args.command == 'refresh-intersections':
        cmd_refresh_intersections()
    elif args.command == 'dedupe-players':
        cmd_dedupe_players()
    elif args.command == 'apply-patches':
        cmd_apply_patches(
            args.patches,
            args.clubs,
            light=args.light or _patch_load_light(),
            enriched_only=args.enriched_only,
        )
    elif args.command == 'sync-api-football':
        cmd_sync_api_football(
            offset=args.offset,
            limit=args.limit,
            output=args.output,
            players_csv=args.players_csv,
            load_db=args.load,
            clubs_path=args.clubs,
            no_cache=args.no_cache,
            cache_only=args.cache_only,
        )
    elif args.command == 'api-football-status':
        cmd_api_football_status()
    elif args.command == 'daily-rollout-begin':
        cmd_daily_rollout_begin()
    elif args.command == 'daily-rollout-fail':
        cmd_daily_rollout_fail()
    elif args.command == 'daily-sync-gate':
        cmd_daily_sync_gate()
    elif args.command == 'ensure-daily':
        cmd_ensure_daily()
    elif args.command == 'career-gap-report':
        gaps = detect_career_gaps(players_csv=args.players_csv)
        write_gap_report(gaps, args.output)
        print(f'  Wrote {len(gaps)} gap(s) → {args.output}')
    elif args.command == 'career-enrich':
        api_limit = None if args.api_limit == 0 else args.api_limit
        summary = run_career_enrichment(
            players_csv=args.players_csv,
            enriched_output=args.output,
            gap_report_output=args.gap_report,
            skip_api_sync=args.skip_api_sync,
            api_offset=args.api_offset,
            api_limit=api_limit,
            use_cache=not args.no_cache,
            cache_only=args.cache_only,
        )
        for key, value in summary.items():
            print(f'  {key}: {value}')
        if args.load:
            cmd_apply_patches(
                DEFAULT_PATCHES_PATH,
                args.clubs,
                light=False,
                enriched_only=True,
            )
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
