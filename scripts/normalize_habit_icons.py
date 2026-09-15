#!/usr/bin/env python3
"""Build tintable habit assets from the existing Figma SVG paths.

Run from any directory with `python3 scripts/normalize_habit_icons.py`.
Figma's CSS custom properties and percentage dimensions are browser-specific;
asset catalogs need explicit dimensions and literal stroke colors. SwiftUI
supplies the displayed tint via template rendering.
"""

import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIRECTORY = PROJECT_ROOT / "IdeaBox/Resources/FigmaAssets/source"
ASSET_DIRECTORY = PROJECT_ROOT / "IdeaBox/Assets.xcassets"
HABIT_ASSETS = {
    "HabitBook": "habit_book.svg",
    "HabitWater": "habit_water.svg",
    "HabitWorkout": "habit_dumbbell.svg",
    "HabitMeditation": "habit_meditation.svg",
    "HabitMoon": "habit_moon.svg",
    "HabitPencil": "habit_pencil.svg",
    "HabitMusic": "habit_music.svg",
    "HabitApple": "habit_apple.svg",
    "HabitBrain": "habit_brain.svg",
    "HabitSun": "habit_sun.svg",
}


def normalize_svg(source: str) -> str:
    root = ET.fromstring(source)
    _, _, width, height = root.attrib["viewBox"].split()
    # Preserve every source path and its geometry; normalize only the SVG wrapper
    # and stroke colors. The source's clipping rectangles remain inside <defs>.
    source = re.sub(r'width="100%"', f'width="{width}"', source, count=1)
    source = re.sub(r'height="100%"', f'height="{height}"', source, count=1)
    source = source.replace('preserveAspectRatio="none"', 'preserveAspectRatio="xMidYMid meet"', 1)
    source = source.replace(' overflow="visible"', '', 1)
    source = source.replace(' style="display: block;"', '', 1)
    source = re.sub(r'var\(--stroke-0,\s*[^)]+\)', '#000000', source)
    if "var(" in source:
        raise ValueError("SVG still contains an unsupported CSS custom property")
    return source


def main() -> None:
    for asset_name, filename in HABIT_ASSETS.items():
        destination = ASSET_DIRECTORY / f"{asset_name}.imageset"
        normalized = normalize_svg((SOURCE_DIRECTORY / filename).read_text())
        (destination / filename).write_text(normalized)
        contents = {
            "images": [{"filename": filename, "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
            "properties": {
                "preserves-vector-representation": True,
                "template-rendering-intent": "template",
            },
        }
        (destination / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
        # The old opaque raster becomes a solid square when template tinted.
        (destination / "image.png").unlink(missing_ok=True)
        print(f"{asset_name} <- {filename}")


if __name__ == "__main__":
    main()
