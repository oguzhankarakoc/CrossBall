"""Detect stale or incomplete career data before enrichment."""

from __future__ import annotations

import csv
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

from .career_patches import load_all_career_patches
from .career_reconcile import is_open_ended, parse_career_date
from .club_metadata import canonical_club_name
from .player_identity import player_identity_key


@dataclass(frozen=True)
class CareerGap:
    external_id: str
    name: str
    issue_type: str
    details: str
    priority: int


def load_base_career_rows(players_csv: Path) -> list[dict]:
    if not players_csv.is_file():
        return []

    rows: list[dict] = []
    with players_csv.open(newline='', encoding='utf-8') as handle:
        for row in csv.DictReader(handle):
            player_id = str(row.get('id', '')).strip()
            name = str(row.get('name', '')).strip()
            team = canonical_club_name(str(row.get('team', '')).strip())
            if not player_id or not name or not team:
                continue
            rows.append(
                {
                    'id': player_id,
                    'name': name,
                    'team': team,
                    'nationality': (row.get('nationality') or '').strip(),
                    'position': (row.get('position') or '').strip(),
                    'start_date': (row.get('start_date') or '').strip(),
                    'end_date': (row.get('end_date') or '').strip(),
                    'is_loan': str(row.get('is_loan', 'false')).lower(),
                    'appearances': int(row.get('appearances') or 1),
                    'source': (row.get('source') or 'kaggle_sofifa').strip(),
                }
            )
    return rows


def detect_career_gaps(
    *,
    players_csv: Path,
    manual_patches_path: Path | None = None,
    api_patches_path: Path | None = None,
) -> list[CareerGap]:
    base_rows = load_base_career_rows(players_csv)
    patch_rows = load_all_career_patches(manual_patches_path, api_patches_path)

    by_player: dict[str, list[dict]] = defaultdict(list)
    names: dict[str, str] = {}
    for row in base_rows:
        by_player[row['id']].append(row)
        names[row['id']] = row['name']

    patch_by_player: dict[str, list[dict]] = defaultdict(list)
    identity_to_base_id: dict[str, set[str]] = defaultdict(set)
    for row in base_rows:
        identity_to_base_id[player_identity_key(row['name'])].add(row['id'])

    for row in patch_rows:
        player_id = str(row['id'])
        patch_by_player[player_id].append(row)
        if player_id.startswith('af-'):
            for base_id in identity_to_base_id.get(player_identity_key(row['name']), set()):
                patch_by_player[base_id].append({**row, 'id': base_id})

    gaps: list[CareerGap] = []

    for player_id, stints in by_player.items():
        name = names.get(player_id, player_id)
        clubs = {row['team'] for row in stints}
        patch_clubs = {row['team'] for row in patch_by_player.get(player_id, [])}
        open_stints = [row for row in stints if is_open_ended(row.get('end_date'))]

        if len(clubs) == 1 and open_stints and patch_clubs - clubs:
            gaps.append(
                CareerGap(
                    external_id=player_id,
                    name=name,
                    issue_type='missing_transfer_clubs',
                    details=f"Base={sorted(clubs)} patches add {sorted(patch_clubs - clubs)}",
                    priority=90,
                )
            )

        if len(open_stints) > 1:
            gaps.append(
                CareerGap(
                    external_id=player_id,
                    name=name,
                    issue_type='multiple_open_stints',
                    details=f"{len(open_stints)} open stints across {sorted(clubs)}",
                    priority=80,
                )
            )

        if len(clubs) == 1 and open_stints and not patch_clubs:
            end = open_stints[0].get('end_date') or ''
            gaps.append(
                CareerGap(
                    external_id=player_id,
                    name=name,
                    issue_type='stale_open_stint',
                    details=f"Sole club {next(iter(clubs))} open until {end or 'unknown'}",
                    priority=60,
                )
            )

        dated = [parse_career_date(row.get('start_date')) for row in stints]
        dated = [value for value in dated if value is not None]
        if dated and max(dated).year >= 2023 and len(clubs) == 1 and not patch_clubs:
            gaps.append(
                CareerGap(
                    external_id=player_id,
                    name=name,
                    issue_type='likely_recent_transfer_missing',
                    details=f"Recent base stint only at {next(iter(clubs))}",
                    priority=50,
                )
            )

    for row in patch_rows:
        if str(row['id']).startswith('af-'):
            identity = player_identity_key(row['name'])
            base_ids = identity_to_base_id.get(identity, set())
            if base_ids:
                gaps.append(
                    CareerGap(
                        external_id=str(row['id']),
                        name=row['name'],
                        issue_type='unlinked_api_player',
                        details=f"Matches base id(s) {sorted(base_ids)} via identity",
                        priority=70,
                    )
                )

    gaps.sort(key=lambda gap: (-gap.priority, gap.name.lower()))
    return gaps


def write_gap_report(gaps: list[CareerGap], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open('w', newline='', encoding='utf-8') as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=['external_id', 'name', 'issue_type', 'details', 'priority'],
        )
        writer.writeheader()
        for gap in gaps:
            writer.writerow(
                {
                    'external_id': gap.external_id,
                    'name': gap.name,
                    'issue_type': gap.issue_type,
                    'details': gap.details,
                    'priority': gap.priority,
                }
            )
