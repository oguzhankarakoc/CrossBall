"""Build reconciled career patch deltas from base data + API/manual patches."""

from __future__ import annotations

from pathlib import Path

from .api_football_sync import (
    DEFAULT_OUTPUT as API_FOOTBALL_OUTPUT,
    load_team_id_map,
    sync_transfers_to_career_rows,
    write_career_csv,
)
from .career_gap_report import detect_career_gaps, load_base_career_rows, write_gap_report
from .career_patches import (
    DEFAULT_PATCHES_PATH,
    load_all_career_patches,
    merge_career_patches,
)
from .career_reconcile import diff_enrichment_rows, reconcile_career_rows

DEFAULT_PLAYERS_CSV = Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'players.csv'
DEFAULT_ENRICHED_PATH = (
    Path(__file__).resolve().parents[1] / 'data' / 'raw' / 'patches' / 'enriched_careers.csv'
)
DEFAULT_GAP_REPORT = Path(__file__).resolve().parents[2] / 'reports' / 'career_gaps.csv'


def build_enriched_career_rows(
    *,
    players_csv: Path | None = None,
    manual_patches_path: Path | None = None,
    api_patches_path: Path | None = None,
    enriched_patches_path: Path | None = None,
) -> tuple[list[dict], list[dict]]:
    """Merge base + patches, reconcile overlaps, return (deltas, full_reconciled)."""
    base_path = players_csv or DEFAULT_PLAYERS_CSV
    base_rows = load_base_career_rows(base_path)
    patch_rows = load_all_career_patches(
        manual_patches_path,
        api_patches_path,
        enriched_patches_path,
    )

    merged, _ = merge_career_patches(base_rows, patch_rows)
    reconciled = reconcile_career_rows(merged)
    deltas = diff_enrichment_rows(base_rows, reconciled)
    return deltas, reconciled


def sync_api_football_careers(
    *,
    players_csv: Path | None = None,
    offset: int = 0,
    limit: int | None = None,
    use_cache: bool = True,
    cache_only: bool = False,
    min_remaining: int | None = None,
    output_path: Path | None = None,
) -> dict[str, int | str]:
    team_map = load_team_id_map()
    if limit is None:
        limit = len(team_map)

    rows, stats = sync_transfers_to_career_rows(
        team_map=team_map,
        offset=offset,
        limit=limit,
        use_cache=use_cache,
        cache_only=cache_only,
        min_remaining=min_remaining,
        players_csv=players_csv or DEFAULT_PLAYERS_CSV,
    )
    target = output_path or API_FOOTBALL_OUTPUT
    preserved = not write_career_csv(rows, target, preserve_existing=True)
    summary = {key: int(value or 0) for key, value in stats.items()}  # type: ignore[arg-type]
    summary['csv_preserved'] = int(preserved)
    summary['output'] = str(target)
    if (
        not rows
        and int(stats.get('teams_ok', 0) or 0) == 0
        and int(stats.get('cache_hits', 0) or 0) == 0
    ):
        summary['api_warning'] = (
            'API-Football sync produced no rows; using existing patch CSV if available.'
        )
    return summary


def run_career_enrichment(
    *,
    players_csv: Path | None = None,
    enriched_output: Path | None = None,
    gap_report_output: Path | None = None,
    skip_api_sync: bool = False,
    api_offset: int = 0,
    api_limit: int | None = None,
    use_cache: bool = True,
    cache_only: bool = False,
    min_remaining: int | None = None,
) -> dict[str, int | str]:
    players_path = players_csv or DEFAULT_PLAYERS_CSV
    enriched_path = enriched_output or DEFAULT_ENRICHED_PATH
    gap_path = gap_report_output or DEFAULT_GAP_REPORT

    summary: dict[str, int | str] = {}

    if not skip_api_sync:
        api_stats = sync_api_football_careers(
            players_csv=players_path,
            offset=api_offset,
            limit=api_limit,
            use_cache=use_cache,
            cache_only=cache_only,
            min_remaining=min_remaining,
        )
        summary.update({f'api_{key}': value for key, value in api_stats.items()})
        warning = api_stats.get('api_warning')
        if warning:
            print(f'  WARNING: {warning}', flush=True)

    deltas, reconciled = build_enriched_career_rows(players_csv=players_path)
    write_career_csv(deltas, enriched_path)

    gaps = detect_career_gaps(players_csv=players_path)
    write_gap_report(gaps, gap_path)

    summary['base_rows'] = len(load_base_career_rows(players_path))
    summary['reconciled_rows'] = len(reconciled)
    summary['enriched_deltas'] = len(deltas)
    summary['gap_count'] = len(gaps)
    summary['enriched_output'] = str(enriched_path)
    summary['gap_report'] = str(gap_path)
    return summary
