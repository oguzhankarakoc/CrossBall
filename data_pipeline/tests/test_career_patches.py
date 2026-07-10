"""Tests for curated career patch merge."""

from pathlib import Path

from pipeline.career_patches import (
    load_all_career_patches,
    load_career_patches,
    merge_career_patches,
)


def test_merge_career_patches_overrides_and_adds():
    base = [
        {
            'id': '231677',
            'name': 'Marcus Rashford',
            'team': 'Manchester United',
            'nationality': 'GB',
            'position': 'ST',
            'start_date': '2014-07-01',
            'end_date': '2023-01-01',
            'is_loan': 'false',
            'appearances': 1,
            'source': 'kaggle_sofifa',
        },
    ]
    patches = [
        {
            'id': '231677',
            'name': 'Marcus Rashford',
            'team': 'Manchester United',
            'nationality': 'GB',
            'position': 'ST',
            'start_date': '2014-07-01',
            'end_date': '2027-06-30',
            'is_loan': 'false',
            'appearances': 1,
            'source': 'manual_patch',
        },
        {
            'id': '231677',
            'name': 'Marcus Rashford',
            'team': 'FC Barcelona',
            'nationality': 'GB',
            'position': 'ST',
            'start_date': '2024-07-01',
            'end_date': '2025-06-30',
            'is_loan': 'true',
            'appearances': 1,
            'source': 'manual_patch',
        },
    ]

    merged, count = merge_career_patches(base, patches)
    assert count == 2
    assert len(merged) == 2

    man_utd = next(r for r in merged if r['team'] == 'Manchester United')
    barca = next(r for r in merged if r['team'] == 'FC Barcelona')

    assert man_utd['end_date'] == '2027-06-30'
    assert barca['is_loan'] == 'true'


def test_load_default_patches_file():
    patches = load_career_patches(
        Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'patches' / 'career_patches.csv'
    )
    assert any(p['id'] == '231677' and p['team'] == 'FC Barcelona' for p in patches)


def test_load_all_career_patches_can_skip_enriched():
    patches_dir = Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'patches'
    manual_path = patches_dir / 'career_patches.csv'
    api_path = patches_dir / 'api_football_careers.csv'
    enriched_path = patches_dir / 'enriched_careers.csv'

    manual_ids = {row['id'] for row in load_career_patches(manual_path)}
    api_ids = {row['id'] for row in load_career_patches(api_path)}
    enriched_only_ids = {
        row['id']
        for row in load_career_patches(enriched_path)
        if row['id'] not in manual_ids and row['id'] not in api_ids
    }
    assert enriched_only_ids

    with_enriched = load_all_career_patches(
        manual_path=manual_path,
        api_football_path=api_path,
        enriched_path=enriched_path,
        include_enriched=True,
    )
    without_enriched = load_all_career_patches(
        manual_path=manual_path,
        api_football_path=api_path,
        enriched_path=enriched_path,
        include_enriched=False,
    )

    assert len(without_enriched) < len(with_enriched)
    without_ids = {row['id'] for row in without_enriched}
    assert enriched_only_ids.isdisjoint(without_ids)
