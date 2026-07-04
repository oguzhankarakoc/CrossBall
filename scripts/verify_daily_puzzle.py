#!/usr/bin/env python3
"""Verify daily puzzle generation and API response shape."""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "data_pipeline"))

from dotenv import load_dotenv  # noqa: E402

load_dotenv(ROOT / "data_pipeline" / ".env")

DATABASE_URL = os.environ.get("DATABASE_URL")
SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_ANON_KEY = os.environ.get("SUPABASE_ANON_KEY", "")


def check_db() -> None:
    if not DATABASE_URL:
        print("SKIP DB: DATABASE_URL not set")
        return

    import psycopg2

    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    cur.execute("SELECT COUNT(*) FROM club_relationships")
    rel_count = cur.fetchone()[0]
    print(f"club_relationships: {rel_count}")

    cur.execute(
        """
        SELECT id, puzzle_date, puzzle_hash, difficulty_tier, quality_score
        FROM puzzles
        WHERE mode = 'daily' AND is_published = TRUE
        ORDER BY puzzle_date DESC
        LIMIT 3
        """
    )
    rows = cur.fetchall()
    print(f"recent daily puzzles: {len(rows)}")
    for row in rows:
        print(f"  {row[1]} tier={row[3]} quality={row[4]} hash={row[2][:8]}...")

    cur.execute(
        """
        SELECT ca.slug, cb.slug
        FROM puzzles p
        JOIN puzzle_row_clubs pr ON pr.puzzle_id = p.id
        JOIN puzzle_col_clubs pc ON pc.puzzle_id = p.id
        JOIN clubs ca ON ca.id = pr.club_id
        JOIN clubs cb ON cb.id = pc.club_id
        WHERE p.mode = 'daily' AND p.puzzle_date = CURRENT_DATE
        ORDER BY pr.row_index, pc.col_index
        LIMIT 9
        """
    )
    cells = cur.fetchall()
    if cells:
        print("today grid pairs (sample):")
        for a, b in cells[:6]:
            print(f"  {a} x {b}")

    cur.close()
    conn.close()


def check_api() -> None:
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        print("SKIP API: SUPABASE_URL / SUPABASE_ANON_KEY not set")
        return

    req = urllib.request.Request(
        f"{SUPABASE_URL}/functions/v1/daily-puzzle",
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        print(f"daily-puzzle API HTTP {exc.code}: {exc.read().decode()[:500]}")
        return

    row_ids = [c.get("id") for c in body.get("row_clubs", [])]
    col_ids = [c.get("id") for c in body.get("col_clubs", [])]
    print(f"API OK puzzle_id={body.get('puzzle_id')} date={body.get('date')}")
    print(f"  rows: {[c.get('slug') for c in body.get('row_clubs', [])]}")
    print(f"  cols: {[c.get('slug') for c in body.get('col_clubs', [])]}")
    uuid_like = all(
        isinstance(i, str) and len(i) == 36 and i.count("-") == 4 for i in row_ids + col_ids
    )
    print(f"  live UUID clubs: {uuid_like}")


def main() -> int:
    check_db()
    check_api()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
