"""Tests for API-Football HTTP client."""

from __future__ import annotations

import json
from unittest.mock import MagicMock, patch

import pytest

from pipeline.api_football_client import (
    ApiFootballClient,
    ApiFootballError,
    is_auth_error,
    is_quota_error,
)


def test_is_quota_error_detects_request_limit_message():
    exc = ApiFootballError('API errors: {"requests": "request limit for the day"}')
    assert is_quota_error(exc) is True


def test_is_auth_error_detects_http_401():
    exc = ApiFootballError('HTTP 401 for url', status_code=401)
    assert is_auth_error(exc) is True


def test_get_uses_cache_without_live_request(tmp_path):
    client = ApiFootballClient(api_key='test-key', cache_dir=tmp_path)
    cache_key = '/transfers?team=529'
    payload = {'response': [{'player': {'id': 1, 'name': 'Test Player'}}], 'errors': []}
    client._write_cache(cache_key, payload)

    result = client.get('/transfers', params={'team': 529}, use_cache=True)

    assert result == payload
    assert client.requests_made == 0
    assert client.requests_from_cache == 1


def test_get_raises_on_payload_errors(tmp_path):
    client = ApiFootballClient(api_key='test-key', cache_dir=tmp_path)

    with patch.object(client, '_request_live', return_value=('{"errors": {"requests": "limit"}}', {})):
        with pytest.raises(ApiFootballError):
            client.get('/transfers', params={'team': 529}, use_cache=False)

    assert client.quota_exhausted is True


def test_get_cache_only_raises_on_cache_miss(tmp_path):
    client = ApiFootballClient(api_key='test-key', cache_dir=tmp_path)

    with pytest.raises(ApiFootballError, match='live API calls are disabled'):
        client.get('/transfers', params={'team': 529}, use_cache=True, allow_live=False)


def test_fetch_status_sets_remaining_daily(tmp_path):
    client = ApiFootballClient(api_key='test-key', cache_dir=tmp_path)
    body = json.dumps({
        'response': {
            'requests': {'current': 12, 'limit_day': 100},
            'subscription': {'plan': 'Free', 'active': True},
        },
        'errors': [],
    })

    with patch.object(client, '_request_live', return_value=(body, {})):
        status = client.fetch_status(use_cache=False)

    assert status['subscription']['plan'] == 'Free'
    assert client.remaining_daily == 88
