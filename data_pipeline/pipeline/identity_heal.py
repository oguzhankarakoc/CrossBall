"""Audit and heal player identity clusters (duplicates + false merges).

Why this exists
---------------
`identity_key` soft-groups Kaggle/API name variants so validate/search share careers.
Two failure modes:

1. **Under-merge** — "Philippe Coutinho" vs "Philippe Coutinho Correia" get different
   keys (`coutinho|p` vs `correia|p`) → search hides Inter, Match Grid confuses users.
2. **Over-merge** — Iberian surnames collide (`perez|a` = 6 different people) →
   `player_identity_group_ids` leaks careers across unrelated players.

Heal strategy (safe, reversible soft keys + existing hard dedupe):
- Split false clusters onto unique keys (`base#uuid8`)
- Unify high-confidence legal-name variants onto one key
- Run `dedupe_players` to hard-merge true duplicates (FK reassign + delete)
"""

from __future__ import annotations

import csv
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from .load import (
    _reassign_player_references,
    dedupe_players,
    refresh_club_relationships,
    refresh_intersections,
)
from .normalize import normalize_name
from .player_identity import (
    names_likely_same_person,
    pick_preferred_external_id,
    pick_preferred_name,
    player_completeness_score,
    player_identity_key,
)


REPORTS_DIR = Path('reports')


@dataclass(frozen=True)
class PlayerRow:
    id: str
    name: str
    identity_key: str | None
    nationality_code: str | None
    primary_position: str | None
    career_count: int
    external_id: str | None = None

    @property
    def key(self) -> str:
        return (self.identity_key or '').strip() or player_identity_key(self.name)


def _significant_tokens(name: str) -> list[str]:
    from .player_identity import _SURNAME_PARTICLES, _prepare_name_for_identity

    parts = [p for p in _prepare_name_for_identity(name).split() if p]
    return [p for p in parts if p.lower() not in _SURNAME_PARTICLES]


def names_are_legal_variants(left: str, right: str) -> bool:
    """True when one display name is a legal-name expansion of the other.

    Examples:
      Philippe Coutinho ↔ Philippe Coutinho Correia
      Vinícius Júnior ↔ Vinícius José Paixão de Oliveira Júnior
      Cristiano Ronaldo ↔ Cristiano Ronaldo dos Santos Aveiro
    """
    if names_likely_same_person(left, right):
        return True

    left_n = normalize_name(left)
    right_n = normalize_name(right)
    if not left_n or not right_n:
        return False
    if left_n == right_n:
        return True

    left_tokens = _significant_tokens(left)
    right_tokens = _significant_tokens(right)
    if not left_tokens or not right_tokens:
        return False

    # First names must match or be initial-compatible
    lf, rf = left_tokens[0], right_tokens[0]
    if lf[0] != rf[0]:
        return False
    if lf != rf and not (
        len(lf) == 1
        or len(rf) == 1
        or lf.startswith(rf[:3])
        or rf.startswith(lf[:3])
    ):
        return False

    shorter_tokens, longer_tokens = (
        (left_tokens, right_tokens)
        if len(left_tokens) <= len(right_tokens)
        else (right_tokens, left_tokens)
    )
    # Every significant token of the shorter name appears in the longer
    longer_set = set(longer_tokens)
    if not all(t in longer_set for t in shorter_tokens):
        return False
    # Need at least first + one more shared token
    if len(shorter_tokens) >= 2:
        return True
    return player_identity_key(left) == player_identity_key(right)


def _cluster_same_person(players: list[PlayerRow]) -> list[list[PlayerRow]]:
    clusters: list[list[PlayerRow]] = []
    for player in players:
        placed = False
        for cluster in clusters:
            if names_are_legal_variants(cluster[0].name, player.name):
                cluster.append(player)
                placed = True
                break
        if not placed:
            clusters.append([player])
    return clusters


def _fetch_players(conn) -> list[PlayerRow]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT p.id::text, p.name, p.identity_key, p.nationality_code,
                   p.primary_position, COUNT(c.id) AS career_count, p.external_id
            FROM players p
            LEFT JOIN player_career_history c ON c.player_id = p.id
            GROUP BY p.id, p.name, p.identity_key, p.nationality_code,
                     p.primary_position, p.external_id
            """
        )
        rows = cur.fetchall()
    return [
        PlayerRow(
            id=r[0],
            name=r[1],
            identity_key=r[2],
            nationality_code=r[3],
            primary_position=r[4],
            career_count=int(r[5] or 0),
            external_id=r[6],
        )
        for r in rows
    ]


def find_false_clusters(players: list[PlayerRow]) -> list[dict]:
    """identity_key groups that contain more than one real person."""
    by_key: dict[str, list[PlayerRow]] = defaultdict(list)
    for p in players:
        if p.key:
            by_key[p.key].append(p)

    findings: list[dict] = []
    for key, members in by_key.items():
        if len(members) < 2:
            continue
        sub = _cluster_same_person(members)
        if len(sub) <= 1:
            continue
        findings.append({
            'identity_key': key,
            'member_count': len(members),
            'person_count': len(sub),
            'names': ' | '.join(sorted({m.name for m in members})),
            'subcluster_sizes': ','.join(str(len(s)) for s in sub),
        })
    findings.sort(key=lambda r: (-r['person_count'], -r['member_count'], r['identity_key']))
    return findings


def find_merge_candidates(
    players: list[PlayerRow],
    *,
    career_clubs: dict[str, set[str]] | None = None,
) -> list[dict]:
    """Different identity_keys that look like the same person (legal-name variants).

    Requires career-club overlap when both players have careers — blocks weak
    prefix collisions like "Daniel James" ⊂ "Daniel James Grimshaw".
    """
    career_clubs = career_clubs or {}

    buckets: dict[tuple[str, str], list[PlayerRow]] = defaultdict(list)
    for p in players:
        tokens = _significant_tokens(p.name)
        if not tokens:
            continue
        nat = (p.nationality_code or '').upper() or '_'
        buckets[(nat, tokens[0][0])].append(p)

    findings: list[dict] = []
    seen_pairs: set[tuple[str, str]] = set()

    for group in buckets.values():
        if len(group) < 2:
            continue
        for i, a in enumerate(group):
            for b in group[i + 1 :]:
                if a.key == b.key and a.key:
                    continue
                if (
                    a.nationality_code
                    and b.nationality_code
                    and a.nationality_code.upper() != b.nationality_code.upper()
                ):
                    continue
                if not names_are_legal_variants(a.name, b.name):
                    continue

                clubs_a = career_clubs.get(a.id, set())
                clubs_b = career_clubs.get(b.id, set())
                if clubs_a and clubs_b and clubs_a.isdisjoint(clubs_b):
                    # Both have careers but no shared club → different people.
                    continue
                if not clubs_a and not clubs_b:
                    # No career evidence — only allow strict same-person key match.
                    if not names_likely_same_person(a.name, b.name):
                        continue

                pair = tuple(sorted((a.id, b.id)))
                if pair in seen_pairs:
                    continue
                seen_pairs.add(pair)
                keep, drop = (a, b) if a.career_count >= b.career_count else (b, a)
                findings.append({
                    'keep_name': keep.name,
                    'drop_name': drop.name,
                    'keep_id': keep.id,
                    'drop_id': drop.id,
                    'keep_key': keep.key,
                    'drop_key': drop.key,
                    'nationality': keep.nationality_code or drop.nationality_code or '',
                    'careers': f'{keep.career_count}+{drop.career_count}',
                    'shared_clubs': len(clubs_a & clubs_b) if clubs_a and clubs_b else 0,
                })

    findings.sort(key=lambda r: r['keep_name'])
    return findings


def _fetch_career_clubs(conn) -> dict[str, set[str]]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT player_id::text, club_id::text
            FROM player_career_history
            WHERE is_senior = TRUE AND is_youth = FALSE AND is_reserve = FALSE
            """
        )
        out: dict[str, set[str]] = defaultdict(set)
        for player_id, club_id in cur.fetchall():
            out[player_id].add(club_id)
        return out


def _write_csv(path: Path, rows: list[dict], fieldnames: Iterable[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=list(fieldnames))
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def run_identity_audit(conn, reports_dir: Path = REPORTS_DIR) -> dict:
    players = _fetch_players(conn)
    career_clubs = _fetch_career_clubs(conn)
    false_clusters = find_false_clusters(players)
    merge_candidates = find_merge_candidates(players, career_clubs=career_clubs)

    false_path = reports_dir / 'identity_false_clusters.csv'
    merge_path = reports_dir / 'identity_merge_candidates.csv'
    _write_csv(
        false_path,
        false_clusters,
        ['identity_key', 'member_count', 'person_count', 'subcluster_sizes', 'names'],
    )
    _write_csv(
        merge_path,
        merge_candidates,
        [
            'keep_name',
            'drop_name',
            'keep_id',
            'drop_id',
            'keep_key',
            'drop_key',
            'nationality',
            'careers',
            'shared_clubs',
        ],
    )

    return {
        'players': len(players),
        'false_clusters': len(false_clusters),
        'merge_candidates': len(merge_candidates),
        'false_path': str(false_path),
        'merge_path': str(merge_path),
    }


def split_false_clusters(conn, players: list[PlayerRow] | None = None) -> int:
    """Give each real person inside a colliding identity_key a unique key."""
    players = players or _fetch_players(conn)
    by_key: dict[str, list[PlayerRow]] = defaultdict(list)
    for p in players:
        if p.key:
            by_key[p.key].append(p)

    updates: list[tuple[str, str]] = []
    for key, members in by_key.items():
        if len(members) < 2:
            continue
        subclusters = _cluster_same_person(members)
        if len(subclusters) <= 1:
            continue
        for cluster in subclusters:
            keep = max(
                cluster,
                key=lambda p: player_completeness_score(
                    name=p.name,
                    nationality_code=p.nationality_code,
                    primary_position=p.primary_position,
                    career_count=p.career_count,
                ),
            )
            # Unique per person; still human-readable for debugging.
            new_key = f'{player_identity_key(keep.name)}#{keep.id[:8]}'
            for member in cluster:
                if member.key != new_key:
                    updates.append((new_key, member.id))

    if not updates:
        return 0

    with conn.cursor() as cur:
        for index in range(0, len(updates), 500):
            cur.executemany(
                """
                UPDATE players
                SET identity_key = %s, updated_at = NOW()
                WHERE id = %s::uuid
                """,
                updates[index : index + 500],
            )
    conn.commit()
    return len(updates)


def unify_merge_candidates(conn, candidates: list[dict] | None = None) -> int:
    """Point legal-name variants at the same identity_key (soft unify before hard dedupe)."""
    players = _fetch_players(conn)
    by_id = {p.id: p for p in players}
    career_clubs = _fetch_career_clubs(conn)
    candidates = (
        candidates
        if candidates is not None
        else find_merge_candidates(players, career_clubs=career_clubs)
    )

    updates: list[tuple[str, str]] = []
    for row in candidates:
        keep = by_id.get(row['keep_id'])
        drop = by_id.get(row['drop_id'])
        if not keep or not drop:
            continue
        target_key = player_identity_key(keep.name)
        if keep.key != target_key:
            updates.append((target_key, keep.id))
        if drop.key != target_key:
            updates.append((target_key, drop.id))

    if not updates:
        return 0

    latest: dict[str, str] = {}
    for key, pid in updates:
        latest[pid] = key
    payload = [(key, pid) for pid, key in latest.items()]

    with conn.cursor() as cur:
        for index in range(0, len(payload), 500):
            cur.executemany(
                """
                UPDATE players
                SET identity_key = %s, updated_at = NOW()
                WHERE id = %s::uuid
                """,
                payload[index : index + 500],
            )
    conn.commit()
    return len(payload)


def hard_merge_candidates(conn, candidates: list[dict] | None = None) -> int:
    """Hard-merge legal-name variant pairs (FK reassign + delete drop rows)."""
    players = _fetch_players(conn)
    by_id = {p.id: p for p in players}
    career_clubs = _fetch_career_clubs(conn)
    candidates = (
        candidates
        if candidates is not None
        else find_merge_candidates(players, career_clubs=career_clubs)
    )

    merged = 0
    # Also merge any DB identity_key groups that are a single real person with 2+ rows
    by_key: dict[str, list[PlayerRow]] = defaultdict(list)
    for p in players:
        if p.key:
            by_key[p.key].append(p)

    pairs: list[tuple[PlayerRow, PlayerRow]] = []
    for row in candidates:
        keep = by_id.get(row['keep_id'])
        drop = by_id.get(row['drop_id'])
        if keep and drop and keep.id != drop.id:
            pairs.append((keep, drop))

    for key, members in by_key.items():
        if len(members) < 2:
            continue
        sub = _cluster_same_person(members)
        if len(sub) != 1:
            continue
        cluster = sorted(
            sub[0],
            key=lambda p: player_completeness_score(
                name=p.name,
                nationality_code=p.nationality_code,
                primary_position=p.primary_position,
                career_count=p.career_count,
            ),
            reverse=True,
        )
        keep = cluster[0]
        for drop in cluster[1:]:
            pairs.append((keep, drop))

    # Collapse transitive pairs onto highest-scoring keep
    dropped: set[str] = set()
    with conn.cursor() as cur:
        for keep, drop in pairs:
            if keep.id in dropped or drop.id in dropped:
                continue
            if keep.id == drop.id:
                continue
            # Refresh keep fields
            merged_name = pick_preferred_name(keep.name, drop.name)
            merged_external = pick_preferred_external_id(keep.external_id, drop.external_id)
            _reassign_player_references(cur, drop.id, keep.id)
            cur.execute('DELETE FROM players WHERE id = %s::uuid', (drop.id,))
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
                WHERE id = %s::uuid
                """,
                (
                    merged_name,
                    normalize_name(merged_name),
                    player_identity_key(merged_name),
                    merged_external,
                    keep.nationality_code or drop.nationality_code,
                    keep.primary_position or drop.primary_position,
                    keep.id,
                ),
            )
            dropped.add(drop.id)
            merged += 1
    conn.commit()
    return merged


def run_identity_heal(conn, *, apply: bool, reports_dir: Path = REPORTS_DIR) -> dict:
    """Audit always; when apply=True, split → unify → hard merge → refresh views."""
    audit = run_identity_audit(conn, reports_dir=reports_dir)
    result = {
        **audit,
        'applied': False,
        'split_updates': 0,
        'unify_updates': 0,
        'hard_merged': 0,
    }
    if not apply:
        return result

    players = _fetch_players(conn)
    split_n = split_false_clusters(conn, players)
    # Capture candidates before unify mutates keys
    career_clubs = _fetch_career_clubs(conn)
    candidates = find_merge_candidates(_fetch_players(conn), career_clubs=career_clubs)
    unify_n = unify_merge_candidates(conn, candidates=candidates)
    hard_n = hard_merge_candidates(conn, candidates=candidates)
    # Legacy pass for same computed-key duplicates
    hard_n += dedupe_players(conn)
    refresh_intersections(conn)
    refresh_club_relationships(conn)

    post = run_identity_audit(conn, reports_dir=reports_dir)
    result.update({
        'applied': True,
        'split_updates': split_n,
        'unify_updates': unify_n,
        'hard_merged': hard_n,
        'false_clusters_after': post['false_clusters'],
        'merge_candidates_after': post['merge_candidates'],
    })
    return result
