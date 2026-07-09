"""Sync career stints from API-Football transfers into pipeline patch format."""

from __future__ import annotations

import csv
import json
from pathlib import Path

from .api_football_client import ApiFootballClient, ApiFootballError
from .club_metadata import canonical_club_name
from .kaggle_transform import MIN_CAREER_YEAR, TOP_CLUB_NAMES
from .normalize import normalize_name
from .player_aliases import build_player_lookup_rows, load_player_aliases, resolve_external_id
from .player_identity import player_identity_key, pick_preferred_name

TEAM_IDS_PATH = Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'api_football' / 'team_ids.json'
DEFAULT_OUTPUT = Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'patches' / 'api_football_careers.csv'

TOP_CLUB_SET = {canonical_club_name(c) for c in TOP_CLUB_NAMES}


def load_team_id_map(path: Path | None = None) -> dict[str, int]:
    data = json.loads((path or TEAM_IDS_PATH).read_text(encoding='utf-8'))
    return {canonical_club_name(name): int(team_id) for name, team_id in data.items()}


def _is_loan(transfer_type: str | None) -> bool:
    return 'loan' in (transfer_type or '').lower()


def _parse_date(value: str | None) -> str | None:
    if not value:
        return None
    text = str(value).strip()[:10]
    if len(text) == 10 and text[4] == '-':
        return text
    return None


def _year(value: str | None) -> int | None:
    parsed = _parse_date(value)
    if not parsed:
        return None
    return int(parsed[:4])


def build_stints_from_player_transfers(
    transfers: list[dict],
    *,
    af_team_id_to_name: dict[int, str],
) -> list[dict]:
    """Turn one player's chronological transfers into top-club career stints."""
    open_stints: dict[str, dict] = {}

    sorted_tx = sorted(
        transfers,
        key=lambda t: _parse_date(t.get('date')) or '9999-12-31',
    )

    for tx in sorted_tx:
        date = _parse_date(tx.get('date'))
        if not date:
            continue
        year = _year(date)
        if year is not None and year < MIN_CAREER_YEAR:
            continue

        teams = tx.get('teams') or {}
        team_out = teams.get('out') or {}
        team_in = teams.get('in') or {}
        out_id = team_out.get('id')
        in_id = team_in.get('id')
        is_loan = _is_loan(tx.get('type'))

        if out_id in af_team_id_to_name:
            club_out = af_team_id_to_name[out_id]
            if club_out in TOP_CLUB_SET and club_out in open_stints:
                open_stints[club_out]['end_date'] = date

        if in_id in af_team_id_to_name:
            club_in = af_team_id_to_name[in_id]
            if club_in in TOP_CLUB_SET:
                open_stints[club_in] = {
                    'team': club_in,
                    'start_date': date,
                    'end_date': '',
                    'is_loan': 'true' if is_loan else 'false',
                }

    return list(open_stints.values())


def _load_player_lookups(
    players_csv: Path | None,
) -> tuple[dict[str, str], dict[str, str]]:
    if not players_csv or not players_csv.is_file():
        return {}, {}
    by_name: dict[str, str] = {}
    by_identity: dict[str, str] = {}
    with players_csv.open(newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            ext_id = str(row.get('id', '')).strip()
            name = str(row.get('name', '')).strip()
            if not ext_id or not name:
                continue
            by_name[normalize_name(name)] = ext_id
            by_identity[player_identity_key(name)] = ext_id
    return by_name, by_identity


def sync_transfers_to_career_rows(
    *,
    team_map: dict[str, int] | None = None,
    client: ApiFootballClient | None = None,
    offset: int = 0,
    limit: int | None = 30,
    use_cache: bool = True,
    players_csv: Path | None = None,
) -> tuple[list[dict], dict[str, int]]:
    """Fetch transfers for mapped teams and return career patch rows + stats."""
    team_map = team_map or load_team_id_map()
    client = client or ApiFootballClient()

    af_id_to_name = {v: k for k, v in team_map.items()}
    name_to_external, identity_to_external = _load_player_lookups(players_csv)
    roster_rows = build_player_lookup_rows(players_csv) if players_csv else []
    alias_map = load_player_aliases()
    preferred_names: dict[str, str] = {}

    items = list(team_map.items())
    if offset:
        items = items[offset:]
    if limit is not None:
        items = items[:limit]

    career_rows: dict[tuple, dict] = {}
    stats: dict[str, int | None] = {
        'teams_requested': len(items),
        'players_seen': 0,
        'career_rows': 0,
        'api_requests': 0,
        'cache_hits': 0,
        'remaining_daily': None,
    }

    for idx, (club_name, team_id) in enumerate(items, start=1):
        print(f'  API team {idx}/{len(items)}: {club_name} (id={team_id})', flush=True)
        before = client.requests_made
        try:
            response_items = client.transfers_for_team(team_id, use_cache=use_cache)
        except ApiFootballError:
            continue
        stats['api_requests'] = int(stats['api_requests']) + (client.requests_made - before)

        for item in response_items:
            player = item.get('player') or {}
            player_name = str(player.get('name', '')).strip()
            af_player_id = player.get('id')
            if not player_name:
                continue

            stats['players_seen'] = int(stats['players_seen']) + 1
            ext_id = resolve_external_id(
                player_name,
                api_football_player_id=af_player_id,
                name_to_external=name_to_external,
                identity_to_external=identity_to_external,
                alias_map=alias_map,
                roster_rows=roster_rows,
            )
            if not ext_id:
                continue
            if ext_id.startswith('af-'):
                continue

            display_name = preferred_names.get(ext_id, player_name)
            preferred_names[ext_id] = pick_preferred_name(display_name, player_name)

            stints = build_stints_from_player_transfers(
                item.get('transfers') or [],
                af_team_id_to_name=af_id_to_name,
            )

            for stint in stints:
                if not ext_id:
                    continue
                key = (ext_id, stint['team'], stint['start_date'], stint['is_loan'])
                career_rows[key] = {
                    'id': ext_id,
                    'name': preferred_names[ext_id],
                    'team': stint['team'],
                    'nationality': '',
                    'position': '',
                    'start_date': stint['start_date'],
                    'end_date': stint['end_date'],
                    'is_loan': stint['is_loan'],
                    'appearances': 1,
                    'source': f'api_football_team_{team_id}',
                }

    stats['cache_hits'] = client.requests_from_cache
    stats['career_rows'] = len(career_rows)
    stats['remaining_daily'] = client.remaining_daily
    return list(career_rows.values()), stats  # type: ignore[return-value]


def write_career_csv(rows: list[dict], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        'id', 'name', 'team', 'nationality', 'position',
        'start_date', 'end_date', 'is_loan', 'appearances', 'source',
    ]
    with output_path.open('w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k, '') for k in fieldnames})
