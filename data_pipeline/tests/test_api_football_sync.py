"""Tests for API-Football transfer → career stint conversion."""

from pipeline.api_football_sync import build_stints_from_player_transfers


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
