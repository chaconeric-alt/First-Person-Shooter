"""Command-line interface for the maze level generator.

Usage examples::

    # Generate a new level with default settings, write to levels/map.csv
    python -m level_generator generate -o levels/map.csv

    # Generate with a specific theme, room count, and seed
    python -m level_generator generate -o levels/dungeon_01.csv \\
        --theme themes/dungeon.json --rooms-x 8 --rooms-y 6 --seed 42

    # Load an existing CSV and pretty-print it
    python -m level_generator load levels/map.csv

    # Generate only if the CSV does not already exist
    python -m level_generator auto levels/map.csv --theme themes/scifi.json
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from level_generator.csv_handler import load_level_csv, save_level_csv
from level_generator.maze import MazeConfig, MazeGenerator
from level_generator.theme import load_theme


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="level_generator",
        description="Maze level generator for First-Person-Shooter",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # -- generate ----------------------------------------------------------
    gen = sub.add_parser("generate", help="Generate a new maze level CSV")
    gen.add_argument("-o", "--output", required=True, help="Output CSV path")
    gen.add_argument("--theme", default=None, help="Path to a theme JSON file")
    gen.add_argument("--rooms-x", type=int, default=5, help="Rooms horizontally (default: 5)")
    gen.add_argument("--rooms-y", type=int, default=5, help="Rooms vertically (default: 5)")
    gen.add_argument("--room-width", type=int, default=3, help="Room interior width in tiles (default: 3)")
    gen.add_argument("--room-height", type=int, default=3, help="Room interior height in tiles (default: 3)")
    gen.add_argument("--door-width", type=int, default=1, help="Doorway width in tiles (default: 1)")
    gen.add_argument("--extra-doors", type=float, default=0.1, help="Extra door probability 0.0-1.0 (default: 0.1)")
    gen.add_argument("--num-exits", type=int, default=1, help="Number of exits (default: 1)")
    gen.add_argument("--seed", type=int, default=None, help="RNG seed for reproducibility")

    # -- load --------------------------------------------------------------
    load = sub.add_parser("load", help="Load and display an existing level CSV")
    load.add_argument("csv_path", help="Path to the CSV file")
    load.add_argument("--theme", default=None, help="Path to a theme JSON to display asset info")

    # -- auto --------------------------------------------------------------
    auto = sub.add_parser(
        "auto",
        help="Load a CSV if it exists, otherwise generate a new one",
    )
    auto.add_argument("csv_path", help="Path to the CSV file")
    auto.add_argument("--theme", default=None, help="Path to a theme JSON file")
    auto.add_argument("--rooms-x", type=int, default=5)
    auto.add_argument("--rooms-y", type=int, default=5)
    auto.add_argument("--room-width", type=int, default=3)
    auto.add_argument("--room-height", type=int, default=3)
    auto.add_argument("--door-width", type=int, default=1)
    auto.add_argument("--extra-doors", type=float, default=0.1)
    auto.add_argument("--num-exits", type=int, default=1)
    auto.add_argument("--seed", type=int, default=None)

    return parser


def _resolve_theme_name(theme_path: str | None) -> str:
    """Extract a theme name from the JSON path, or return 'default'."""
    if theme_path is None:
        return "default"
    try:
        theme = load_theme(theme_path)
        return theme.name
    except Exception:
        return Path(theme_path).stem


def _generate(args: argparse.Namespace) -> None:
    theme_name = _resolve_theme_name(args.theme)
    config = MazeConfig(
        rooms_x=args.rooms_x,
        rooms_y=args.rooms_y,
        room_width=args.room_width,
        room_height=args.room_height,
        door_width=args.door_width,
        extra_doors=args.extra_doors,
        num_exits=args.num_exits,
        theme_name=theme_name,
        seed=args.seed,
    )
    gen = MazeGenerator(config)
    level = gen.generate()
    save_level_csv(level, args.output)
    print(f"Level generated ({level.width}x{level.height} tiles, "
          f"{config.rooms_x}x{config.rooms_y} rooms)")
    print(f"Saved to: {args.output}")
    print(f"Theme: {theme_name}")
    print(f"Entry: {level.entry}")
    print(f"Exits: {level.exits}")
    print()
    print(level.pretty_print())


def _load(args: argparse.Namespace) -> None:
    level = load_level_csv(args.csv_path)
    print(f"Loaded level from: {args.csv_path}")
    print(f"Size: {level.width}x{level.height} tiles")
    print(f"Theme: {level.theme_name}")
    print(f"Entry: {level.entry}")
    print(f"Exits: {level.exits}")

    if args.theme:
        theme = load_theme(args.theme)
        print(f"\nTheme '{theme.name}': {theme.description}")
        for tt, asset in theme.tiles.items():
            print(f"  {tt.name:8s} -> mesh={asset.mesh}  material={asset.material}")

    print()
    print(level.pretty_print())


def _auto(args: argparse.Namespace) -> None:
    csv_path = Path(args.csv_path)
    if csv_path.exists():
        print(f"CSV exists, loading: {csv_path}")
        level = load_level_csv(csv_path)
        print(f"Loaded level ({level.width}x{level.height}, theme={level.theme_name})")
        print(f"Entry: {level.entry}  Exits: {level.exits}")
        print()
        print(level.pretty_print())
    else:
        print(f"CSV not found, generating new level: {csv_path}")
        theme_name = _resolve_theme_name(args.theme)
        config = MazeConfig(
            rooms_x=args.rooms_x,
            rooms_y=args.rooms_y,
            room_width=args.room_width,
            room_height=args.room_height,
            door_width=args.door_width,
            extra_doors=args.extra_doors,
            num_exits=args.num_exits,
            theme_name=theme_name,
            seed=args.seed,
        )
        gen = MazeGenerator(config)
        level = gen.generate()
        save_level_csv(level, csv_path)
        print(f"Generated and saved ({level.width}x{level.height} tiles, "
              f"{config.rooms_x}x{config.rooms_y} rooms)")
        print(f"Entry: {level.entry}  Exits: {level.exits}")
        print()
        print(level.pretty_print())


def main(argv: list[str] | None = None) -> None:
    parser = _build_parser()
    args = parser.parse_args(argv)

    if args.command == "generate":
        _generate(args)
    elif args.command == "load":
        _load(args)
    elif args.command == "auto":
        _auto(args)
    else:
        parser.print_help()
        sys.exit(1)
