"""Tests for the maze level generator."""

import os
import tempfile
from pathlib import Path

from level_generator.level import Level, TileType
from level_generator.maze import MazeConfig, MazeGenerator
from level_generator.csv_handler import load_level_csv, save_level_csv
from level_generator.theme import Theme, TileAsset, load_theme


class TestTileType:
    def test_from_value_valid(self):
        assert TileType.from_value(0) == TileType.VOID
        assert TileType.from_value(1) == TileType.WALL
        assert TileType.from_value(3) == TileType.ENTRY
        assert TileType.from_value(4) == TileType.EXIT

    def test_from_value_invalid_returns_void(self):
        assert TileType.from_value(99) == TileType.VOID
        assert TileType.from_value(-1) == TileType.VOID


class TestLevel:
    def test_init_creates_void_grid(self):
        level = Level(10, 8)
        assert level.width == 10
        assert level.height == 8
        for row in level.grid:
            for cell in row:
                assert cell == TileType.VOID

    def test_set_and_get(self):
        level = Level(5, 5)
        level.set(2, 3, TileType.WALL)
        assert level.get(2, 3) == TileType.WALL

    def test_get_out_of_bounds_returns_void(self):
        level = Level(5, 5)
        assert level.get(-1, 0) == TileType.VOID
        assert level.get(0, 99) == TileType.VOID

    def test_set_entry(self):
        level = Level(5, 5)
        level.set_entry(1, 1)
        assert level.entry == (1, 1)
        assert level.get(1, 1) == TileType.ENTRY

    def test_add_exit(self):
        level = Level(5, 5)
        level.add_exit(3, 3)
        level.add_exit(4, 4)
        assert len(level.exits) == 2
        assert level.get(3, 3) == TileType.EXIT

    def test_find_tiles(self):
        level = Level(5, 5)
        level.set(0, 0, TileType.WALL)
        level.set(1, 2, TileType.WALL)
        level.set(3, 4, TileType.WALL)
        walls = level.find_tiles(TileType.WALL)
        assert len(walls) == 3
        assert (0, 0) in walls
        assert (1, 2) in walls

    def test_pretty_print(self):
        level = Level(3, 3)
        level.set(0, 0, TileType.WALL)
        level.set(0, 1, TileType.WALL)
        level.set(0, 2, TileType.WALL)
        level.set(1, 0, TileType.WALL)
        level.set(1, 1, TileType.ENTRY)
        level.set(1, 2, TileType.WALL)
        level.set(2, 0, TileType.WALL)
        level.set(2, 1, TileType.EXIT)
        level.set(2, 2, TileType.WALL)
        text = level.pretty_print()
        assert "S" in text
        assert "X" in text
        assert "#" in text


class TestMazeGenerator:
    def test_generate_returns_level(self):
        config = MazeConfig(rooms_x=3, rooms_y=3, seed=42)
        gen = MazeGenerator(config)
        level = gen.generate()
        assert isinstance(level, Level)

    def test_level_has_entry_and_exit(self):
        config = MazeConfig(rooms_x=3, rooms_y=3, seed=42)
        gen = MazeGenerator(config)
        level = gen.generate()
        assert level.entry is not None
        assert len(level.exits) >= 1
        assert level.get(*level.entry) == TileType.ENTRY
        for ex in level.exits:
            assert level.get(*ex) == TileType.EXIT

    def test_grid_dimensions(self):
        config = MazeConfig(rooms_x=4, rooms_y=3, room_width=3, room_height=3, seed=1)
        gen = MazeGenerator(config)
        level = gen.generate()
        expected_w = 4 * (3 + 1) + 1  # 17
        expected_h = 3 * (3 + 1) + 1  # 13
        assert level.width == expected_w
        assert level.height == expected_h

    def test_multiple_exits(self):
        config = MazeConfig(rooms_x=5, rooms_y=5, num_exits=3, seed=7)
        gen = MazeGenerator(config)
        level = gen.generate()
        assert len(level.exits) >= 3

    def test_deterministic_with_seed(self):
        config = MazeConfig(rooms_x=4, rooms_y=4, seed=123)
        gen = MazeGenerator(config)
        level1 = gen.generate()
        level2 = gen.generate(seed=123)
        assert level1.grid == level2.grid

    def test_rooms_have_floor_tiles(self):
        config = MazeConfig(rooms_x=2, rooms_y=2, room_width=3, room_height=3, seed=0)
        gen = MazeGenerator(config)
        level = gen.generate()
        floors = level.find_tiles(TileType.FLOOR)
        # Each room has room_width * room_height - 1 floors (one is entry or exit)
        # Minimum: at least some floors per room
        assert len(floors) >= 4  # 4 rooms, at least some floor per room

    def test_has_doors(self):
        config = MazeConfig(rooms_x=3, rooms_y=3, seed=55)
        gen = MazeGenerator(config)
        level = gen.generate()
        doors = level.find_tiles(TileType.DOOR)
        assert len(doors) >= 1, "Maze should have at least one door"

    def test_has_pillars(self):
        config = MazeConfig(rooms_x=2, rooms_y=2, seed=0)
        gen = MazeGenerator(config)
        level = gen.generate()
        pillars = level.find_tiles(TileType.PILLAR)
        # 3x3 grid of intersections for 2x2 rooms
        assert len(pillars) == 9

    def test_all_rooms_reachable(self):
        """Every room should be reachable from the entry room via doors."""
        config = MazeConfig(rooms_x=4, rooms_y=4, seed=99)
        gen = MazeGenerator(config)
        level = gen.generate()
        # BFS from entry over walkable tiles (FLOOR, ENTRY, EXIT, DOOR)
        walkable = {TileType.FLOOR, TileType.ENTRY, TileType.EXIT, TileType.DOOR}
        visited = set()
        queue = [level.entry]
        visited.add(level.entry)
        while queue:
            r, c = queue.pop(0)
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = r + dr, c + dc
                if (nr, nc) not in visited and level.get(nr, nc) in walkable:
                    visited.add((nr, nc))
                    queue.append((nr, nc))

        # Check that every room has at least one visited floor tile
        for ry in range(config.rooms_y):
            for rx in range(config.rooms_x):
                top = ry * (config.room_height + 1) + 1
                left = rx * (config.room_width + 1) + 1
                room_visited = False
                for dr in range(config.room_height):
                    for dc in range(config.room_width):
                        if (top + dr, left + dc) in visited:
                            room_visited = True
                            break
                    if room_visited:
                        break
                assert room_visited, f"Room ({rx},{ry}) is not reachable"


class TestCSVRoundTrip:
    def test_save_and_load(self):
        config = MazeConfig(rooms_x=3, rooms_y=3, seed=42, theme_name="dungeon")
        gen = MazeGenerator(config)
        level = gen.generate()

        with tempfile.TemporaryDirectory() as tmpdir:
            csv_path = Path(tmpdir) / "test_map.csv"
            save_level_csv(level, csv_path)

            loaded = load_level_csv(csv_path)
            assert loaded.width == level.width
            assert loaded.height == level.height
            assert loaded.theme_name == "dungeon"
            assert loaded.entry == level.entry
            assert sorted(loaded.exits) == sorted(level.exits)
            assert loaded.grid == level.grid

    def test_load_nonexistent_raises(self):
        try:
            load_level_csv("/nonexistent/path.csv")
            assert False, "Should have raised FileNotFoundError"
        except FileNotFoundError:
            pass

    def test_load_empty_raises(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            csv_path = Path(tmpdir) / "empty.csv"
            csv_path.write_text("# theme:test\n")
            try:
                load_level_csv(csv_path)
                assert False, "Should have raised ValueError"
            except ValueError:
                pass

    def test_csv_content_format(self):
        config = MazeConfig(rooms_x=2, rooms_y=2, seed=1)
        gen = MazeGenerator(config)
        level = gen.generate()

        with tempfile.TemporaryDirectory() as tmpdir:
            csv_path = Path(tmpdir) / "format_test.csv"
            save_level_csv(level, csv_path)
            content = csv_path.read_text()
            # First line should be the theme comment
            lines = content.strip().split("\n")
            assert lines[0].startswith("# theme:")
            # Remaining lines should be comma-separated integers
            for line in lines[1:]:
                parts = line.split(",")
                for p in parts:
                    int(p.strip())  # Should not raise


class TestTheme:
    def test_load_theme_json(self):
        theme = load_theme("themes/default.json")
        assert theme.name == "default"
        assert TileType.WALL in theme.tiles
        assert TileType.FLOOR in theme.tiles
        assert theme.tiles[TileType.WALL].mesh != ""

    def test_load_all_bundled_themes(self):
        themes_dir = Path("themes")
        for json_file in themes_dir.glob("*.json"):
            theme = load_theme(json_file)
            assert theme.name, f"Theme {json_file} has no name"
            assert TileType.WALL in theme.tiles, f"Theme {json_file} missing WALL"
            assert TileType.FLOOR in theme.tiles, f"Theme {json_file} missing FLOOR"

    def test_theme_save_and_load(self):
        theme = Theme(
            name="test_theme",
            description="A test",
            tiles={
                TileType.WALL: TileAsset(mesh="wall.obj", material="wall.mat"),
                TileType.FLOOR: TileAsset(mesh="floor.obj", material="floor.mat"),
            },
        )
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "test_theme.json"
            theme.save(path)
            loaded = load_theme(path)
            assert loaded.name == "test_theme"
            assert loaded.tiles[TileType.WALL].mesh == "wall.obj"

    def test_get_asset(self):
        theme = Theme(
            tiles={TileType.WALL: TileAsset(mesh="w.obj")},
        )
        assert theme.get_asset(TileType.WALL) is not None
        assert theme.get_asset(TileType.EXIT) is None
