"""Curated career patches for gaps in stale SoFIFA/Kaggle snapshots.

Patches are merged after Kaggle transform. Same player+club+start_date+is_loan
keys are overwritten; new stints are appended. All entries are free/manual curation.
"""

from __future__ import annotations

import csv
from pathlib import Path

from .club_metadata import canonical_club_name

PATCH_FIELDS = (
    'id', 'name', 'team', 'nationality', 'position',
    'start_date', 'end_date', 'is_loan', 'appearances', 'source',
)

DEFAULT_PATCHES_PATH = Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'patches' / 'career_patches.csv'
API_FOOTBALL_PATCHES_PATH = (
    Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'patches' / 'api_football_careers.csv'
)
ENRICHED_PATCHES_PATH = (
    Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'patches' / 'enriched_careers.csv'
)


def load_career_patches(path: Path | None = None) -> list[dict]:
    patch_path = path or DEFAULT_PATCHES_PATH
    if not patch_path.is_file():
        return []

    with patch_path.open(newline='', encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    patches: list[dict] = []
    for row in rows:
        player_id = str(row.get('id', '')).strip()
        name = str(row.get('name', '')).strip()
        team = canonical_club_name(str(row.get('team', '')).strip())
        if not player_id or not name or not team:
            continue
        patches.append({
            'id': player_id,
            'name': name,
            'team': team,
            'nationality': (row.get('nationality') or '').strip(),
            'position': (row.get('position') or '').strip(),
            'start_date': (row.get('start_date') or '').strip(),
            'end_date': (row.get('end_date') or '').strip(),
            'is_loan': str(row.get('is_loan', 'false')).lower(),
            'appearances': int(row.get('appearances') or 1),
            'source': (row.get('source') or 'manual_patch').strip(),
        })
    return patches


def _patch_key(row: dict) -> tuple[str, str, str, str]:
    return (
        str(row['id']),
        canonical_club_name(str(row['team'])),
        str(row.get('start_date') or ''),
        str(row.get('is_loan', 'false')).lower(),
    )


def load_all_career_patches(
    manual_path: Path | None = None,
    api_football_path: Path | None = None,
    enriched_path: Path | None = None,
    *,
    include_enriched: bool = True,
) -> list[dict]:
    """Load manual, API-Football, and optionally reconciled enrichment deltas."""
    combined: list[dict] = []
    combined.extend(load_career_patches(manual_path or DEFAULT_PATCHES_PATH))
    api_path = api_football_path or API_FOOTBALL_PATCHES_PATH
    combined.extend(load_career_patches(api_path))
    if include_enriched:
        enriched = enriched_path or ENRICHED_PATCHES_PATH
        combined.extend(load_career_patches(enriched))
    return combined


def merge_all_patches_into_rows(player_rows: list[dict]) -> tuple[list[dict], int]:
    patches = load_all_career_patches()
    return merge_career_patches(player_rows, patches)


def merge_career_patches(
    player_rows: list[dict],
    patches: list[dict],
) -> tuple[list[dict], int]:
    """Merge patch rows into pipeline player rows. Returns (merged, patch_count)."""
    if not patches:
        return player_rows, 0

    merged: dict[tuple[str, str, str, str], dict] = {}
    for row in player_rows:
        merged[_patch_key(row)] = dict(row)

    applied = 0
    for patch in patches:
        key = _patch_key(patch)
        base = merged.get(key, {})
        merged[key] = {
            'id': patch['id'],
            'name': patch['name'],
            'team': patch['team'],
            'nationality': patch.get('nationality') or base.get('nationality', ''),
            'position': patch.get('position') or base.get('position', ''),
            'start_date': patch.get('start_date') or base.get('start_date', ''),
            'end_date': patch.get('end_date') or base.get('end_date', ''),
            'is_loan': patch.get('is_loan', 'false'),
            'appearances': patch.get('appearances', base.get('appearances', 1)),
            'source': patch.get('source', 'manual_patch'),
        }
        applied += 1

    return list(merged.values()), applied
