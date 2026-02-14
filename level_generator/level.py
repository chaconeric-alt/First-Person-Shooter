"""Core data models for levels, tiles, and the map grid."""

from __future__ import annotations

import enum
from dataclasses import dataclass, field
from typing import Optional


class TileType(enum.IntEnum):
    """Types of tiles that can appear in the level grid.

    Integer values are used directly in CSV serialization.
    """

    VOID = 0       # Empty space outside the playable area
    WALL = 1       # Solid wall
    FLOOR = 2      # Walkable floor
    ENTRY = 3      # Player spawn / level entry
    EXIT = 4       # Level exit (at least one per map)
    DOOR = 5       # Doorway connecting rooms
    PILLAR = 6     # Structural pillar at wall intersections

    @classmethod
    def from_value(cls, value: int) -> "TileType":
        try:
            return cls(value)
        except ValueError:
            return cls.VOID


@dataclass
class Tile:
    """A single tile in the level grid."""

    tile_type: TileType
    mesh_id: Optional[str] = None       # Override mesh for this specific tile
    rotation: float = 0.0               # Rotation in degrees (0, 90, 180, 270)
    metadata: dict = field(default_factory=dict)


class Level:
    """A 2D grid-based level composed of tiles.

    The grid uses (row, col) indexing where (0, 0) is the top-left corner.
    """

    def __init__(self, width: int, height: int, theme_name: str = "default"):
        self.width = width
        self.height = height
        self.theme_name = theme_name
        self.grid: list[list[TileType]] = [
            [TileType.VOID for _ in range(width)] for _ in range(height)
        ]
        self.entry: Optional[tuple[int, int]] = None   # (row, col)
        self.exits: list[tuple[int, int]] = []          # [(row, col), ...]

    def get(self, row: int, col: int) -> TileType:
        if 0 <= row < self.height and 0 <= col < self.width:
            return self.grid[row][col]
        return TileType.VOID

    def set(self, row: int, col: int, tile_type: TileType) -> None:
        if 0 <= row < self.height and 0 <= col < self.width:
            self.grid[row][col] = tile_type

    def set_entry(self, row: int, col: int) -> None:
        self.entry = (row, col)
        self.set(row, col, TileType.ENTRY)

    def add_exit(self, row: int, col: int) -> None:
        self.exits.append((row, col))
        self.set(row, col, TileType.EXIT)

    def find_tiles(self, tile_type: TileType) -> list[tuple[int, int]]:
        """Return all (row, col) positions matching the given tile type."""
        results = []
        for r in range(self.height):
            for c in range(self.width):
                if self.grid[r][c] == tile_type:
                    results.append((r, c))
        return results

    def pretty_print(self) -> str:
        """Return a human-readable string representation of the level."""
        symbols = {
            TileType.VOID: " ",
            TileType.WALL: "#",
            TileType.FLOOR: ".",
            TileType.ENTRY: "S",
            TileType.EXIT: "X",
            TileType.DOOR: "D",
            TileType.PILLAR: "+",
        }
        lines = []
        for row in self.grid:
            lines.append("".join(symbols.get(t, "?") for t in row))
        return "\n".join(lines)
