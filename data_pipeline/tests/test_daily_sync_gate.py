from unittest.mock import MagicMock, patch

from pipeline.__main__ import cmd_daily_sync_gate


def test_daily_sync_gate_proceed_when_no_rollout():
    conn = MagicMock()
    cursor = MagicMock()
    cursor.fetchone.side_effect = [None, None]
    conn.cursor.return_value.__enter__.return_value = cursor

    with patch('pipeline.__main__.get_connection', return_value=conn):
        with patch('builtins.print') as mock_print:
            cmd_daily_sync_gate()
            mock_print.assert_called_once_with('PROCEED')


def test_daily_sync_gate_skip_when_rollout_ready():
    conn = MagicMock()
    cursor = MagicMock()
    cursor.fetchone.return_value = ('ready',)
    conn.cursor.return_value.__enter__.return_value = cursor

    with patch('pipeline.__main__.get_connection', return_value=conn):
        with patch('builtins.print') as mock_print:
            cmd_daily_sync_gate()
            mock_print.assert_called_once_with('SKIP')


def test_daily_sync_gate_skip_when_puzzle_exists():
    conn = MagicMock()
    cursor = MagicMock()
    cursor.fetchone.side_effect = [('generating',), (1,)]
    conn.cursor.return_value.__enter__.return_value = cursor

    with patch('pipeline.__main__.get_connection', return_value=conn):
        with patch('builtins.print') as mock_print:
            cmd_daily_sync_gate()
            mock_print.assert_called_once_with('SKIP')
