"""Tests for API player id resolution."""

from pipeline.player_aliases import resolve_external_id


def test_resolve_external_id_prefers_roster_match_over_af_id():
    roster = [{'id': '258580', 'name': 'Muhammed Kerem Aktürkoğlu'}]
    ext_id = resolve_external_id(
        'M. Akturkoglu',
        api_football_player_id=99999,
        name_to_external={},
        identity_to_external={},
        alias_map={},
        roster_rows=roster,
    )
    assert ext_id == '258580'


def test_resolve_external_id_uses_alias_map():
    ext_id = resolve_external_id(
        'Unknown Player',
        api_football_player_id=4242,
        name_to_external={},
        identity_to_external={},
        alias_map={'4242': '258580'},
        roster_rows=[],
    )
    assert ext_id == '258580'
