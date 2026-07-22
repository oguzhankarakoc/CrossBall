"""One-shot career truth pass: gap report + enriched delta rebuild (no web scrape)."""

from __future__ import annotations

import csv
from pathlib import Path

from .api_football_sync import write_career_csv
from .career_enrichment import (
    DEFAULT_ENRICHED_PATH,
    DEFAULT_GAP_REPORT,
    DEFAULT_PLAYERS_CSV,
)
from .career_gap_report import (
    detect_career_gaps,
    load_base_career_rows,
    write_gap_report,
)
from .career_patches import (
    API_FOOTBALL_PATCHES_PATH,
    DEFAULT_PATCHES_PATH,
    load_all_career_patches,
    merge_career_patches,
)
from .career_reconcile import (
    diff_enrichment_rows,
    is_open_ended,
    reconcile_career_rows,
)

DEFAULT_TRUTH_REPORT = (
    Path(__file__).resolve().parents[2] / 'reports' / 'career_truth_pass.csv'
)


def run_career_truth_pass(
    *,
    players_csv: Path | None = None,
    enriched_output: Path | None = None,
    gap_report_output: Path | None = None,
    truth_report_output: Path | None = None,
) -> dict[str, int | str]:
    """Rebuild enriched deltas from base + curated/API patches and write reports.

    Does **not** call Google or scrape the web. Uses existing structured CSVs only.
    """
    players_path = players_csv or DEFAULT_PLAYERS_CSV
    enriched_path = enriched_output or DEFAULT_ENRICHED_PATH
    gap_path = gap_report_output or DEFAULT_GAP_REPORT
    truth_path = truth_report_output or DEFAULT_TRUTH_REPORT

    gaps = detect_career_gaps(
        players_csv=players_path,
        manual_patches_path=DEFAULT_PATCHES_PATH,
        api_patches_path=API_FOOTBALL_PATCHES_PATH,
    )
    write_gap_report(gaps, gap_path)

    base_rows = load_base_career_rows(players_path)
    patch_rows = load_all_career_patches(include_enriched=False)
    merged, _ = merge_career_patches(base_rows, patch_rows)
    reconciled = reconcile_career_rows(merged)
    deltas = diff_enrichment_rows(base_rows, reconciled)
    write_career_csv(deltas, enriched_path, preserve_existing=False)

    truth_path.parent.mkdir(parents=True, exist_ok=True)
    base_open = _open_clubs_from_rows(base_rows)
    recon_open = _open_clubs_from_rows(reconciled)
    rows_out: list[dict[str, str]] = []
    names = {str(r['id']): str(r['name']) for r in reconciled}
    for player_id, clubs in sorted(recon_open.items()):
        base = base_open.get(player_id, set())
        if clubs != base:
            rows_out.append(
                {
                    'external_id': player_id,
                    'name': names.get(player_id, player_id),
                    'base_open_clubs': '|'.join(sorted(base)),
                    'reconciled_open_clubs': '|'.join(sorted(clubs)),
                    'issue_type': 'current_club_updated',
                    'priority': '95',
                }
            )

    with truth_path.open('w', newline='', encoding='utf-8') as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                'external_id',
                'name',
                'base_open_clubs',
                'reconciled_open_clubs',
                'issue_type',
                'priority',
            ],
        )
        writer.writeheader()
        writer.writerows(rows_out)

    return {
        'gaps': len(gaps),
        'enriched_deltas': len(deltas),
        'reconciled_rows': len(reconciled),
        'current_club_updates': len(rows_out),
        'enriched_csv': str(enriched_path),
        'gap_report': str(gap_path),
        'truth_report': str(truth_path),
    }


def _open_clubs_from_rows(rows: list[dict]) -> dict[str, set[str]]:
    out: dict[str, set[str]] = {}
    for row in rows:
        if is_open_ended(row.get('end_date')):
            out.setdefault(str(row['id']), set()).add(str(row['team']))
    return out
