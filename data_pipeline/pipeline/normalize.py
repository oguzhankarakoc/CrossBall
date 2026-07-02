"""Normalize player and club names for search and deduplication."""

import re
from unidecode import unidecode

YOUTH_PATTERNS = re.compile(
    r'\b(U\d{2}|Youth|Junior|B\s*Team|Reserve|II|Amateur)\b',
    re.IGNORECASE,
)


def normalize_name(name: str) -> str:
    """Accent-insensitive lowercase normalization."""
    cleaned = unidecode(name.strip())
    cleaned = re.sub(r'[^a-zA-Z0-9\s]', '', cleaned)
    return cleaned.lower().strip()


def slugify(name: str) -> str:
    """URL-safe club slug."""
    slug = normalize_name(name)
    return re.sub(r'\s+', '-', slug)


def is_youth_or_reserve(team_name: str) -> bool:
    """Detect youth, reserve, or B team entries."""
    return bool(YOUTH_PATTERNS.search(team_name))
