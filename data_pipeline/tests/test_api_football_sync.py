"""Tests for API-Football transfer → career stint conversion and sync loop."""

from __future__ import annotations

import csv
from unittest.mock import MagicMock

import pytest

from pipeline.api_football_client import ApiFootballError
from pipeline.api_football_sync import (
    ApiFootballSyncError,
    build_stints_from_player_transfers,
    load_career_csv,
    sync_transfers_to_career_rows,
    write_career_csv,
)


def test_loan_transfer_creates_barcelona_stint():
    af_map = {
        529: 'FC Barcelona',
        33: 'Manchester United',
    }
    transfers = [
        {
            'date': '2014-07-01',
            'type': '€ N/A',
            'teams': {
                'in': {'id': 33, 'name': 'Manchester United'},
                'out': {'id': 999, 'name': 'Academy'},
            },
        },
        {
            'date': '2024-07-15',
            'type': 'Loan',
            'teams': {
                'in': {'id': 529, 'name': 'Barcelona'},
                'out': {'id': 33, 'name': 'Manchester United'},
            },
        },
    ]

    stints = build_stints_from_player_transfers(transfers, af_team_id_to_name=af_map)
    by_team = {s['team']: s for s in stints}

    assert 'FC Barcelona' in by_team
    assert by_team['FC Barcelona']['is_loan'] == 'true'
    assert by_team['FC Barcelona']['start_date'] == '2024-07-15'
    assert by_team['Manchester United']['end_date'] == '2024-07-15'


def test_sync_logs_failed_team_and_preserves_stats():
    client = MagicMock()
    client.requests_made = 0
    client.requests_from_cache = 0
    client.remaining_daily = 42
    client.quota_exhausted = False
    client.transfers_for_team.side_effect = ApiFootballError('API errors: {"requests": "limit"}')

    rows, stats = sync_transfers_to_career_rows(
        team_map={'FC Barcelona': 529},
        client=client,
        use_cache=True,
        min_remaining=None,
    )

    assert rows == []
    assert stats['teams_failed'] == 1
    assert stats['players_seen'] == 0


def test_sync_raises_on_auth_error():
    client = MagicMock()
    client.requests_made = 0
    client.requests_from_cache = 0
    client.remaining_daily = None
    client.quota_exhausted = False
    client.transfers_for_team.side_effect = ApiFootballError('HTTP 401', status_code=401)

    with pytest.raises(ApiFootballSyncError, match='authentication failed'):
        sync_transfers_to_career_rows(
            team_map={'FC Barcelona': 529},
            client=client,
            use_cache=True,
        )


def test_write_career_csv_preserves_existing_file(tmp_path):
    output = tmp_path / 'api_football_careers.csv'
    with output.open('w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(
            f,
            fieldnames=['id', 'name', 'team', 'nationality', 'position', 'start_date', 'end_date', 'is_loan', 'appearances', 'source'],
        )
        writer.writeheader()
        writer.writerow({
            'id': '123',
            'name': 'Player',
            'team': 'FC Barcelona',
            'nationality': '',
            'position': '',
            'start_date': '2020-01-01',
            'end_date': '',
            'is_loan': 'false',
            'appearances': '1',
            'source': 'api_football_team_529',
        })

    preserved = write_career_csv([], output, preserve_existing=True)

    assert preserved is False
    assert len(load_career_csv(output)) == 1
