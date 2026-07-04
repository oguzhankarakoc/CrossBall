"""Download Kaggle football datasets (requires Kaggle API credentials)."""

from __future__ import annotations

import shutil
import subprocess
import zipfile
from pathlib import Path

# Free SoFIFA-style exports — newest first; failures on optional sources are non-fatal.
KAGGLE_SOURCES: list[tuple[str, str | None]] = [
    ('stefanoleone992/ea-sports-fc-24-complete-player-dataset', None),
    ('stefanoleone992/fifa-23-complete-player-dataset', 'male_players (legacy).csv'),
]


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
    """Download and unzip Kaggle datasets. Returns path containing CSV files."""
    output_dir.mkdir(parents=True, exist_ok=True)

    if shutil.which('kaggle') is None:
        raise RuntimeError(
            'Kaggle CLI not found. Install: pip install kaggle\n'
            'Then configure ~/.kaggle/kaggle.json (API token from kaggle.com/settings)'
        )

    downloaded = 0
    errors: list[str] = []

    for dataset, file_name in KAGGLE_SOURCES:
        label = f'{dataset}' + (f' ({file_name})' if file_name else '')
        print(f'  Downloading {label} ...')
        if file_name:
            cmd = [
                'kaggle', 'datasets', 'download',
                '-d', dataset,
                '-f', file_name,
                '-p', str(output_dir),
                '--unzip',
            ]
        else:
            cmd = [
                'kaggle', 'datasets', 'download',
                '-d', dataset,
                '-p', str(output_dir),
                '--unzip',
            ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            errors.append(f'{label}: {result.stderr or result.stdout}')
            print(f'  Skipped {label} (not available or terms not accepted)')
            continue
        downloaded += 1

    csv_files = _extract_csvs(output_dir)
    if not csv_files:
        detail = '\n'.join(errors) if errors else 'No CSV files found'
        raise RuntimeError(f'Kaggle download failed:\n{detail}')

    print(f'  Downloaded {downloaded} dataset(s), {len(csv_files)} CSV file(s) in {output_dir}')
    return output_dir
