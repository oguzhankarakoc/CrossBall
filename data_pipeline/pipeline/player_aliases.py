"""Map API-Football player ids/names to canonical SoFIFA external ids."""

from __future__ import annotations

import csv
from pathlib import Path

from .player_identity import names_likely_same_person

DEFAULT_ALIASES_PATH = (
    Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'patches' / 'player_id_aliases.csv'
)

ALIAS_FIELDS = ('external_id', 'api_football_player_id', 'api_name_hint', 'notes')


def load_player_aliases(path: Path | None = None) -> dict[str, str]:
    """Return api_football_player_id -> external_id (SoFIFA id string)."""
    alias_path = path or DEFAULT_ALIASES_PATH
    if not alias_path.is_file():
        return {}

    mapping: dict[str, str] = {}
    with alias_path.open(newline='', encoding='utf-8') as handle:
        for row in csv.DictReader(handle):
            external_id = str(row.get('external_id', '')).strip()
            api_id = str(row.get('api_football_player_id', '')).strip()
            if external_id and api_id:
                mapping[api_id] = external_id
    return mapping


def build_player_lookup_rows(players_csv: Path) -> list[dict[str, str]]:
    if not players_csv.is_file():
        return []

    rows: list[dict[str, str]] = []
    with players_csv.open(newline='', encoding='utf-8') as handle:
        for row in csv.DictReader(handle):
            player_id = str(row.get('id', '')).strip()
            name = str(row.get('name', '')).strip()
            if player_id and name:
                rows.append({'id': player_id, 'name': name})
    return rows


def resolve_external_id(
    player_name: str,
    *,
    api_football_player_id: int | str | None,
    name_to_external: dict[str, str],
    identity_to_external: dict[str, str],
    alias_map: dict[str, str],
    roster_rows: list[dict[str, str]] | None = None,
) -> str | None:
    from .normalize import normalize_name
    from .player_identity import player_identity_key

    normalized = normalize_name(player_name)
    if normalized in name_to_external:
        return name_to_external[normalized]

    identity = player_identity_key(player_name)
    if identity in identity_to_external:
        return identity_to_external[identity]

    if roster_rows:
        for row in roster_rows:
            if names_likely_same_person(row['name'], player_name):
                return row['id']

    if api_football_player_id is not None:
        api_key = str(api_football_player_id).strip()
        if api_key in alias_map:
            return alias_map[api_key]

    if api_football_player_id is not None:
        return f'af-{api_football_player_id}'
    return None
