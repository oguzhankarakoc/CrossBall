from pathlib import Path

import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))

from run_migrations import migration_version, resolve_migration_files  # noqa: E402


def test_migration_version_uses_stem():
    assert migration_version(Path("028_ensure_daily_smallint_cast.sql")) == "028_ensure_daily_smallint_cast"


def test_resolve_all_migrations_sorted(tmp_path):
    migrations_dir = tmp_path / "migrations"
    migrations_dir.mkdir()
    (migrations_dir / "010_b.sql").write_text("-- b")
    (migrations_dir / "009_a.sql").write_text("-- a")

    files = resolve_migration_files(migrations_dir, [])
    assert [path.name for path in files] == ["009_a.sql", "010_b.sql"]


def test_resolve_numeric_prefix():
    migrations_dir = Path(__file__).resolve().parents[2] / "supabase" / "migrations"
    files = resolve_migration_files(migrations_dir, ["036"])
    assert len(files) == 1
    assert files[0].name == "036_security_rls_lockdown.sql"
