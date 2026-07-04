"""Transform Kaggle / SoFIFA CSV exports into CrossBall pipeline format."""

from __future__ import annotations

import csv
import glob
import re
import uuid
import zipfile
from pathlib import Path

import pandas as pd

from .career_patches import DEFAULT_PATCHES_PATH, load_all_career_patches, merge_career_patches
from .club_metadata import canonical_club_name, club_record
from .nationality_map import nationality_to_iso
from .normalize import is_youth_or_reserve, normalize_name, slugify

MIN_CAREER_YEAR = 1990

# Top ~100 clubs (senior teams only) — intersection puzzle scope
TOP_CLUB_NAMES: list[str] = [
    'FC Barcelona', 'Real Madrid', 'Atletico Madrid', 'Sevilla FC', 'Valencia CF',
    'Manchester United', 'Manchester City', 'Liverpool FC', 'Chelsea FC', 'Arsenal FC',
    'Tottenham Hotspur', 'Newcastle United', 'West Ham United', 'Aston Villa', 'Everton FC',
    'Bayern Munich', 'Borussia Dortmund', 'RB Leipzig', 'Bayer Leverkusen', 'Borussia Mönchengladbach',
    'Juventus', 'AC Milan', 'Inter Milan', 'AS Roma', 'Napoli', 'Lazio', 'Fiorentina',
    'Paris Saint-Germain', 'Lyon', 'Marseille', 'Monaco', 'Lille OSC',
    'Ajax', 'PSV Eindhoven', 'Feyenoord',
    'Benfica', 'FC Porto', 'Sporting CP',
    'Celtic FC', 'Rangers FC',
    'Galatasaray', 'Fenerbahce', 'Besiktas', 'Trabzonspor',
    'River Plate', 'Boca Juniors',
    'Flamengo', 'Palmeiras', 'Santos FC', 'Corinthians',
    'Club America', 'Monterrey',
    'LA Galaxy', 'Inter Miami',
    'Al Hilal', 'Al Nassr', 'Al Ahli',
    'Shakhtar Donetsk', 'Dynamo Kyiv',
    'Red Star Belgrade', 'Partizan',
    'Olympiacos', 'Panathinaikos',
    'Copenhagen', 'Brondby',
    'Anderlecht', 'Club Brugge',
    'Basel', 'Young Boys',
    'Salzburg', 'Rapid Vienna',
    'Sparta Prague', 'Slavia Prague',
    'Legia Warsaw',
    'Steaua Bucharest', 'CFR Cluj',
    'Dinamo Zagreb', 'Hajduk Split',
    'Malmo FF', 'AIK',
    'Rosenborg', 'Molde FK',
    'HJK Helsinki',
    'Qarabag FK',
    'APOEL', 'Omonia',
    'Maccabi Tel Aviv', 'Maccabi Haifa',
    'Sydney FC', 'Melbourne City',
    'Urawa Red Diamonds', 'Kashima Antlers',
    'Guangzhou FC', 'Shanghai SIPG',
    'Ulsan HD', 'Jeonbuk Hyundai',
    'Wydad AC', 'Raja Casablanca',
    'Esperance Tunis', 'Al Ahly Cairo',
    'Kaizer Chiefs', 'Orlando Pirates',
]


def _column(df: pd.DataFrame, *candidates: str) -> str | None:
    lower = {c.lower(): c for c in df.columns}
    for candidate in candidates:
        if candidate.lower() in lower:
            return lower[candidate.lower()]
    return None


def _parse_year(value) -> int | None:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return None
    text = str(value).strip()
    if not text:
        return None
    match = re.search(r'(19|20)\d{2}', text)
    return int(match.group()) if match else None


def _safe_date(value) -> str | None:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return None
    text = str(value).strip()
    if not text:
        return None
    if re.match(r'\d{4}-\d{2}-\d{2}', text):
        return text
    year = _parse_year(text)
    return f'{year}-01-01' if year else None


def discover_kaggle_files(input_path: Path) -> list[Path]:
    if input_path.is_file():
        return [] if zipfile.is_zipfile(input_path) else [input_path]

    patterns = ['male_players*.csv', 'players_*.csv', '*.csv', '**/*.csv']
    files: list[Path] = []
    for pattern in patterns:
        files.extend(input_path.glob(pattern))

    unique = sorted({
        path for path in files
        if path.is_file() and not zipfile.is_zipfile(path)
    })
    preferred = [
        path for path in unique
        if 'legacy' in path.name.lower() or 'players_' in path.name.lower()
    ]
    return preferred or list(unique)


def _read_csv(file_path: Path) -> pd.DataFrame:
    for encoding in ('utf-8', 'utf-8-sig', 'latin-1'):
        try:
            return pd.read_csv(file_path, low_memory=False, encoding=encoding)
        except UnicodeDecodeError:
            continue
    raise UnicodeDecodeError('csv', b'', 0, 1, f'Could not decode {file_path}')


def transform_kaggle_files(
    input_path: Path,
    *,
    min_year: int = MIN_CAREER_YEAR,
    patches_path: Path | None = DEFAULT_PATCHES_PATH,
) -> tuple[list[dict], list[dict]]:
    """Merge multi-year SoFIFA exports into player career rows."""
    files = discover_kaggle_files(input_path)
    if not files:
        raise FileNotFoundError(f'No CSV files found under {input_path}')

    top_club_set = {canonical_club_name(c) for c in TOP_CLUB_NAMES}
    careers_by_player: dict[str, dict] = {}

    for file_path in files:
        df = _read_csv(file_path)
        name_col = _column(df, 'long_name', 'short_name', 'name', 'player_name')
        club_col = _column(df, 'club_name', 'team', 'club')
        nat_col = _column(df, 'nationality', 'nationality_name', 'nation')
        pos_col = _column(df, 'player_positions', 'position', 'preferred_position')
        joined_col = _column(
            df, 'joined', 'start_date', 'club_joined_date', 'club_joined',
        )
        end_col = _column(
            df,
            'contract_valid_until',
            'end_date',
            'club_contract_valid_until_year',
            'club_contract_valid_until',
        )
        loan_col = _column(df, 'loaned_from', 'club_loaned_from')
        id_col = _column(df, 'sofifa_id', 'id', 'player_id')

        if not name_col or not club_col:
            continue

        for _, row in df.iterrows():
            raw_name = str(row[name_col]).strip()
            if not raw_name or raw_name.lower() == 'nan':
                continue

            raw_club = str(row[club_col]).strip()
            if not raw_club or raw_club.lower() in ('nan', '', 'free agents'):
                continue
            if is_youth_or_reserve(raw_club):
                continue

            club = canonical_club_name(raw_club)
            if club not in top_club_set:
                continue

            joined = _safe_date(row[joined_col]) if joined_col else None
            joined_year = _parse_year(joined)
            if joined_year and joined_year < min_year:
                continue

            player_id = str(row[id_col]).strip() if id_col and pd.notna(row[id_col]) else ''
            if not player_id:
                player_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, normalize_name(raw_name)))

            nat_raw = str(row[nat_col]).strip() if nat_col and pd.notna(row[nat_col]) else ''
            position = str(row[pos_col]).split(',')[0].strip() if pos_col and pd.notna(row[pos_col]) else None
            loaned = loan_col and pd.notna(row[loan_col]) and str(row[loan_col]).strip() not in ('', 'nan')

            key = player_id
            if key not in careers_by_player:
                careers_by_player[key] = {
                    'id': player_id,
                    'name': raw_name,
                    'nationality': nat_raw,
                    'position': position,
                    'stints': {},
                }

            stint_key = (club, joined or '')
            careers_by_player[key]['stints'][stint_key] = {
                'team': club,
                'start_date': joined,
                'end_date': _safe_date(row[end_col]) if end_col else None,
                'is_loan': bool(loaned),
            }

    player_rows: list[dict] = []
    clubs_seen: set[str] = set()

    for player in careers_by_player.values():
        if not player['stints']:
            continue
        nat_iso = nationality_to_iso(player['nationality'])
        for stint in player['stints'].values():
            clubs_seen.add(stint['team'])
            player_rows.append({
                'id': player['id'],
                'name': player['name'],
                'team': stint['team'],
                'nationality': nat_iso or '',
                'position': player['position'] or '',
                'start_date': stint['start_date'] or '',
                'end_date': stint['end_date'] or '',
                'is_loan': 'true' if stint['is_loan'] else 'false',
                'appearances': 1,
                'source': 'kaggle_sofifa',
            })

    patches = load_all_career_patches(patches_path)
    player_rows, patch_count = merge_career_patches(player_rows, patches)
    if patch_count:
        print(f'  Applied {patch_count} career patch row(s) (manual + API-Football)')

    clubs_seen: set[str] = set()
    for row in player_rows:
        clubs_seen.add(row['team'])

    club_rows = [club_record(name) for name in sorted(clubs_seen)]
    return player_rows, club_rows


def write_pipeline_csv(
    players: list[dict],
    clubs: list[dict],
    players_out: Path,
    clubs_out: Path,
) -> None:
    players_out.parent.mkdir(parents=True, exist_ok=True)
    clubs_out.parent.mkdir(parents=True, exist_ok=True)

    if players:
        fieldnames = list(players[0].keys())
        with players_out.open('w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(players)

    if clubs:
        with clubs_out.open('w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(
                f,
                fieldnames=[
                    'name', 'country_code', 'is_top_club',
                    'badge_primary_color', 'badge_secondary_color',
                    'badge_initials', 'badge_gradient_style', 'short_name',
                ],
            )
            writer.writeheader()
            for club in clubs:
                writer.writerow({
                    'name': club['name'],
                    'country_code': club.get('country_code') or '',
                    'is_top_club': 'true' if club.get('is_top_club', True) else 'false',
                    'badge_primary_color': club.get('badge_primary_color', ''),
                    'badge_secondary_color': club.get('badge_secondary_color', ''),
                    'badge_initials': club.get('badge_initials', ''),
                    'badge_gradient_style': club.get('badge_gradient_style', 'vertical'),
                    'short_name': club.get('short_name', ''),
                })
