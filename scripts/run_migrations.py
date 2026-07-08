#!/usr/bin/env python3
"""Run Supabase SQL migrations against DATABASE_URL in data_pipeline/.env."""

from __future__ import annotations

import os
import sys
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

import psycopg2
from dotenv import load_dotenv

TRACKING_TABLE = "crossball_applied_migrations"
TRACKING_DDL = f"""
CREATE TABLE IF NOT EXISTS public.{TRACKING_TABLE} (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
"""


def _sanitize_database_url(database_url: str) -> str:
    """Drop URI params psycopg2 doesn't accept (e.g. pgbouncer=true)."""
    split = urlsplit(database_url)
    if not split.query:
        return database_url

    filtered = [(k, v) for k, v in parse_qsl(split.query, keep_blank_values=True) if k != "pgbouncer"]
    if len(filtered) == len(parse_qsl(split.query, keep_blank_values=True)):
        return database_url

    return urlunsplit((split.scheme, split.netloc, split.path, urlencode(filtered), split.fragment))


def migration_version(path: Path) -> str:
    """Version key aligned with Supabase CLI (filename without .sql)."""
    return path.stem


def migration_prefix(version: str) -> str:
    """Numeric prefix shared by Supabase CLI ('011') and repo files ('011_game_economy_engine')."""
    head = version.split("_", 1)[0]
    return head if head.isdigit() else version


def build_prefix_index(files: list[Path]) -> dict[str, str]:
    """Map numeric prefix -> canonical filename stem."""
    index: dict[str, str] = {}
    for path in files:
        stem = migration_version(path)
        index[migration_prefix(stem)] = stem
    return index


def is_migration_applied(version: str, applied_versions: set[str]) -> bool:
    if version in applied_versions:
        return True
    prefix = migration_prefix(version)
    return any(migration_prefix(applied) == prefix for applied in applied_versions)


def _supabase_tracking_exists(cur) -> bool:
    cur.execute(
        """
        SELECT EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = 'supabase_migrations'
            AND table_name = 'schema_migrations'
        )
        """
    )
    return bool(cur.fetchone()[0])


def load_applied_versions(cur) -> set[str]:
    applied: set[str] = set()

    if _supabase_tracking_exists(cur):
        cur.execute("SELECT version FROM supabase_migrations.schema_migrations")
        applied.update(row[0] for row in cur.fetchall())

    cur.execute(TRACKING_DDL)
    cur.execute(f"SELECT version FROM public.{TRACKING_TABLE}")
    applied.update(row[0] for row in cur.fetchall())
    return applied


def record_applied_version(cur, version: str) -> None:
    cur.execute(
        f"""
        INSERT INTO public.{TRACKING_TABLE} (version)
        VALUES (%s)
        ON CONFLICT (version) DO NOTHING
        """,
        (version,),
    )


def sync_tracking(cur, files: list[Path]) -> int:
    """Backfill crossball_applied_migrations from Supabase CLI tracking + prefix map."""
    prefix_index = build_prefix_index(files)
    applied = load_applied_versions(cur)
    synced = 0

    for raw in sorted(applied):
        canonical = prefix_index.get(migration_prefix(raw))
        if canonical is None:
            continue
        cur.execute(
            f"""
            INSERT INTO public.{TRACKING_TABLE} (version)
            VALUES (%s)
            ON CONFLICT (version) DO NOTHING
            RETURNING version
            """,
            (canonical,),
        )
        if cur.fetchone():
            print(f"SYNC {canonical} (from {raw})")
            synced += 1

    return synced


def resolve_migration_files(migrations_dir: Path, args: list[str]) -> list[Path] | None:
    if not args:
        return sorted(migrations_dir.glob("*.sql"))

    files: list[Path] = []
    for arg in args:
        if arg.endswith(".sql"):
            files.append(Path(arg))
        elif arg[:3].isdigit():
            matches = sorted(migrations_dir.glob(f"{arg}_*.sql"))
            if not matches:
                print(f"No migration matching: {arg}", file=sys.stderr)
                return None
            files.extend(matches)
        else:
            files.append(migrations_dir / arg)
    return files


def apply_migration(cur, path: Path, version: str) -> None:
    sql = path.read_text(encoding="utf-8")
    cur.execute(sql)
    record_applied_version(cur, version)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    env_path = root / "data_pipeline" / ".env"
    load_dotenv(env_path)

    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print(f"DATABASE_URL not set in {env_path}", file=sys.stderr)
        return 1

    migrations_dir = root / "supabase" / "migrations"
    args = [a for a in sys.argv[1:] if a != "--sync-tracking"]
    sync_only = "--sync-tracking" in sys.argv[1:]

    files = resolve_migration_files(migrations_dir, args)
    if files is None:
        return 1

    if not files and not sync_only:
        print("No migration files found.", file=sys.stderr)
        return 1

    conn = psycopg2.connect(_sanitize_database_url(database_url))
    cur = conn.cursor()

    applied = 0
    skipped = 0

    try:
        if sync_only:
            synced = sync_tracking(cur, sorted(migrations_dir.glob("*.sql")))
            conn.commit()
            print(f"\nSynced {synced} migration record(s) into {TRACKING_TABLE}.")
            return 0

        applied_versions = load_applied_versions(cur)

        for path in files:
            if not path.is_file():
                print(f"Migration not found: {path}", file=sys.stderr)
                conn.rollback()
                return 1

            version = migration_version(path)
            if is_migration_applied(version, applied_versions):
                print(f"SKIP {path.name} (already applied)")
                skipped += 1
                continue

            try:
                apply_migration(cur, path, version)
                conn.commit()
                applied_versions.add(version)
                print(f"OK   {path.name}")
                applied += 1
            except Exception as exc:
                conn.rollback()
                print(f"FAIL {path.name}: {exc}", file=sys.stderr)
                return 1
    finally:
        cur.close()
        conn.close()

    print(f"\nDone. Applied {applied} migration(s), skipped {skipped}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
