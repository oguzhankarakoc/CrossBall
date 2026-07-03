#!/usr/bin/env python3
"""Run Supabase SQL migrations against DATABASE_URL in data_pipeline/.env."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    env_path = root / "data_pipeline" / ".env"
    load_dotenv(env_path)

    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print(f"DATABASE_URL not set in {env_path}", file=sys.stderr)
        return 1

    migrations_dir = root / "supabase" / "migrations"
    if len(sys.argv) > 1:
        files: list[Path] = []
        for arg in sys.argv[1:]:
            if arg.endswith(".sql"):
                files.append(Path(arg))
            elif arg[:3].isdigit():
                matches = sorted(migrations_dir.glob(f"{arg}_*.sql"))
                if not matches:
                    print(f"No migration matching: {arg}", file=sys.stderr)
                    return 1
                files.extend(matches)
            else:
                files.append(migrations_dir / arg)
    else:
        files = sorted(migrations_dir.glob("*.sql"))

    if not files:
        print("No migration files found.", file=sys.stderr)
        return 1

    conn = psycopg2.connect(database_url)
    conn.autocommit = True
    cur = conn.cursor()

    try:
        for path in files:
            if not path.is_file():
                print(f"Migration not found: {path}", file=sys.stderr)
                return 1
            sql = path.read_text(encoding="utf-8")
            cur.execute(sql)
            print(f"OK  {path.name}")
    finally:
        cur.close()
        conn.close()

    print(f"\nDone. Applied {len(files)} migration(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
