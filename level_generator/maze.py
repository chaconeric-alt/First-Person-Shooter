"""Procedural maze generator using recursive backtracking.

Generates a maze of interconnected rooms on a grid.  Each "room" is a
multi-tile area separated by walls, with carved doorways linking
neighbouring rooms.  The algorithm guarantees every room is reachable
from the entry point, and places at least one exit as far from the
entry as possible.
"""

from __future__ import annotations

import random
from dataclasses import dataclass, field
from typing import Optional

from level_generator.level import Level, TileType


# Directions: (delta_row, delta_col)
_DIRECTIONS = [(-1, 0), (1, 0), (0, -1), (0, 1)]


@dataclass
class MazeConfig:
    """Parameters that control maze generation."""

    rooms_x: int = 5              # Number of rooms horizontally
    rooms_y: int = 5              # Number of rooms vertically
    room_width: int = 3           # Interior width of each room (tiles)
    room_height: int = 3          # Interior height of each room (tiles)
    door_width: int = 1           # Width of doorways between rooms
    extra_doors: float = 0.1      # Probability of adding extra doors (0.0-1.0)
    num_exits: int = 1            # Minimum number of exits to place
    theme_name: str = "default"   # Theme to tag on the resulting Level
    seed: Optional[int] = None    # RNG seed for reproducibility


class MazeGenerator:
    """Generates a :class:`Level` containing a maze of interconnected rooms."""

    def __init__(self, config: Optional[MazeConfig] = None):
        self.config = config or MazeConfig()

    def generate(self, seed: Optional[int] = None) -> Level:
        """Generate and return a new :class:`Level`."""
        cfg = self.config
        effective_seed = seed if seed is not None else cfg.seed
        if effective_seed is not None:
            random.seed(effective_seed)

        # -- Compute overall tile-grid dimensions --
        # Each room is room_width x room_height interior tiles, surrounded by
        # 1-tile-thick walls.  Rooms share walls with their neighbours.
        grid_w = cfg.rooms_x * (cfg.room_width + 1) + 1
        grid_h = cfg.rooms_y * (cfg.room_height + 1) + 1

        level = Level(width=grid_w, height=grid_h, theme_name=cfg.theme_name)

        # Fill entire grid with walls first
        for r in range(grid_h):
            for c in range(grid_w):
                level.set(r, c, TileType.WALL)

        # Carve room interiors as floor
        for ry in range(cfg.rooms_y):
            for rx in range(cfg.rooms_x):
                self._carve_room(level, rx, ry)

        # Place pillars at wall intersections for visual variety
        self._place_pillars(level)

        # Generate maze connectivity using recursive backtracking (DFS)
        visited = [[False] * cfg.rooms_x for _ in range(cfg.rooms_y)]
        self._carve_maze(level, visited, 0, 0)

        # Optionally add extra doors to create loops (makes navigation less tedious)
        self._add_extra_doors(level)

        # Place entry and exit(s)
        self._place_entry_and_exits(level)

        return level

    # -----------------------------------------------------------------
    # Internal helpers
    # -----------------------------------------------------------------

    def _room_top_left(self, rx: int, ry: int) -> tuple[int, int]:
        """Return the (row, col) of the top-left interior tile of room (rx, ry)."""
        cfg = self.config
        row = ry * (cfg.room_height + 1) + 1
        col = rx * (cfg.room_width + 1) + 1
        return row, col

    def _carve_room(self, level: Level, rx: int, ry: int) -> None:
        """Set all interior tiles of room (rx, ry) to FLOOR."""
        cfg = self.config
        top, left = self._room_top_left(rx, ry)
        for dr in range(cfg.room_height):
            for dc in range(cfg.room_width):
                level.set(top + dr, left + dc, TileType.FLOOR)

    def _place_pillars(self, level: Level) -> None:
        """Mark wall-intersection corners as PILLAR tiles."""
        cfg = self.config
        for ry in range(cfg.rooms_y + 1):
            for rx in range(cfg.rooms_x + 1):
                r = ry * (cfg.room_height + 1)
                c = rx * (cfg.room_width + 1)
                level.set(r, c, TileType.PILLAR)

    def _carve_maze(
        self,
        level: Level,
        visited: list[list[bool]],
        rx: int,
        ry: int,
    ) -> None:
        """Recursive backtracking: carve doorways between adjacent rooms."""
        visited[ry][rx] = True
        directions = list(_DIRECTIONS)
        random.shuffle(directions)

        for dry, drx in directions:
            nx, ny = rx + drx, ry + dry
            if (
                0 <= nx < self.config.rooms_x
                and 0 <= ny < self.config.rooms_y
                and not visited[ny][nx]
            ):
                self._carve_door(level, rx, ry, drx, dry)
                self._carve_maze(level, visited, nx, ny)

    def _carve_door(
        self,
        level: Level,
        rx: int,
        ry: int,
        drx: int,
        dry: int,
    ) -> None:
        """Carve a doorway in the wall between room (rx, ry) and its neighbour."""
        cfg = self.config
        top, left = self._room_top_left(rx, ry)

        if drx == 1:  # Door on the right wall
            wall_col = left + cfg.room_width
            center_row = top + cfg.room_height // 2
            for d in range(cfg.door_width):
                level.set(center_row + d, wall_col, TileType.DOOR)
        elif drx == -1:  # Door on the left wall
            wall_col = left - 1
            center_row = top + cfg.room_height // 2
            for d in range(cfg.door_width):
                level.set(center_row + d, wall_col, TileType.DOOR)
        elif dry == 1:  # Door on the bottom wall
            wall_row = top + cfg.room_height
            center_col = left + cfg.room_width // 2
            for d in range(cfg.door_width):
                level.set(wall_row, center_col + d, TileType.DOOR)
        elif dry == -1:  # Door on the top wall
            wall_row = top - 1
            center_col = left + cfg.room_width // 2
            for d in range(cfg.door_width):
                level.set(wall_row, center_col + d, TileType.DOOR)

    def _add_extra_doors(self, level: Level) -> None:
        """Randomly punch additional doorways to add loops to the maze."""
        cfg = self.config
        if cfg.extra_doors <= 0:
            return

        for ry in range(cfg.rooms_y):
            for rx in range(cfg.rooms_x):
                # Try right neighbour
                if rx + 1 < cfg.rooms_x and random.random() < cfg.extra_doors:
                    top, left = self._room_top_left(rx, ry)
                    wall_col = left + cfg.room_width
                    center_row = top + cfg.room_height // 2
                    if level.get(center_row, wall_col) == TileType.WALL:
                        level.set(center_row, wall_col, TileType.DOOR)
                # Try bottom neighbour
                if ry + 1 < cfg.rooms_y and random.random() < cfg.extra_doors:
                    top, left = self._room_top_left(rx, ry)
                    wall_row = top + cfg.room_height
                    center_col = left + cfg.room_width // 2
                    if level.get(wall_row, center_col) == TileType.WALL:
                        level.set(wall_row, center_col, TileType.DOOR)

    def _place_entry_and_exits(self, level: Level) -> None:
        """Place the entry in the first room and exit(s) far from the entry."""
        cfg = self.config

        # Entry: centre of room (0, 0)
        entry_top, entry_left = self._room_top_left(0, 0)
        entry_r = entry_top + cfg.room_height // 2
        entry_c = entry_left + cfg.room_width // 2
        level.set_entry(entry_r, entry_c)

        # Exits: place in rooms farthest from entry using BFS over the room graph
        distances = self._bfs_room_distances(level, 0, 0)
        # Sort rooms by distance descending, pick the farthest ones
        room_list = [
            (dist, rx, ry)
            for ry, row in enumerate(distances)
            for rx, dist in enumerate(row)
            if dist >= 0 and not (rx == 0 and ry == 0)
        ]
        room_list.sort(reverse=True)

        placed = 0
        for _dist, rx, ry in room_list:
            if placed >= cfg.num_exits:
                break
            top, left = self._room_top_left(rx, ry)
            er = top + cfg.room_height // 2
            ec = left + cfg.room_width // 2
            level.add_exit(er, ec)
            placed += 1

        # Safety: guarantee at least one exit even on tiny mazes
        if not level.exits:
            last_top, last_left = self._room_top_left(
                cfg.rooms_x - 1, cfg.rooms_y - 1
            )
            level.add_exit(
                last_top + cfg.room_height // 2,
                last_left + cfg.room_width // 2,
            )

    def _bfs_room_distances(
        self, level: Level, start_rx: int, start_ry: int
    ) -> list[list[int]]:
        """BFS over the room connectivity graph; return distance matrix."""
        cfg = self.config
        dist = [[-1] * cfg.rooms_x for _ in range(cfg.rooms_y)]
        dist[start_ry][start_rx] = 0
        queue = [(start_rx, start_ry)]
        head = 0

        while head < len(queue):
            rx, ry = queue[head]
            head += 1
            for dry, drx in _DIRECTIONS:
                nx, ny = rx + drx, ry + dry
                if (
                    0 <= nx < cfg.rooms_x
                    and 0 <= ny < cfg.rooms_y
                    and dist[ny][nx] == -1
                    and self._has_door_between(level, rx, ry, drx, dry)
                ):
                    dist[ny][nx] = dist[ry][rx] + 1
                    queue.append((nx, ny))
        return dist

    def _has_door_between(
        self, level: Level, rx: int, ry: int, drx: int, dry: int
    ) -> bool:
        """Check whether there is a carved door between room (rx,ry) and its neighbour."""
        cfg = self.config
        top, left = self._room_top_left(rx, ry)

        if drx == 1:
            wall_col = left + cfg.room_width
            center_row = top + cfg.room_height // 2
            return level.get(center_row, wall_col) in (TileType.DOOR, TileType.FLOOR)
        if drx == -1:
            wall_col = left - 1
            center_row = top + cfg.room_height // 2
            return level.get(center_row, wall_col) in (TileType.DOOR, TileType.FLOOR)
        if dry == 1:
            wall_row = top + cfg.room_height
            center_col = left + cfg.room_width // 2
            return level.get(wall_row, center_col) in (TileType.DOOR, TileType.FLOOR)
        if dry == -1:
            wall_row = top - 1
            center_col = left + cfg.room_width // 2
            return level.get(wall_row, center_col) in (TileType.DOOR, TileType.FLOOR)
        return False
