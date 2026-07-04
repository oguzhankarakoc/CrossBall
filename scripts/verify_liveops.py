#!/usr/bin/env python3
"""Verify LiveOps Engine tables, seed data, and loe_get_snapshot RPC."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    load_dotenv(root / "data_pipeline" / ".env")

    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("DATABASE_URL not set in data_pipeline/.env", file=sys.stderr)
        return 1

    conn = psycopg2.connect(database_url)
    cur = conn.cursor()

    checks = [
        ("liveops_feature_flags", "SELECT COUNT(*) FROM liveops_feature_flags"),
        ("liveops_events", "SELECT COUNT(*) FROM liveops_events"),
        ("liveops_announcements", "SELECT COUNT(*) FROM liveops_announcements"),
        ("liveops_community_goals", "SELECT COUNT(*) FROM liveops_community_goals"),
    ]

    print("LiveOps verification")
    print("-" * 40)
    for label, sql in checks:
        cur.execute(sql)
        count = cur.fetchone()[0]
        status = "OK" if count > 0 else "EMPTY"
        print(f"{status:5} {label}: {count} rows")

    cur.execute(
        """
        SELECT loe_get_snapshot(NULL, 'tr', 'ios', 'TR', '1.0.0')
        """
    )
    snapshot = cur.fetchone()[0]
    flags = snapshot.get("feature_flags", {})
    events = snapshot.get("active_events", [])
    announcements = snapshot.get("announcements", [])

    print("-" * 40)
    print(f"OK    loe_get_snapshot RPC")
    print(f"      feature_flags: {len(flags)}")
    print(f"      active_events: {len(events)}")
    print(f"      announcements: {len(announcements)}")
    print(f"      friend_challenges enabled: {flags.get('friend_challenges')}")

    if events:
        print(f"      first event: {events[0].get('title')}")
    if announcements:
        print(f"      first announcement: {announcements[0].get('title')}")

    cur.close()
    conn.close()
    print("-" * 40)
    print("LiveOps backend is ready.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
