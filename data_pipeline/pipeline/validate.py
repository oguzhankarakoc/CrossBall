"""Validate data integrity before database load."""

from dataclasses import dataclass


@dataclass
class ValidationResult:
    valid: bool
    errors: list[str]
    warnings: list[str]


def validate_players(players: list[dict], clubs: list[dict]) -> ValidationResult:
    errors: list[str] = []
    warnings: list[str] = []

    club_ids = {c['id'] for c in clubs}
    seen_names: set[str] = set()

    for p in players:
        if not p.get('name'):
            errors.append(f"Player missing name: {p}")
            continue

        norm = p.get('normalized_name', '')
        if norm in seen_names:
            warnings.append(f"Duplicate normalized name: {norm}")
        seen_names.add(norm)

        for career in p.get('careers', []):
            if career.get('club_id') not in club_ids:
                errors.append(
                    f"Player {p['name']}: unknown club_id {career.get('club_id')}"
                )

    return ValidationResult(valid=len(errors) == 0, errors=errors, warnings=warnings)


def validate_puzzle_fairness(cell_answer_counts: list[int]) -> ValidationResult:
    errors: list[str] = []
    warnings: list[str] = []

    for i, count in enumerate(cell_answer_counts):
        if count < 3:
            errors.append(f"Cell {i}: only {count} valid answers (min 3)")
        elif count < 8:
            warnings.append(f"Cell {i}: {count} valid answers (ideal 8+)")

    return ValidationResult(valid=len(errors) == 0, errors=errors, warnings=warnings)
