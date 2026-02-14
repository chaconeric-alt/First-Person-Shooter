"""Theme system for mapping tile types to meshes and materials.

A *theme* is a JSON file that tells the game engine which mesh, material,
and scale to use for every :class:`TileType`.  Different environments
(dungeon, sci-fi corridor, outdoor ruins, etc.) can each have their own
theme file while sharing the same underlying level grid.

Theme JSON schema
-----------------
::

    {
      "name": "dungeon",
      "description": "Dark stone dungeon corridors",
      "tiles": {
        "WALL":  { "mesh": "meshes/dungeon_wall.obj",  "material": "materials/stone.mat",  "scale": [1,1,1] },
        "FLOOR": { "mesh": "meshes/dungeon_floor.obj", "material": "materials/stone_floor.mat", "scale": [1,1,1] },
        "ENTRY": { "mesh": "meshes/spawn_pad.obj",     "material": "materials/glow_green.mat",  "scale": [1,1,1] },
        "EXIT":  { "mesh": "meshes/exit_portal.obj",   "material": "materials/glow_red.mat",    "scale": [1,1,1] },
        "DOOR":  { "mesh": "meshes/doorway_arch.obj",  "material": "materials/wood.mat",        "scale": [1,1,1] },
        "PILLAR":{ "mesh": "meshes/pillar.obj",        "material": "materials/stone.mat",        "scale": [1,1,1] }
      },
      "ambient_light": [0.15, 0.15, 0.2],
      "fog_color": [0.05, 0.05, 0.1],
      "fog_density": 0.03
    }
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Optional, Union

from level_generator.level import TileType


@dataclass
class TileAsset:
    """Asset references for a single tile type."""

    mesh: str = ""
    material: str = ""
    scale: list[float] = field(default_factory=lambda: [1.0, 1.0, 1.0])

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "TileAsset":
        return cls(
            mesh=data.get("mesh", ""),
            material=data.get("material", ""),
            scale=data.get("scale", [1.0, 1.0, 1.0]),
        )

    def to_dict(self) -> dict[str, Any]:
        return {"mesh": self.mesh, "material": self.material, "scale": self.scale}


@dataclass
class Theme:
    """Collection of asset mappings for an environment style."""

    name: str = "default"
    description: str = ""
    tiles: dict[TileType, TileAsset] = field(default_factory=dict)
    ambient_light: list[float] = field(default_factory=lambda: [0.3, 0.3, 0.3])
    fog_color: list[float] = field(default_factory=lambda: [0.1, 0.1, 0.1])
    fog_density: float = 0.0

    def get_asset(self, tile_type: TileType) -> Optional[TileAsset]:
        """Return the asset config for *tile_type*, or ``None``."""
        return self.tiles.get(tile_type)

    def to_dict(self) -> dict[str, Any]:
        tiles_dict = {}
        for tt, asset in self.tiles.items():
            tiles_dict[tt.name] = asset.to_dict()
        return {
            "name": self.name,
            "description": self.description,
            "tiles": tiles_dict,
            "ambient_light": self.ambient_light,
            "fog_color": self.fog_color,
            "fog_density": self.fog_density,
        }

    def save(self, path: Union[str, Path]) -> None:
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as fh:
            json.dump(self.to_dict(), fh, indent=2)
            fh.write("\n")


def load_theme(path: Union[str, Path]) -> Theme:
    """Load a :class:`Theme` from a JSON file."""
    path = Path(path)
    with open(path, "r") as fh:
        data = json.load(fh)

    tile_type_lookup = {t.name: t for t in TileType}

    tiles: dict[TileType, TileAsset] = {}
    for key, asset_data in data.get("tiles", {}).items():
        tt = tile_type_lookup.get(key.upper())
        if tt is not None:
            tiles[tt] = TileAsset.from_dict(asset_data)

    return Theme(
        name=data.get("name", "default"),
        description=data.get("description", ""),
        tiles=tiles,
        ambient_light=data.get("ambient_light", [0.3, 0.3, 0.3]),
        fog_color=data.get("fog_color", [0.1, 0.1, 0.1]),
        fog_density=data.get("fog_density", 0.0),
    )
