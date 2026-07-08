"""Close stale/open career stints when newer club transfers are known."""

from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime
from typing import Any


def parse_career_date(value: str | None) -> date | None:
    if not value:
        return None
    text = str(value).strip()[:10]
    if len(text) != 10 or text[4] != '-':
        return None
    try:
        return date.fromisoformat(text)
    except ValueError:
        return None


def format_career_date(value: date) -> str:
    return value.isoformat()


def is_open_ended(end_date: str | None, *, today: date | None = None) -> bool:
    parsed = parse_career_date(end_date)
    if parsed is None:
        return True
    ref = today or date.today()
    # SoFIFA often uses far-future contract end dates for active players.
    return parsed >= date(ref.year + 1, 1, 1)


def reconcile_player_stints(stints: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Close overlapping open stints when a later stint at another club starts."""
    if len(stints) <= 1:
        return [dict(row) for row in stints]

    ordered = sorted(
        [dict(row) for row in stints],
        key=lambda row: parse_career_date(row.get('start_date')) or date.max,
    )

    for index, incoming in enumerate(ordered):
        incoming_start = parse_career_date(incoming.get('start_date'))
        if incoming_start is None:
            continue

        for prior in ordered[:index]:
            if prior.get('team') == incoming.get('team'):
                continue
            prior_start = parse_career_date(prior.get('start_date'))
            if prior_start and prior_start >= incoming_start:
                continue

            prior_end = parse_career_date(prior.get('end_date'))
            if prior_end and prior_end <= incoming_start:
                continue

            prior['end_date'] = format_career_date(incoming_start)
            prior['source'] = prior.get('source') or 'enrichment_reconcile'

    return ordered


def reconcile_career_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        player_id = str(row.get('id', '')).strip()
        if not player_id:
            continue
        grouped[player_id].append(dict(row))

    merged: list[dict[str, Any]] = []
    for player_id in sorted(grouped):
        merged.extend(reconcile_player_stints(grouped[player_id]))
    return merged


def stint_key(row: dict[str, Any]) -> tuple[str, str, str, str, str]:
    return (
        str(row.get('id', '')),
        str(row.get('team', '')),
        str(row.get('start_date') or ''),
        str(row.get('is_loan', 'false')).lower(),
        str(row.get('source') or ''),
    )


def diff_enrichment_rows(
    base_rows: list[dict[str, Any]],
    reconciled_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Return rows that should be applied as patches (new stints or end_date fixes)."""
    base_index = {
        (r['id'], r['team'], r.get('start_date') or '', str(r.get('is_loan', 'false')).lower()): r
        for r in base_rows
    }
    deltas: list[dict[str, Any]] = []
    seen: set[tuple[str, str, str, str]] = set()

    for row in reconciled_rows:
        key = (
            str(row['id']),
            str(row['team']),
            str(row.get('start_date') or ''),
            str(row.get('is_loan', 'false')).lower(),
        )
        if key in seen:
            continue
        seen.add(key)

        base = base_index.get(key)
        if base is None:
            deltas.append(dict(row))
            continue

        base_end = (base.get('end_date') or '').strip()
        new_end = (row.get('end_date') or '').strip()
        if base_end != new_end:
            patched = dict(row)
            patched['source'] = row.get('source') or 'enrichment_reconcile'
            deltas.append(patched)

    return deltas
