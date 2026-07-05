from unittest.mock import MagicMock, patch

from pipeline.load import (
    _find_existing_player,
    _update_player_record,
    normalize_database_url,
)


def test_normalize_database_url_strips_pgbouncer_param():
    url = (
        'postgresql://postgres.ref:secret@aws-0-ap-south-1.pooler.supabase.com:6543/postgres'
        '?pgbouncer=true'
    )
    assert normalize_database_url(url) == (
        'postgresql://postgres.ref:secret@aws-0-ap-south-1.pooler.supabase.com:6543/postgres'
    )


def test_normalize_database_url_keeps_other_params():
    url = 'postgresql://postgres:secret@localhost:5432/postgres?connect_timeout=10'
    assert normalize_database_url(url) == url


def test_find_existing_player_prefers_external_id():
    cur = MagicMock()
    cur.fetchone.side_effect = [
        ('owner-uuid', '213956', 'Player A', 'BR', 'ST', 'silva|g'),
    ]
    player = {
        'id': 'new-uuid',
        'name': 'Gabriel Silva',
        'external_id': '213956',
        'identity_key': 'silva|g',
    }
    existing = _find_existing_player(cur, player)
    assert existing is not None
    assert existing['id'] == 'owner-uuid'
    assert existing['external_id'] == '213956'
    cur.execute.assert_called_once()
    assert 'WHERE external_id = %s' in cur.execute.call_args[0][0]


@patch('pipeline.load._merge_player_into_owner')
def test_update_player_record_merges_when_external_id_owned_elsewhere(mock_merge):
    cur = MagicMock()
    cur.fetchone.side_effect = [
        ('owner-uuid',),
        (
            'owner-uuid',
            '213956',
            'Gabriel Silva',
            'BR',
            'ST',
            'silva|g',
        ),
    ]

    player_id = _update_player_record(
        cur,
        'drop-uuid',
        {
            'id': 'drop-uuid',
            'external_id': None,
            'name': 'G. Silva',
            'nationality_code': None,
            'primary_position': None,
            'identity_key': 'silva|g',
        },
        {
            'id': 'drop-uuid',
            'external_id': '213956',
            'name': 'Gabriel Silva',
            'normalized_name': 'gabriel silva',
            'identity_key': 'silva|g',
            'nationality_code': 'BR',
            'primary_position': 'ST',
        },
    )

    assert player_id == 'owner-uuid'
    mock_merge.assert_called_once_with(cur, 'drop-uuid', 'owner-uuid')
    update_calls = [
        call
        for call in cur.execute.call_args_list
        if call[0][0].strip().startswith('UPDATE players')
    ]
    assert update_calls
    assert update_calls[-1][0][1]['id'] == 'owner-uuid'
