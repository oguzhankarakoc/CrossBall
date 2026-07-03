"""Download Kaggle football dataset (requires Kaggle API credentials)."""

from __future__ import annotations

import shutil
import subprocess
import zipfile
from pathlib import Path

# SoFIFA-style multi-year career data (club_name, club_joined_date, etc.)
KAGGLE_DATASET = 'stefanoleone992/fifa-23-complete-player-dataset'
KAGGLE_FILE = 'male_players (legacy).csv'


def _extract_csvs(output_dir: Path) -> list[Path]:
    for item in list(output_dir.iterdir()):
        if not item.is_file():
            continue
        try:
            with zipfile.ZipFile(item, 'r') as zf:
                zf.extractall(output_dir)
        except zipfile.BadZipFile:
            continue

    csv_files = [
        path for path in output_dir.glob('**/*.csv')
        if not zipfile.is_zipfile(path)
    ]
    return csv_files


def fetch_kaggle_dataset(output_dir: Path) -> Path:
    """Download and unzip Kaggle dataset. Returns path containing CSV files."""
    output_dir.mkdir(parents=True, exist_ok=True)

    if shutil.which('kaggle') is None:
        raise RuntimeError(
            'Kaggle CLI not found. Install: pip install kaggle\n'
            'Then configure ~/.kaggle/kaggle.json (API token from kaggle.com/settings)'
        )

    print(f'  Downloading {KAGGLE_DATASET} ({KAGGLE_FILE}) ...')
    result = subprocess.run(
        [
            'kaggle', 'datasets', 'download',
            '-d', KAGGLE_DATASET,
            '-f', KAGGLE_FILE,
            '-p', str(output_dir),
            '--unzip',
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f'Kaggle download failed:\n{result.stderr or result.stdout}')

    csv_files = _extract_csvs(output_dir)
    if not csv_files:
        raise RuntimeError(f'No CSV files found in {output_dir} after download')

    print(f'  Downloaded {len(csv_files)} CSV file(s) to {output_dir}')
    return output_dir
