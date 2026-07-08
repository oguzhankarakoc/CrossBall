"""Tests for enrichment orchestration without live API calls."""

from pathlib import Path

from pipeline.career_enrichment import build_enriched_career_rows


def test_build_enriched_career_rows_from_manual_and_base(tmp_path: Path):
    players_csv = tmp_path / 'players.csv'
    manual = tmp_path / 'manual.csv'
    api_csv = tmp_path / 'api.csv'

    players_csv.write_text(
        '\n'.join(
            [
                'id,name,team,nationality,position,start_date,end_date,is_loan,appearances,source',
                '258580,Muhammed Kerem Aktürkoğlu,Galatasaray,TR,LM,2020-09-02,2026-01-01,false,1,kaggle_sofifa',
            ]
        ),
        encoding='utf-8',
    )
    manual.write_text('id,name,team,nationality,position,start_date,end_date,is_loan,appearances,source\n', encoding='utf-8')
    api_csv.write_text(
        '\n'.join(
            [
                'id,name,team,nationality,position,start_date,end_date,is_loan,appearances,source',
                '258580,Muhammed Kerem Aktürkoğlu,Benfica,TR,LM,2024-07-15,,false,1,api_football_team_211',
                '258580,Muhammed Kerem Aktürkoğlu,Fenerbahce,TR,LM,2025-07-01,,false,1,api_football_team_611',
            ]
        ),
        encoding='utf-8',
    )

    deltas, reconciled = build_enriched_career_rows(
        players_csv=players_csv,
        manual_patches_path=manual,
        api_patches_path=api_csv,
    )

    teams = {row['team'] for row in reconciled}
    assert teams == {'Galatasaray', 'Benfica', 'Fenerbahce'}
    assert any(row['team'] == 'Galatasaray' and row['end_date'] == '2024-07-15' for row in deltas)
