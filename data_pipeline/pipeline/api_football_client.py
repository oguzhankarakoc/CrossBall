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
MAX_RETRIES = 2
RETRYABLE_HTTP_CODES = {429, 500, 502, 503, 504}


class ApiFootballError(RuntimeError):
    """Raised when API-Football returns an HTTP, network, or payload error."""

    def __init__(self, message: str, *, status_code: int | None = None) -> None:
        super().__init__(message)
        self.status_code = status_code


def is_quota_error(exc: ApiFootballError) -> bool:
    text = str(exc).lower()
    return any(
        token in text
        for token in (
            'request limit',
            'rate limit',
            'too many requests',
            'daily limit',
            'requests limit',
            "'requests'",
            '"requests"',
        )
    )


def is_auth_error(exc: ApiFootballError) -> bool:
    if exc.status_code in {401, 403}:
        return True
    text = str(exc).lower()
    return 'invalid' in text and 'key' in text


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
        self.last_error: str | None = None
        self.quota_exhausted = False

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

    def _throttle(self) -> None:
        elapsed = time.time() - self._last_request_at
        if elapsed < self.min_interval_sec:
            time.sleep(self.min_interval_sec - elapsed)

    def _request_live(self, url: str) -> tuple[str, dict[str, str]]:
        req = urllib.request.Request(url, headers={'x-apisports-key': self.api_key})
        try:
            with urllib.request.urlopen(req, timeout=45) as resp:
                body = resp.read().decode()
                headers = {key.lower(): value for key, value in resp.headers.items()}
                return body, headers
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode()[:500]
            raise ApiFootballError(
                f'HTTP {exc.code} for {url}: {detail}',
                status_code=exc.code,
            ) from exc
        except urllib.error.URLError as exc:
            raise ApiFootballError(f'Network error for {url}: {exc}') from exc

    def _parse_payload(self, body: str, *, url: str) -> dict[str, Any]:
        payload = json.loads(body)
        errors = payload.get('errors') or {}
        if errors:
            message = f'API errors for {url}: {errors}'
            error = ApiFootballError(message)
            self.last_error = message
            if is_quota_error(error):
                self.quota_exhausted = True
            raise error
        return payload

    def get(
        self,
        path: str,
        *,
        params: dict[str, Any] | None = None,
        use_cache: bool = True,
        allow_live: bool = True,
    ) -> dict[str, Any]:
        query = ''
        if params:
            query = '?' + '&'.join(f'{k}={v}' for k, v in params.items())
        cache_key = f'{path}{query}'
        url = f'{BASE_URL}{path}{query}'

        if use_cache:
            cached = self._read_cache(cache_key)
            if cached is not None:
                return cached

        if not allow_live:
            raise ApiFootballError(f'Cache miss for {cache_key} and live API calls are disabled')

        last_exc: ApiFootballError | None = None
        for attempt in range(MAX_RETRIES + 1):
            self._throttle()
            try:
                body, headers = self._request_live(url)
            except ApiFootballError as exc:
                last_exc = exc
                self.last_error = str(exc)
                if exc.status_code in RETRYABLE_HTTP_CODES and attempt < MAX_RETRIES:
                    time.sleep(self.min_interval_sec * (attempt + 1))
                    continue
                if is_quota_error(exc):
                    self.quota_exhausted = True
                raise

            self._last_request_at = time.time()
            self.requests_made += 1
            remaining = headers.get('x-ratelimit-requests-remaining')
            if remaining is not None:
                try:
                    self.remaining_daily = int(remaining)
                except ValueError:
                    pass

            try:
                payload = self._parse_payload(body, url=url)
            except ApiFootballError:
                raise

            if use_cache:
                self._write_cache(cache_key, payload)
            return payload

        if last_exc is not None:
            raise last_exc
        raise ApiFootballError(f'Failed to fetch {url}')

    def fetch_status(self, *, use_cache: bool = False) -> dict[str, Any]:
        """Return account/subscription/request quota from /status."""
        payload = self.get('/status', use_cache=use_cache, allow_live=True)
        response = payload.get('response') or {}
        requests_info = response.get('requests') or {}
        current = int(requests_info.get('current') or 0)
        limit_day = int(requests_info.get('limit_day') or 0)
        if limit_day:
            self.remaining_daily = max(limit_day - current, 0)
        return response

    def transfers_for_team(
        self,
        team_id: int,
        *,
        use_cache: bool = True,
        allow_live: bool = True,
    ) -> list[dict[str, Any]]:
        payload = self.get(
            '/transfers',
            params={'team': team_id},
            use_cache=use_cache,
            allow_live=allow_live,
        )
        return payload.get('response') or []
