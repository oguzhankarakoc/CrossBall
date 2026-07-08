"""Tests for career gap detection."""

from pathlib import Path

from pipeline.career_gap_report import detect_career_gaps, load_base_career_rows


def test_detect_stale_open_stint_for_single_club_player(tmp_path: Path):
    players_csv = tmp_path / 'players.csv'
    players_csv.write_text(
        '\n'.join(
            [
                'id,name,team,nationality,position,start_date,end_date,is_loan,appearances,source',
                '258580,Muhammed Kerem Aktürkoğlu,Galatasaray,TR,LM,2020-09-02,,false,1,kaggle_sofifa',
            ]
        ),
        encoding='utf-8',
    )

    gaps = detect_career_gaps(players_csv=players_csv)
    issue_types = {gap.issue_type for gap in gaps}
    assert 'stale_open_stint' in issue_types


def test_load_base_career_rows_normalizes_team_names(tmp_path: Path):
    players_csv = tmp_path / 'players.csv'
    players_csv.write_text(
        '\n'.join(
            [
                'id,name,team,nationality,position,start_date,end_date,is_loan,appearances,source',
                '1,Test Player,galatasaray,TR,LM,2020-01-01,,false,1,kaggle_sofifa',
            ]
        ),
        encoding='utf-8',
    )
    rows = load_base_career_rows(players_csv)
    assert rows[0]['team'] == 'Galatasaray'
