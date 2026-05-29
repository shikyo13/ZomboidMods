# Barricade Context Menu [B42]

Restores right-click context menu options for barricading and unbarricading windows and doors in Project Zomboid Build 42.

Build 42 moved barricading from the intuitive right-click menu into the build menu system, adding unnecessary clicks for a core survival action. This lightweight mod brings it back.

## Features

- Right-click any window or door to barricade it directly
- Supports all three barricade types: Wood Planks, Metal Sheets, and Metal Bars
- Remove barricades via right-click with the appropriate tools
- Uses vanilla barricade logic — zero new game mechanics
- Reuses vanilla translation keys — works in all languages automatically
- Multiplayer compatible

## Material Requirements

| Action | Materials |
|--------|-----------|
| Barricade (Planks) | Hammer + Plank + 2 Nails |
| Barricade (Metal Sheet) | Blow Torch + Sheet Metal |
| Barricade (Metal Bars) | Blow Torch + 3 Metal Bars |
| Remove (Wood) | Crowbar or Hammer |
| Remove (Metal) | Blow Torch |

## Installation

### Steam Workshop
Subscribe on the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3667874678).

### Manual
Copy `Contents/mods/BarricadeContextMenu` to your PZ mods directory (`~/Zomboid/mods/`).

## Technical Details

Build 42 moved barricading to the build recipe system, leaving the vanilla context menu handlers (`ISWorldObjectContextMenu.onBarricade`, etc.) as orphaned dead code. This mod hooks `OnFillWorldObjectContextMenu` to reconnect them.

It also fixes a vanilla bug in `ISBarricadeAction:isValid()` where `ItemType.HAMMER` (nil) was used instead of `ItemTag.HAMMER`, which caused the barricade timed action to always fail silently.

## Credits

- ZeroTheAbsolute — Build 42 mod

## License

MIT
