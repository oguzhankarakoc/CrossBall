"""CLI entry point for CrossBall data pipeline."""

import argparse
import csv
import uuid
from pathlib import Path

from .fetch_kaggle import fetch_kaggle_dataset
from .kaggle_transform import transform_kaggle_files, write_pipeline_csv
from .load import (
    compute_content_hash,
    get_connection,
    refresh_intersections,
    remap_career_club_ids,
    upsert_clubs,
    upsert_players,
)
from .club_metadata import LEGACY_CLUB_SLUGS
from .normalize import is_youth_or_reserve, normalize_name, slugify
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

        club_slug = slugify(team)
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
        refresh_intersections(conn)
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
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
