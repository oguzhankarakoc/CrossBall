import importlib.util
from pathlib import Path

import pytest


def _load_runner():
    path = Path(__file__).resolve().parents[2] / "scripts" / "run_migrations.py"
    spec = importlib.util.spec_from_file_location("run_migrations", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


runner = _load_runner()


def test_migration_prefix_matches_supabase_and_repo_keys():
    assert runner.migration_prefix("011") == "011"
    assert runner.migration_prefix("011_game_economy_engine") == "011"
    assert runner.migration_prefix("039_player_identity_dotted_initials") == "039"


def test_is_migration_applied_accepts_numeric_alias():
    applied = {"011", "012_liveops_engine"}
    assert runner.is_migration_applied("011_game_economy_engine", applied)
    assert runner.is_migration_applied("012_liveops_engine", applied)
    assert not runner.is_migration_applied("037_weekly_daily_leaderboard_and_scoring", applied)


def test_build_prefix_index_uses_repo_stem():
    files = [
        Path("supabase/migrations/011_game_economy_engine.sql"),
        Path("supabase/migrations/037_weekly_daily_leaderboard_and_scoring.sql"),
    ]
    index = runner.build_prefix_index(files)
    assert index["011"] == "011_game_economy_engine"
    assert index["037"] == "037_weekly_daily_leaderboard_and_scoring"
