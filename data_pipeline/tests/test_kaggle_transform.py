"""Tests for Kaggle transform helpers."""

from pathlib import Path

from pipeline.kaggle_transform import discover_kaggle_files, transform_kaggle_files


def test_transform_demo_csv(tmp_path: Path):
    demo = tmp_path / 'players_demo.csv'
    demo.write_text(
        'sofifa_id,long_name,club_name,nationality,player_positions,joined,contract_valid_until\n'
        '1,Pedro,FC Barcelona,Spain,ST,2008-07-01,2015-06-30\n'
        '1,Pedro,Chelsea,England,ST,2015-07-01,2020-01-31\n',
        encoding='utf-8',
    )
    files = discover_kaggle_files(tmp_path)
    assert len(files) == 1
    players, clubs = transform_kaggle_files(tmp_path)
    assert len(players) >= 2
    assert any(c['name'] == 'FC Barcelona' for c in clubs)
