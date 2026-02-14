"""CSV serialization and deserialization for level grids.

File format
-----------
Line 1:  ``# theme:<theme_name>``   (comment header with theme metadata)
Line 2+: One CSV row per grid row.  Each cell is the integer value of a
          :class:`TileType`.

Example (4x4 grid)::

    # theme:dungeon
    1,1,1,1
    1,3,2,1
    1,2,4,1
    1,1,1,1
"""

from __future__ import annotations

import csv
import os
from pathlib import Path
from typing import Union

from level_generator.level import Level, TileType


def save_level_csv(level: Level, path: Union[str, Path]) -> None:
    """Write a :class:`Level` to a CSV file."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with open(path, "w", newline="") as fh:
        fh.write(f"# theme:{level.theme_name}\n")
        writer = csv.writer(fh)
        for row in level.grid:
            writer.writerow([int(t) for t in row])


def load_level_csv(path: Union[str, Path]) -> Level:
    """Read a :class:`Level` from a CSV file.

    Raises
    ------
    FileNotFoundError
        If *path* does not exist.
    ValueError
        If the file is empty or has inconsistent row lengths.
    """
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(f"Level CSV not found: {path}")

    theme_name = "default"
    grid_rows: list[list[TileType]] = []

    with open(path, "r", newline="") as fh:
        for line in fh:
            stripped = line.strip()
            if not stripped:
                continue
            # Parse comment header
            if stripped.startswith("#"):
                if stripped.startswith("# theme:"):
                    theme_name = stripped.split(":", 1)[1].strip()
                continue
            # Parse data row
            cells = stripped.split(",")
            grid_rows.append([TileType.from_value(int(c.strip())) for c in cells])

    if not grid_rows:
        raise ValueError(f"Level CSV is empty: {path}")

    height = len(grid_rows)
    width = len(grid_rows[0])
    for i, row in enumerate(grid_rows):
        if len(row) != width:
            raise ValueError(
                f"Inconsistent row length at line {i + 1}: "
                f"expected {width}, got {len(row)}"
            )

    level = Level(width=width, height=height, theme_name=theme_name)
    level.grid = grid_rows

    # Reconstruct entry / exit metadata from the grid
    for r in range(height):
        for c in range(width):
            if grid_rows[r][c] == TileType.ENTRY:
                level.entry = (r, c)
            elif grid_rows[r][c] == TileType.EXIT:
                level.exits.append((r, c))

    return level
