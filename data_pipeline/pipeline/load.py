"""Load normalized data into PostgreSQL."""

import hashlib
import json
import os

import psycopg2
from dotenv import load_dotenv

load_dotenv()


def get_connection():
    return psycopg2.connect(os.environ['DATABASE_URL'])


def upsert_clubs(conn, clubs: list[dict]) -> int:
    with conn.cursor() as cur:
        for club in clubs:
            cur.execute(
                """
                INSERT INTO clubs (id, name, slug, country_code, is_top_club)
                VALUES (%(id)s, %(name)s, %(slug)s, %(country_code)s, %(is_top_club)s)
                ON CONFLICT (slug) DO UPDATE SET
                  name = EXCLUDED.name,
                  country_code = EXCLUDED.country_code,
                  is_top_club = EXCLUDED.is_top_club
                """,
                club,
            )
    conn.commit()
    return len(clubs)


def upsert_players(conn, players: list[dict]) -> int:
    with conn.cursor() as cur:
        for player in players:
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
                """,
                player,
            )

            for career in player.get('careers', []):
                if career.get('is_youth') or career.get('is_reserve'):
                    continue
                cur.execute(
                    """
                    INSERT INTO player_career_history
                      (player_id, club_id, start_date, end_date, is_loan,
                       is_senior, is_youth, is_reserve, appearances)
                    VALUES (%(player_id)s, %(club_id)s, %(start_date)s, %(end_date)s,
                            %(is_loan)s, %(is_senior)s, false, false, %(appearances)s)
                    ON CONFLICT (player_id, club_id, start_date, is_loan) DO NOTHING
                    """,
                    {**career, 'player_id': player['id']},
                )
    conn.commit()
    return len(players)


def compute_content_hash(data: dict) -> str:
    serialized = json.dumps(data, sort_keys=True, default=str)
    return hashlib.sha256(serialized.encode()).hexdigest()[:16]
