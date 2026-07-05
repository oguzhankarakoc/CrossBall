"""Load normalized data into PostgreSQL."""

from __future__ import annotations

import hashlib
import json
import os
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

import psycopg2
from dotenv import load_dotenv

from .normalize import normalize_name
from .player_identity import (
    names_likely_same_person,
    pick_preferred_external_id,
    pick_preferred_name,
    pick_preferred_optional,
    player_completeness_score,
    player_identity_key,
)

load_dotenv()


def normalize_database_url(url: str) -> str:
    """Strip Supabase URI params that psycopg2 does not accept (e.g. pgbouncer=true)."""
    parsed = urlparse(url)
    if not parsed.query:
        return url
    params = parse_qs(parsed.query, keep_blank_values=True)
    params.pop('pgbouncer', None)
    query = urlencode(params, doseq=True)
    return urlunparse(parsed._replace(query=query))


def get_connection():
    url = normalize_database_url(os.environ['DATABASE_URL'])
    connect_kwargs: dict[str, str] = {}
    if 'localhost' not in url and '127.0.0.1' not in url:
        connect_kwargs['sslmode'] = 'require'
    conn = psycopg2.connect(url, **connect_kwargs)
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


def _player_row(player: dict) -> dict:
    name = player['name']
    return {
        'id': player['id'],
        'external_id': player.get('external_id'),
        'name': name,
        'normalized_name': player.get('normalized_name') or normalize_name(name),
        'identity_key': player.get('identity_key') or player_identity_key(name),
        'nationality_code': player.get('nationality_code'),
        'primary_position': player.get('primary_position'),
    }


def _existing_from_db_row(row) -> dict:
    existing_id, ext_id, name, nat, pos, ikey = row
    return {
        'id': str(existing_id),
        'external_id': ext_id,
        'name': name,
        'nationality_code': nat,
        'primary_position': pos,
        'identity_key': ikey,
    }


def _find_existing_player(cur, player: dict) -> dict | None:
    row = _player_row(player)

    if row['external_id']:
        cur.execute(
            """
            SELECT id, external_id, name, nationality_code, primary_position, identity_key
            FROM players
            WHERE external_id = %s
            """,
            (row['external_id'],),
        )
        hit = cur.fetchone()
        if hit:
            return _existing_from_db_row(hit)

    cur.execute(
        """
        SELECT id, external_id, name, nationality_code, primary_position, identity_key
        FROM players
        WHERE identity_key = %s
        """,
        (row['identity_key'],),
    )
    for hit in cur.fetchall():
        existing = _existing_from_db_row(hit)
        if names_likely_same_person(existing['name'], row['name']):
            return existing
    return None


def _merge_player_into_owner(cur, drop_id: str, keep_id: str) -> None:
    """Move careers and stats from drop_id to keep_id, then delete drop_id."""
    if drop_id == keep_id:
        return
    _reassign_player_references(cur, drop_id, keep_id)
    cur.execute('DELETE FROM players WHERE id = %s', (drop_id,))


def _update_player_record(cur, player_id: str, existing: dict, incoming: dict) -> str:
    merged_name = pick_preferred_name(existing['name'], incoming['name'])
    merged_external = pick_preferred_external_id(
        existing.get('external_id'),
        incoming.get('external_id'),
    )

    if merged_external:
        cur.execute(
            """
            SELECT id FROM players
            WHERE external_id = %s AND id <> %s
            LIMIT 1
            """,
            (merged_external, player_id),
        )
        conflict = cur.fetchone()
        if conflict:
            owner_id = str(conflict[0])
            _merge_player_into_owner(cur, player_id, owner_id)
            player_id = owner_id
            cur.execute(
                """
                SELECT id, external_id, name, nationality_code, primary_position, identity_key
                FROM players
                WHERE id = %s
                """,
                (player_id,),
            )
            row = cur.fetchone()
            if row:
                existing = _existing_from_db_row(row)
                merged_name = pick_preferred_name(existing['name'], incoming['name'])
                merged_external = pick_preferred_external_id(
                    existing.get('external_id'),
                    incoming.get('external_id'),
                )

    merged = {
        'id': player_id,
        'external_id': merged_external,
        'name': merged_name,
        'normalized_name': normalize_name(merged_name),
        'identity_key': incoming.get('identity_key') or player_identity_key(merged_name),
        'nationality_code': pick_preferred_optional(
            incoming.get('nationality_code'),
            existing.get('nationality_code'),
        ),
        'primary_position': pick_preferred_optional(
            incoming.get('primary_position'),
            existing.get('primary_position'),
        ),
    }
    cur.execute(
        """
        UPDATE players
        SET external_id = %(external_id)s,
            name = %(name)s,
            normalized_name = %(normalized_name)s,
            identity_key = %(identity_key)s,
            nationality_code = COALESCE(%(nationality_code)s, nationality_code),
            primary_position = COALESCE(%(primary_position)s, primary_position),
            updated_at = NOW()
        WHERE id = %(id)s
        """,
        merged,
    )
    return player_id


def _insert_careers(cur, player_id: str, careers: list[dict]) -> None:
    for career in careers:
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


def upsert_players(conn, players: list[dict], *, batch_size: int = 250) -> int:
    total = 0
    with conn.cursor() as cur:
        for index, player in enumerate(players, start=1):
            incoming = _player_row(player)
            existing = _find_existing_player(cur, incoming)

            if existing:
                player_id = _update_player_record(cur, existing['id'], existing, incoming)
            else:
                cur.execute(
                    """
                    INSERT INTO players (
                      id, external_id, name, normalized_name, identity_key,
                      nationality_code, primary_position
                    )
                    VALUES (
                      %(id)s, %(external_id)s, %(name)s, %(normalized_name)s, %(identity_key)s,
                      %(nationality_code)s, %(primary_position)s
                    )
                    ON CONFLICT (external_id) DO UPDATE SET
                      name = EXCLUDED.name,
                      normalized_name = EXCLUDED.normalized_name,
                      identity_key = EXCLUDED.identity_key,
                      nationality_code = COALESCE(EXCLUDED.nationality_code, players.nationality_code),
                      primary_position = COALESCE(EXCLUDED.primary_position, players.primary_position),
                      updated_at = NOW()
                    RETURNING id
                    """,
                    incoming,
                )
                player_id = str(cur.fetchone()[0])

            _insert_careers(cur, player_id, player.get('careers', []))
            total += 1
            if index % batch_size == 0:
                conn.commit()
                print(f'  Loaded {index}/{len(players)} players...')

    conn.commit()
    return total


def backfill_identity_keys(conn) -> int:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT id, name
            FROM players
            WHERE identity_key IS NULL OR identity_key = ''
            """
        )
        rows = cur.fetchall()
        if not rows:
            return 0
        print(f'  Backfilling identity_key for {len(rows)} player(s)...')
        updates = [(player_identity_key(name), player_id) for player_id, name in rows]
        for index in range(0, len(updates), 500):
            cur.executemany(
                """
                UPDATE players
                SET identity_key = %s, updated_at = NOW()
                WHERE id = %s
                """,
                updates[index:index + 500],
            )
    conn.commit()
    return len(rows)


def _reassign_player_references(cur, drop_id: str, keep_id: str) -> None:
    cur.execute(
        """
        UPDATE player_career_history AS incoming
        SET player_id = %(keep_id)s
        WHERE incoming.player_id = %(drop_id)s
          AND NOT EXISTS (
            SELECT 1
            FROM player_career_history AS existing
            WHERE existing.player_id = %(keep_id)s
              AND existing.club_id = incoming.club_id
              AND existing.start_date IS NOT DISTINCT FROM incoming.start_date
              AND existing.is_loan = incoming.is_loan
          )
        """,
        {'keep_id': keep_id, 'drop_id': drop_id},
    )
    cur.execute('DELETE FROM player_career_history WHERE player_id = %s', (drop_id,))

    cur.execute(
        'UPDATE answers SET player_id = %s WHERE player_id = %s',
        (keep_id, drop_id),
    )

    cur.execute(
        """
        INSERT INTO player_popularity (player_id, global_selection_count, updated_at)
        SELECT %(keep_id)s, COALESCE(SUM(global_selection_count), 0), NOW()
        FROM player_popularity
        WHERE player_id IN (%(keep_id)s, %(drop_id)s)
        ON CONFLICT (player_id) DO UPDATE SET
          global_selection_count = EXCLUDED.global_selection_count,
          updated_at = NOW()
        """,
        {'keep_id': keep_id, 'drop_id': drop_id},
    )
    cur.execute('DELETE FROM player_popularity WHERE player_id = %s', (drop_id,))

    cur.execute(
        """
        INSERT INTO rarity_stats (
          puzzle_cell_id, player_id, selection_count, usage_percentage, updated_at
        )
        SELECT puzzle_cell_id, %(keep_id)s, selection_count, usage_percentage, updated_at
        FROM rarity_stats
        WHERE player_id = %(drop_id)s
        ON CONFLICT (puzzle_cell_id, player_id) DO UPDATE SET
          selection_count = rarity_stats.selection_count + EXCLUDED.selection_count,
          updated_at = NOW()
        """,
        {'keep_id': keep_id, 'drop_id': drop_id},
    )
    cur.execute('DELETE FROM rarity_stats WHERE player_id = %s', (drop_id,))


def dedupe_players(conn) -> int:
    """Merge duplicate players that share identity_key. Returns number merged away."""
    merged = 0

    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT p.id, p.name, p.external_id, p.nationality_code, p.primary_position,
                   COUNT(c.id) AS career_count
            FROM players p
            LEFT JOIN player_career_history c ON c.player_id = p.id
            GROUP BY p.id, p.name, p.external_id, p.nationality_code, p.primary_position
            """
        )
        rows = cur.fetchall()

    groups: dict[str, list[tuple]] = {}
    for row in rows:
        key = player_identity_key(row[1])
        groups.setdefault(key, []).append(row)

    duplicate_groups = [items for items in groups.values() if len(items) > 1]
    if duplicate_groups:
        print(f'  Found {len(duplicate_groups)} duplicate identity group(s)...')

    with conn.cursor() as cur:
        for group_index, items in enumerate(duplicate_groups, start=1):
            clusters: list[list[tuple]] = []
            for item in items:
                placed = False
                for cluster in clusters:
                    if names_likely_same_person(cluster[0][1], item[1]):
                        cluster.append(item)
                        placed = True
                        break
                if not placed:
                    clusters.append([item])

            for cluster in clusters:
                identity_key = player_identity_key(cluster[0][1])
                if len(cluster) < 2:
                    cur.execute(
                        """
                        UPDATE players
                        SET identity_key = %s, updated_at = NOW()
                        WHERE id = %s AND (identity_key IS NULL OR identity_key = '')
                        """,
                        (identity_key, cluster[0][0]),
                    )
                    continue

                scored = sorted(
                    cluster,
                    key=lambda row: player_completeness_score(
                        name=row[1],
                        nationality_code=row[3],
                        primary_position=row[4],
                        career_count=int(row[5] or 0),
                    ),
                    reverse=True,
                )
                keep = scored[0]
                keep_id = str(keep[0])
                merged_name = keep[1]
                merged_external = keep[2]

                for drop in scored[1:]:
                    drop_id = str(drop[0])
                    merged_name = pick_preferred_name(merged_name, drop[1])
                    merged_external = pick_preferred_external_id(merged_external, drop[2])
                    _reassign_player_references(cur, drop_id, keep_id)
                    cur.execute('DELETE FROM players WHERE id = %s', (drop_id,))
                    merged += 1

                cur.execute(
                    """
                    UPDATE players
                    SET name = %s,
                        normalized_name = %s,
                        identity_key = %s,
                        external_id = COALESCE(%s, external_id),
                        nationality_code = COALESCE(%s, nationality_code),
                        primary_position = COALESCE(%s, primary_position),
                        updated_at = NOW()
                    WHERE id = %s
                    """,
                    (
                        merged_name,
                        normalize_name(merged_name),
                        identity_key,
                        merged_external,
                        keep[3],
                        keep[4],
                        keep_id,
                    ),
                )

            if group_index % 100 == 0:
                conn.commit()
                print(f'  Dedupe progress: {group_index}/{len(duplicate_groups)} groups...')

    conn.commit()
    return merged


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
