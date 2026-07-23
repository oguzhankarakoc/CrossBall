"""Tests for one-shot career truth pass (no network)."""

from pathlib import Path

import pipeline.career_patches as patches_mod
import pipeline.career_truth_pass as truth_mod
from pipeline.career_truth_pass import run_career_truth_pass


def test_truth_pass_updates_kerem_current_club(tmp_path: Path, monkeypatch):
    players = tmp_path / 'players.csv'
    players.write_text(
        '\n'.join(
            [
                'id,name,team,nationality,position,start_date,end_date,is_loan,appearances,source',
                '258580,Muhammed Kerem Aktürkoğlu,Galatasaray,TR,LM,2020-09-02,2026-01-01,false,1,kaggle_sofifa',
            ]
        ),
        encoding='utf-8',
    )

    patches_dir = tmp_path / 'patches'
    patches_dir.mkdir()
    manual = patches_dir / 'career_patches.csv'
    api = patches_dir / 'api_football_careers.csv'
    manual.write_text(
        '\n'.join(
            [
                'id,name,team,nationality,position,start_date,end_date,is_loan,appearances,source',
                '258580,Muhammed Kerem Aktürkoğlu,Galatasaray,TR,LM,2020-09-02,2024-07-15,false,1,manual_patch_kerem_gala',
                '258580,Muhammed Kerem Aktürkoğlu,Benfica,TR,LM,2024-07-15,2025-07-01,false,1,manual_patch_kerem_benfica',
                '258580,Muhammed Kerem Aktürkoğlu,Fenerbahce,TR,LM,2025-07-01,,false,1,manual_patch_kerem_fenerbahce',
            ]
        ),
        encoding='utf-8',
    )
    api.write_text(
        'id,name,team,nationality,position,start_date,end_date,is_loan,appearances,source\n',
        encoding='utf-8',
    )

    monkeypatch.setattr(patches_mod, 'DEFAULT_PATCHES_PATH', manual)
    monkeypatch.setattr(patches_mod, 'API_FOOTBALL_PATCHES_PATH', api)
    monkeypatch.setattr(truth_mod, 'DEFAULT_PATCHES_PATH', manual)
    monkeypatch.setattr(truth_mod, 'API_FOOTBALL_PATCHES_PATH', api)

    enriched = tmp_path / 'enriched.csv'
    gaps = tmp_path / 'gaps.csv'
    truth = tmp_path / 'truth.csv'

    summary = run_career_truth_pass(
        players_csv=players,
        enriched_output=enriched,
        gap_report_output=gaps,
        truth_report_output=truth,
    )

    assert summary['enriched_deltas'] >= 1
    assert summary['current_club_updates'] >= 1
    truth_text = truth.read_text(encoding='utf-8')
    assert '258580' in truth_text
    assert 'Fenerbahce' in truth_text
    enriched_text = enriched.read_text(encoding='utf-8')
    assert 'Fenerbahce' in enriched_text
    assert 'Benfica' in enriched_text
    # GS stint closed at transfer date in curated patch / reconcile
    assert '2024-07-15' in enriched_text
