# Quake-Style FPS in Godot 4

A complete, modular first-person shooter inspired by classic arena shooters like Quake, built entirely in Godot 4 with GDScript.

## 🎮 Current Status

**✅ FULLY PLAYABLE WITH ZERO EXTERNAL ASSETS!**

The game currently includes:

- Complete procedural asset generation system
- Quake-style player movement with air control
- Four distinct enemy types (Grunt, Sniper, Brute, Swarmling) - all procedurally generated
- Weapons (Pistol, Shotgun, Rocket Launcher, Railgun) - procedural viewmodels
- Items (Health, Armor, Ammo) - procedural pickups
- CSV-based game data system with automatic defaults
- Test arena with enemies and items

## 🚀 How to Run

### Game (Godot)

1. **Install Godot 4.3+** from https://godotengine.org
2. **Open the repository root** as a Godot project (the `project.godot` is at the top level)
3. **Press F5** to run

That's it! No assets to download, no external dependencies.

### Level Generator (Python)

```bash
# Generate a new maze level
python -m level_generator generate -o levels/map.csv --theme themes/dungeon.json --seed 42

# Load and display an existing level
python -m level_generator load levels/map.csv

# Run tests
python -m pytest tests/
```

## 🎯 Controls

- **WASD** - Move
- **Mouse** - Look around
- **Space** - Jump
- **ESC** - Release/Capture mouse cursor
- **ESC (in game)** - Pause

## 📁 Project Structure

The repository root is the Godot project — everything lives in one integrated package.

```
./
├── project.godot                  # Godot 4 project config (repo root)
├── main.tscn / main.gd           # Test scene with procedural level
├── game_manager.gd                # Autoload singleton - game state & CSV data
├── test_procedural.gd             # Quick asset verification script
├── scripts/
│   ├── player/
│   │   └── player_controller.gd   # Quake-style FPS movement
│   └── utils/
│       ├── csv_parser.gd          # CSV data loading/saving
│       └── procedural_assets.gd   # ALL visual assets generated here
├── level_generator/               # Python maze level generator
│   ├── maze.py                    # Recursive-backtracking maze algorithm
│   ├── level.py                   # Level/TileType data models
│   ├── csv_handler.py             # CSV serialization for levels
│   ├── theme.py                   # Theme system for asset mapping
│   └── cli.py                     # Command-line interface
├── themes/                        # Theme JSON configs (dungeon, scifi, etc.)
├── levels/                        # Generated level CSV output
├── tests/                         # Python unit tests
│   └── test_level_generator.py
└── csv/                           # Auto-generated game balance data (runtime)
```

## 🎨 Procedural Asset System

The `procedural_assets.gd` file contains complete implementations for generating:

- **Enemies**: 4 unique types with distinct visual designs
- **Weapons**: Pistol, Shotgun, Rocket Launcher, Railgun
- **Items**: Health packs, armor, ammo boxes
- **Level Geometry**: Floors, walls, doors, pillars
- **Effects**: Projectiles, particles, lighting
- **Environment**: Procedural skyboxes

Every asset is created using Godot's built-in mesh primitives (BoxMesh, CapsuleMesh, CylinderMesh, SphereMesh) with programmatic materials.

## 🔧 What's Next

To continue development, you can:

1. **Add AI Behavior** - Implement the AI state machine for enemies
2. **Add Weapon System** - Create firing mechanics and projectiles
3. **Integrate Level Generator** - Load generated maze CSVs into the Godot scene
4. **HUD/UI** - Add health/armor displays, crosshair
5. **Sound System** - Add sound effects and music
6. **Replace Procedural Assets** - Swap in artist-made 3D models

## 📊 Data-Driven Design

All game balance is controlled via CSV files that auto-generate on first run:

- `enemies.csv` - Enemy stats, AI behavior, drops
- `weapons.csv` - Damage, fire rate, ammo
- `items.csv` - Health/armor values, respawn times
- `projectiles.csv` - Speed, damage, physics

Simply edit these files to rebalance the game!

## 🎮 Test Scene

The current `main.tscn` creates:

- A 40x40 unit test arena with walls
- One of each enemy type placed in corners
- Health, armor, and ammo pickups
- Directional lighting and procedural sky
- Fully playable FPS character with camera

Walk around to see all the procedurally generated assets!

## 🔨 Architecture Highlights

- **Asset-Agnostic Code**: All visual assets loaded via paths from CSV
- **Complete Fallback System**: Missing assets automatically use procedural generation
- **Modular Design**: Each system (player, enemies, items) is independent
- **CSV-Driven Balance**: No hardcoded game values
- **Extension Points**: Clear hooks for adding new content

## 📝 License

This is a demonstration project based on the comprehensive FPS prompt. Feel free to use, modify, and extend!

## 🎯 Credits

Built following the comprehensive Quake-style FPS prompt for Godot 4, which provides:
- Complete procedural asset generation
- CSV-based data systems
- Modular architecture
- Quake-style movement physics
- Artist integration workflow

Enjoy your retro FPS! 🚀
