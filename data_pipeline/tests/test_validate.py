from pipeline.validate import validate_puzzle_fairness, validate_players


def test_validate_players_empty():
    result = validate_players([], [])
    assert result.valid


def test_validate_puzzle_fairness_rejects_unfair_cells():
    result = validate_puzzle_fairness([2, 8, 5])
    assert not result.valid


def test_validate_puzzle_fairness_accepts_fair_cells():
    result = validate_puzzle_fairness([8, 10, 12])
    assert result.valid
