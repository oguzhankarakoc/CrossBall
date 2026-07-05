import os
from unittest.mock import patch

from pipeline.__main__ import _patch_load_light


def test_patch_load_light_env():
    with patch.dict(os.environ, {'PATCH_LOAD_LIGHT': '1'}, clear=False):
        assert _patch_load_light() is True
    with patch.dict(os.environ, {'PATCH_LOAD_LIGHT': '0'}, clear=False):
        assert _patch_load_light() is False
