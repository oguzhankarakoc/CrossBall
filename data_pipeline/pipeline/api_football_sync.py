"""Sync career stints from API-Football transfers into pipeline patch format."""

from __future__ import annotations

import csv
import json
import os
from pathlib import Path

from .api_football_client import (
    ApiFootballClient,
    ApiFootballError,
    is_auth_error,
    is_quota_error,
)
from .club_metadata import canonical_club_name
from .kaggle_transform import MIN_CAREER_YEAR, TOP_CLUB_NAMES
from .normalize import normalize_name
from .player_aliases import build_player_lookup_rows, load_player_aliases, resolve_external_id
from .player_identity import player_identity_key, pick_preferred_name

TEAM_IDS_PATH = Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'api_football' / 'team_ids.json'
DEFAULT_OUTPUT = Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'patches' / 'api_football_careers.csv'

TOP_CLUB_SET = {canonical_club_name(c) for c in TOP_CLUB_NAMES}
CAREER_CSV_FIELDS = (
    'id', 'name', 'team', 'nationality', 'position',
    'start_date', 'end_date', 'is_loan', 'appearances', 'source',
)


class ApiFootballSyncError(RuntimeError):
    """Raised when API sync fails completely and no usable fallback exists."""


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


def load_career_csv(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    with path.open(newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))


def _empty_stats(teams_requested: int) -> dict[str, int | None]:
    return {
        'teams_requested': teams_requested,
        'teams_ok': 0,
        'teams_failed': 0,
        'teams_empty': 0,
        'teams_skipped_quota': 0,
        'players_seen': 0,
        'players_unresolved': 0,
        'career_rows': 0,
        'api_requests': 0,
        'cache_hits': 0,
        'remaining_daily': None,
    }


def _resolve_min_remaining(explicit: int | None) -> int | None:
    if explicit is not None:
        return explicit
    raw = os.environ.get('API_FOOTBALL_MIN_REMAINING', '').strip()
    if not raw:
        return None
    try:
        return int(raw)
    except ValueError:
        return None


def sync_transfers_to_career_rows(
    *,
    team_map: dict[str, int] | None = None,
    client: ApiFootballClient | None = None,
    offset: int = 0,
    limit: int | None = 30,
    use_cache: bool = True,
    cache_only: bool = False,
    min_remaining: int | None = None,
    players_csv: Path | None = None,
) -> tuple[list[dict], dict[str, int | None]]:
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

    stats = _empty_stats(len(items))
    min_remaining = _resolve_min_remaining(min_remaining)
    allow_live = not cache_only
    sample_errors: list[str] = []

    if allow_live and min_remaining is not None:
        try:
            client.fetch_status(use_cache=False)
        except ApiFootballError as exc:
            print(f'  API-Football status check failed: {exc}', flush=True)
        else:
            remaining = client.remaining_daily
            print(f'  API-Football quota check: remaining={remaining}', flush=True)
            if remaining is not None and remaining < min_remaining:
                print(
                    f'  Switching to cache-only mode '
                    f'(remaining={remaining} < required={min_remaining})',
                    flush=True,
                )
                allow_live = False

    career_rows: dict[tuple, dict] = {}

    for idx, (club_name, team_id) in enumerate(items, start=1):
        if not allow_live and client.quota_exhausted:
            stats['teams_skipped_quota'] = int(stats['teams_skipped_quota']) + 1
            continue

        print(f'  API team {idx}/{len(items)}: {club_name} (id={team_id})', flush=True)
        before_requests = client.requests_made
        try:
            response_items = client.transfers_for_team(
                team_id,
                use_cache=use_cache,
                allow_live=allow_live,
            )
        except ApiFootballError as exc:
            stats['teams_failed'] = int(stats['teams_failed']) + 1
            stats['api_requests'] = int(stats['api_requests']) + (client.requests_made - before_requests)
            message = f'{club_name} (id={team_id}): {exc}'
            if len(sample_errors) < 5:
                sample_errors.append(message)
            print(f'  API team failed: {message}', flush=True)
            if is_auth_error(exc):
                raise ApiFootballSyncError(
                    f'API-Football authentication failed — check API_FOOTBALL_KEY. {exc}'
                ) from exc
            if is_quota_error(exc) or client.quota_exhausted:
                allow_live = False
                remaining = len(items) - idx
                stats['teams_skipped_quota'] = int(stats['teams_skipped_quota']) + remaining
                print(
                    '  API-Football daily quota exhausted; '
                    'remaining teams will use cache-only or be skipped.',
                    flush=True,
                )
                break
            continue
        else:
            stats['api_requests'] = int(stats['api_requests']) + (client.requests_made - before_requests)
            if not response_items:
                stats['teams_empty'] = int(stats['teams_empty']) + 1
            else:
                stats['teams_ok'] = int(stats['teams_ok']) + 1

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
                stats['players_unresolved'] = int(stats['players_unresolved']) + 1
                continue

            display_name = preferred_names.get(ext_id, player_name)
            preferred_names[ext_id] = pick_preferred_name(display_name, player_name)

            stints = build_stints_from_player_transfers(
                item.get('transfers') or [],
                af_team_id_to_name=af_id_to_name,
            )

            for stint in stints:
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

    print(
        '  API sync summary: '
        f"ok={stats['teams_ok']} failed={stats['teams_failed']} "
        f"empty={stats['teams_empty']} skipped_quota={stats['teams_skipped_quota']} "
        f"players={stats['players_seen']} unresolved={stats['players_unresolved']} "
        f"career_rows={stats['career_rows']} api_requests={stats['api_requests']} "
        f"cache_hits={stats['cache_hits']} remaining={stats['remaining_daily']}",
        flush=True,
    )
    if sample_errors:
        print('  API sample errors:', flush=True)
        for message in sample_errors:
            print(f'    - {message}', flush=True)

    return list(career_rows.values()), stats


def write_career_csv(
    rows: list[dict],
    output_path: Path,
    *,
    preserve_existing: bool = False,
) -> bool:
    """Write career patch CSV. Returns False when an existing file was preserved."""
    if preserve_existing and not rows and output_path.is_file():
        existing = load_career_csv(output_path)
        if existing:
            print(
                f'  Preserving existing API patch CSV ({len(existing)} rows) at {output_path}',
                flush=True,
            )
            return False

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open('w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=CAREER_CSV_FIELDS)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k, '') for k in CAREER_CSV_FIELDS})
    return True
