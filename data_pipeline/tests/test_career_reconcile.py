"""Tests for career stint reconciliation."""

from pipeline.career_reconcile import diff_enrichment_rows, reconcile_player_stints


def test_reconcile_closes_open_stint_when_player_moves():
    base = [
        {
            'id': '258580',
            'name': 'Muhammed Kerem Aktürkoğlu',
            'team': 'Galatasaray',
            'start_date': '2020-09-02',
            'end_date': '2026-01-01',
            'is_loan': 'false',
            'source': 'kaggle_sofifa',
        },
    ]
    incoming = base + [
        {
            'id': '258580',
            'name': 'Muhammed Kerem Aktürkoğlu',
            'team': 'Benfica',
            'start_date': '2024-07-15',
            'end_date': '',
            'is_loan': 'false',
            'source': 'api_football_team_211',
        },
        {
            'id': '258580',
            'name': 'Muhammed Kerem Aktürkoğlu',
            'team': 'Fenerbahce',
            'start_date': '2025-07-01',
            'end_date': '',
            'is_loan': 'false',
            'source': 'api_football_team_611',
        },
    ]

    reconciled = reconcile_player_stints(incoming)
    by_team = {row['team']: row for row in reconciled}

    assert by_team['Galatasaray']['end_date'] == '2024-07-15'
    assert by_team['Benfica']['end_date'] == '2025-07-01'
    assert by_team['Fenerbahce']['end_date'] == ''

    deltas = diff_enrichment_rows(base, reconciled)
    assert any(
        row['team'] == 'Galatasaray' and row['end_date'] == '2024-07-15' for row in deltas
    )
    assert any(row['team'] == 'Benfica' for row in deltas)
    assert any(row['team'] == 'Fenerbahce' for row in deltas)
