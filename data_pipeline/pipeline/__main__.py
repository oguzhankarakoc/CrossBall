"""CLI entry point for CrossBall data pipeline."""

import argparse
import csv
import uuid
from pathlib import Path

from .load import compute_content_hash, get_connection, upsert_clubs, upsert_players
from .normalize import is_youth_or_reserve, normalize_name, slugify
from .validate import validate_players


def ingest_csv(path: Path) -> list[dict]:
    with path.open(newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))


def normalize_raw(raw_players: list[dict], club_slug_map: dict[str, str]) -> list[dict]:
    players = []
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

        existing = next((p for p in players if p['external_id'] == player_id), None)
        career = {
            'club_id': club_id,
            'start_date': row.get('start_date') or None,
            'end_date': row.get('end_date') or None,
            'is_loan': row.get('is_loan', '').lower() == 'true',
            'is_senior': True,
            'appearances': int(row.get('appearances', 0) or 0),
        }

        if existing:
            existing['careers'].append(career)
        else:
            players.append({
                'id': str(uuid.uuid4()),
                'external_id': player_id,
                'name': name,
                'normalized_name': normalize_name(name),
                'nationality_code': row.get('nationality', '')[:2] or None,
                'primary_position': row.get('position'),
                'careers': [career],
            })

    return players


def normalize_clubs(raw_clubs: list[dict]) -> list[dict]:
    clubs = []
    for row in raw_clubs:
        slug = slugify(row['name'])
        clubs.append({
            'id': str(uuid.uuid4()),
            'name': row['name'],
            'slug': slug,
            'country_code': row.get('country_code', '')[:2] or None,
            'is_top_club': row.get('is_top_club', 'true').lower() == 'true',
        })
    return clubs


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

    conn = get_connection()
    try:
        upsert_clubs(conn, clubs)
        upsert_players(conn, players)
        print('  Load complete.')
    finally:
        conn.close()


def main():
    parser = argparse.ArgumentParser(description='CrossBall data pipeline')
    sub = parser.add_subparsers(dest='command')

    run_parser = sub.add_parser('run', help='Run full pipeline')
    run_parser.add_argument('--input', required=True, type=Path)
    run_parser.add_argument('--clubs', required=True, type=Path)

    args = parser.parse_args()
    if args.command == 'run':
        run_pipeline(args.input, args.clubs)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
