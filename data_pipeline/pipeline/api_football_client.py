"""API-Football (api-sports.io) client — free tier: 100 req/day, 10 req/min."""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

BASE_URL = 'https://v3.football.api-sports.io'
DEFAULT_CACHE_DIR = Path(__file__).resolve().parents[1] / 'data' / 'cache' / 'api_football'
MIN_REQUEST_INTERVAL_SEC = 6.5  # stay under 10/min free tier


class ApiFootballError(RuntimeError):
    pass


class ApiFootballClient:
    def __init__(
        self,
        api_key: str | None = None,
        *,
        cache_dir: Path | None = None,
        cache_ttl_days: int = 30,
        min_interval_sec: float = MIN_REQUEST_INTERVAL_SEC,
    ) -> None:
        self.api_key = api_key or os.environ.get('API_FOOTBALL_KEY', '').strip()
        if not self.api_key:
            raise ApiFootballError(
                'API_FOOTBALL_KEY not set. Register free at https://www.api-football.com/ '
                'and add the key to data_pipeline/.env'
            )
        self.cache_dir = cache_dir or DEFAULT_CACHE_DIR
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.cache_ttl_days = cache_ttl_days
        self.min_interval_sec = min_interval_sec
        self._last_request_at = 0.0
        self.requests_made = 0
        self.requests_from_cache = 0
        self.remaining_daily: int | None = None

    def _cache_path(self, cache_key: str) -> Path:
        safe = cache_key.replace('/', '_').replace('?', '_')
        return self.cache_dir / f'{safe}.json'

    def _read_cache(self, cache_key: str) -> dict[str, Any] | None:
        path = self._cache_path(cache_key)
        if not path.is_file():
            return None
        age_days = (time.time() - path.stat().st_mtime) / 86400
        if age_days > self.cache_ttl_days:
            return None
        with path.open(encoding='utf-8') as f:
            self.requests_from_cache += 1
            return json.load(f)

    def _write_cache(self, cache_key: str, payload: dict[str, Any]) -> None:
        path = self._cache_path(cache_key)
        with path.open('w', encoding='utf-8') as f:
            json.dump(payload, f)

    def get(self, path: str, *, params: dict[str, Any] | None = None, use_cache: bool = True) -> dict[str, Any]:
        query = ''
        if params:
            query = '?' + '&'.join(f'{k}={v}' for k, v in params.items())
        cache_key = f'{path}{query}'

        if use_cache:
            cached = self._read_cache(cache_key)
            if cached is not None:
                return cached

        elapsed = time.time() - self._last_request_at
        if elapsed < self.min_interval_sec:
            time.sleep(self.min_interval_sec - elapsed)

        url = f'{BASE_URL}{path}{query}'
        req = urllib.request.Request(url, headers={'x-apisports-key': self.api_key})
        try:
            with urllib.request.urlopen(req, timeout=45) as resp:
                body = resp.read().decode()
                remaining = resp.headers.get('x-ratelimit-requests-remaining')
                if remaining is not None:
                    self.remaining_daily = int(remaining)
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode()[:500]
            raise ApiFootballError(f'HTTP {exc.code} for {url}: {detail}') from exc
        except urllib.error.URLError as exc:
            raise ApiFootballError(f'Network error for {url}: {exc}') from exc

        self._last_request_at = time.time()
        self.requests_made += 1

        payload = json.loads(body)
        errors = payload.get('errors') or {}
        if errors:
            raise ApiFootballError(f'API errors: {errors}')

        if use_cache:
            self._write_cache(cache_key, payload)
        return payload

    def transfers_for_team(self, team_id: int, *, use_cache: bool = True) -> list[dict[str, Any]]:
        payload = self.get('/transfers', params={'team': team_id}, use_cache=use_cache)
        return payload.get('response') or []
