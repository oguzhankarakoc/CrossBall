"""Stable player identity for cross-source deduplication (Kaggle, API-Football, patches)."""

from __future__ import annotations

import re

from .normalize import normalize_name


def _first_name_token(first: str) -> str:
    cleaned = first.rstrip('.')
    if not cleaned:
        return ''
    return cleaned[0]


def player_identity_key(name: str) -> str:
    """Surname + first-name token — groups 'Z. Ibrahimović' with 'Zlatan Ibrahimović'."""
    normalized = normalize_name(name)
    parts = [part for part in normalized.split() if part]
    if not parts:
        return normalized
    surname = parts[-1]
    if len(parts) == 1:
        return surname
    return f'{surname}|{_first_name_token(parts[0])}'


def names_likely_same_person(left: str, right: str) -> bool:
    if player_identity_key(left) != player_identity_key(right):
        return False

    left_parts = normalize_name(left).split()
    right_parts = normalize_name(right).split()
    if not left_parts or not right_parts:
        return False

    left_first = left_parts[0].rstrip('.')
    right_first = right_parts[0].rstrip('.')

    if left_first == right_first:
        return True
    if left_first and right_first and left_first[0] == right_first[0]:
        if len(left_first) == 1 or len(right_first) == 1:
            return True
        shorter, longer = (
            (left_first, right_first)
            if len(left_first) <= len(right_first)
            else (right_first, left_first)
        )
        if len(shorter) == 1:
            return longer.startswith(shorter)
        return shorter[:4] == longer[:4] or longer.startswith(shorter[:3])
    return False


def pick_preferred_name(left: str, right: str) -> str:
    """Prefer full display names over abbreviated API forms (e.g. 'Z. …' vs 'Zlatan …')."""
    left = left.strip()
    right = right.strip()
    if not left:
        return right
    if not right:
        return left

    left_parts = left.split()
    right_parts = right.split()
    left_initial_only = len(left_parts) > 0 and len(left_parts[0].rstrip('.')) <= 1
    right_initial_only = len(right_parts) > 0 and len(right_parts[0].rstrip('.')) <= 1

    if left_initial_only and not right_initial_only:
        return right
    if right_initial_only and not left_initial_only:
        return left
    return left if len(left) >= len(right) else right


def pick_preferred_external_id(left: str | None, right: str | None) -> str | None:
    """Prefer SoFIFA/Kaggle ids over ephemeral API-Football af-* ids."""
    left = (left or '').strip() or None
    right = (right or '').strip() or None
    if not left:
        return right
    if not right:
        return left

    left_af = left.startswith('af-')
    right_af = right.startswith('af-')
    if left_af and not right_af:
        return right
    if right_af and not left_af:
        return left
    return left


def pick_preferred_optional(left: str | None, right: str | None) -> str | None:
    left = (left or '').strip() or None
    right = (right or '').strip() or None
    return left or right


def player_completeness_score(
    *,
    name: str,
    nationality_code: str | None,
    primary_position: str | None,
    career_count: int = 0,
) -> int:
    score = career_count * 5
    if nationality_code:
        score += 20
    if primary_position:
        score += 10
    score += len(name)
    if not re.match(r'^[A-Z]\.\s', name):
        score += 15
    return score
