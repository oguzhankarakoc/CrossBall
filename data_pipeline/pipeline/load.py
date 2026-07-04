"""Load normalized data into PostgreSQL."""

import hashlib
import json
import os

import psycopg2
from dotenv import load_dotenv

load_dotenv()


def get_connection():
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    with conn.cursor() as cur:
        cur.execute("SET statement_timeout = '0'")
    conn.commit()
    return conn


def upsert_clubs(conn, clubs: list[dict]) -> dict[str, str]:
    """Upsert clubs and return slug → database id (handles ON CONFLICT id reuse)."""
    slug_to_id: dict[str, str] = {}
    with conn.cursor() as cur:
        for club in clubs:
            cur.execute(
                """
                INSERT INTO clubs (
                  id, name, slug, country_code, is_top_club,
                  badge_primary_color, badge_secondary_color, badge_initials,
                  badge_gradient_style, short_name, display_name, short_code, league_name
                )
                VALUES (
                  %(id)s, %(name)s, %(slug)s, %(country_code)s, %(is_top_club)s,
                  %(badge_primary_color)s, %(badge_secondary_color)s, %(badge_initials)s,
                  %(badge_gradient_style)s, %(short_name)s, %(display_name)s, %(short_code)s,
                  %(league_name)s
                )
                ON CONFLICT (slug) DO UPDATE SET
                  name = EXCLUDED.name,
                  country_code = EXCLUDED.country_code,
                  is_top_club = EXCLUDED.is_top_club,
                  badge_primary_color = EXCLUDED.badge_primary_color,
                  badge_secondary_color = EXCLUDED.badge_secondary_color,
                  badge_initials = EXCLUDED.badge_initials,
                  badge_gradient_style = EXCLUDED.badge_gradient_style,
                  short_name = EXCLUDED.short_name,
                  display_name = COALESCE(EXCLUDED.display_name, clubs.display_name),
                  short_code = COALESCE(EXCLUDED.short_code, clubs.short_code),
                  league_name = COALESCE(EXCLUDED.league_name, clubs.league_name)
                RETURNING id, slug
                """,
                {
                    'id': club['id'],
                    'name': club['name'],
                    'slug': club['slug'],
                    'country_code': club.get('country_code'),
                    'is_top_club': club.get('is_top_club', True),
                    'badge_primary_color': club.get('badge_primary_color'),
                    'badge_secondary_color': club.get('badge_secondary_color'),
                    'badge_initials': club.get('badge_initials'),
                    'badge_gradient_style': club.get('badge_gradient_style', 'vertical'),
                    'short_name': club.get('short_name'),
                    'display_name': club.get('display_name') or club['name'],
                    'short_code': club.get('short_code') or club.get('badge_initials'),
                    'league_name': club.get('league_name'),
                },
            )
            row = cur.fetchone()
            slug_to_id[row[1]] = str(row[0])
    conn.commit()
    return slug_to_id


def remap_career_club_ids(
    players: list[dict],
    clubs: list[dict],
    slug_to_id: dict[str, str],
) -> None:
    """Replace in-memory club UUIDs with ids returned from the database."""
    temp_id_to_slug = {club['id']: club['slug'] for club in clubs}
    for player in players:
        for career in player.get('careers', []):
            slug = temp_id_to_slug.get(career['club_id'])
            if slug and slug in slug_to_id:
                career['club_id'] = slug_to_id[slug]


def upsert_players(conn, players: list[dict], *, batch_size: int = 250) -> int:
    total = 0
    with conn.cursor() as cur:
        for index, player in enumerate(players, start=1):
            cur.execute(
                """
                INSERT INTO players (id, external_id, name, normalized_name,
                                     nationality_code, primary_position)
                VALUES (%(id)s, %(external_id)s, %(name)s, %(normalized_name)s,
                        %(nationality_code)s, %(primary_position)s)
                ON CONFLICT (external_id) DO UPDATE SET
                  name = EXCLUDED.name,
                  normalized_name = EXCLUDED.normalized_name,
                  nationality_code = EXCLUDED.nationality_code,
                  primary_position = EXCLUDED.primary_position
                RETURNING id
                """,
                player,
            )
            player_id = str(cur.fetchone()[0])

            for career in player.get('careers', []):
                if career.get('is_youth') or career.get('is_reserve'):
                    continue
                cur.execute(
                    """
                    INSERT INTO player_career_history
                      (player_id, club_id, start_date, end_date, is_loan,
                       is_senior, is_youth, is_reserve, appearances, source)
                    VALUES (%(player_id)s, %(club_id)s, %(start_date)s, %(end_date)s,
                            %(is_loan)s, %(is_senior)s, false, false, %(appearances)s,
                            %(source)s)
                    ON CONFLICT (player_id, club_id, start_date, is_loan) DO UPDATE SET
                      end_date = EXCLUDED.end_date,
                      appearances = GREATEST(
                        COALESCE(player_career_history.appearances, 0),
                        COALESCE(EXCLUDED.appearances, 0)
                      ),
                      source = EXCLUDED.source
                    """,
                    {
                        **career,
                        'player_id': player_id,
                        'source': career.get('source') or 'kaggle_sofifa',
                    },
                )

            total += 1
            if index % batch_size == 0:
                conn.commit()
                print(f'  Loaded {index}/{len(players)} players...')

    conn.commit()
    return total


def refresh_club_relationships(conn) -> None:
    """Rebuild precomputed club relationship graph for puzzle generation."""
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT EXISTS (
              SELECT 1 FROM pg_proc WHERE proname = 'refresh_club_relationships'
            )
            """
        )
        if not cur.fetchone()[0]:
            return
        cur.execute('SELECT public.refresh_club_relationships()')
        count = cur.fetchone()[0]
        conn.commit()
        print(f'  Refreshed club_relationships ({count} pairs).')


def refresh_intersections(conn) -> None:
    """Refresh materialized view if present (optional post-load step)."""
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT EXISTS (
              SELECT 1 FROM pg_matviews WHERE matviewname = 'player_club_intersections'
            )
            """
        )
        exists = cur.fetchone()[0]
        if not exists:
            return

        try:
            cur.execute('SELECT public.refresh_player_club_intersections()')
        except psycopg2.Error:
            conn.rollback()
            cur.execute('REFRESH MATERIALIZED VIEW player_club_intersections')
        conn.commit()
        print('  Refreshed player_club_intersections materialized view.')


def compute_content_hash(data: dict) -> str:
    serialized = json.dumps(data, sort_keys=True, default=str)
    return hashlib.sha256(serialized.encode()).hexdigest()[:16]
