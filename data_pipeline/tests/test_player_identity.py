from pipeline.player_identity import (
    names_likely_same_person,
    pick_preferred_name,
    player_identity_key,
)


def test_player_identity_key_groups_initial_and_full_name():
    assert player_identity_key('Z. Ibrahimović') == player_identity_key('Zlatan Ibrahimović')


def test_player_identity_key_distinguishes_different_first_names():
    assert player_identity_key('A. Ibrahimović') != player_identity_key('Z. Ibrahimović')


def test_names_likely_same_person():
    assert names_likely_same_person('Z. Ibrahimović', 'Zlatan Ibrahimović')
    assert not names_likely_same_person('A. Ibrahimović', 'Zlatan Ibrahimović')


def test_pick_preferred_name():
    assert pick_preferred_name('Z. Ibrahimović', 'Zlatan Ibrahimović') == 'Zlatan Ibrahimović'
    assert pick_preferred_name('Zlatan Ibrahimović', 'Z. Ibrahimović') == 'Zlatan Ibrahimović'
