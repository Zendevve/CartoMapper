# CartoMapper

**Unified Map Enhancement Addon for World of Warcraft: Wrath of the Lich King (3.3.5a)**

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=flat-square&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/zendevve)

---

## Features

CartoMapper replaces several heavy map addons with a single, lightweight, high-performance package. It combines fog clearing, scroll zooming, coordinate display, group icons, points of interest, waypoints, instance maps, and battlefield minimap enhancements into one unified experience.

| Feature | Description |
| --- | --- |
| **Fog of War Clear** | Reveals unexplored world map regions as removable or fully transparent overlays, with optional color tinting |
| **Scroll-to-Zoom & Drag-to-Pan** | Smooth mousewheel zoom (up to 10x) with cursor-centered scaling and click-and-drag navigation |
| **Coordinates** | Real-time cursor and player position coordinates at the bottom of the map |
| **Waypoints** | TomTom-style waypoint system with a navigation arrow, cross-zone routing, and automatic path gate management |
| **Class-Colored Group Icons** | Party/raid members displayed with class colors, subgroup numbers, and pulsing visual indicators (dead, in combat, AFK) |
| **Points of Interest** | Dungeon/raid portals, flight paths, spirit healers, and clickable zone-crossing arrows |
| **Instance & Battleground Maps** | View dungeon, raid, and battleground maps offline from the continent/zone dropdowns |
| **Battlefield Minimap** | Enhanced Shift+M map with configurable size, opacity, unlock, and zoom levels |
| **Zone Level Info** | Recommended level ranges and minimum fishing skill shown on zone map tooltips |
| **Borderless / Click-Through Map** | Hides default frame borders for a clean overlay; optional click-through mode; controls reappear on hover |
| **Ctrl + Scroll Scaling** | Scale the windowed map frame size on the fly |
| **Per-Character Settings** | Override global settings on a per-character basis |

---

## Installation

1. Download the latest release or clone this repository.
2. Copy the `CartoMapper` folder into your WoW addon directory:
   ```
   World of Warcraft\Interface\AddOns\
   ```
3. Ensure the folder is named exactly `CartoMapper` (not `CartoMapper-main`).
4. Log in and type `/cm` to open the configuration panel.

> [!NOTE]
> CartoMapper targets **WoW 3.3.5a (Wrath of the Lich King)**. It requires the `Interface: 30300` API.

---

## Slash Commands

| Command | Description |
| --- | --- |
| `/cm` / `/cartomapper` | Toggle the configuration panel |
| `/cm status` | Print the current state of all modules to chat |
| `/cm toggle <option>` | Toggle a specific module on or off |

Available toggle options:

- `zoom` — Scroll-to-zoom and drag-to-pan
- `coords` — Cursor and player coordinates
- `battleMap` — Enhanced battlefield minimap
- `groupIcons` — Class-colored group icons
- `fogClear` — Fog of war reveal
- `pois` — Points of interest
- `borderless` — Borderless windowed map
- `minimapButton` — Minimap shortcut button

Example: `/cm toggle fogclear`

### Waypoints

| Command | Description |
| --- | --- |
| `/way [x] [y] [desc]` | Add a waypoint in the current zone |
| `/way [zone] [x] [y] [desc]` | Add a waypoint in a specific zone |
| `/way clear` | Clear all active waypoints |
| `/wayback` / `/wayb` | Bookmark your current position |
| `/cway` / `/closestway` | Set the nearest waypoint as active |

> [!TIP]
> Some toggles require a `/reload` to take full effect. The configuration panel marks these with an asterisk (*).

---

## Configuration Panel

Open with `/cm` or by clicking the minimap button. The panel has seven tabs:

### General
- Minimap button visibility
- Remember zoom level across map openings
- Show zone level and fishing skill info on tooltips

### Map Window
- Borderless mode (hides frame borders)
- Click-through mode (interact through the map)
- No fade on cursor hover
- Hide town/city icons on continent maps
- Map window scale (0.5x – 4.0x)
- Stationary and moving opacity (0.1 – 1.0)

### Zoom / Pan
- Enable/disable scroll-to-zoom
- Center map on player automatically
- Maximum zoom scale (1x – 10x)
- Player arrow and group icon sizes

### Fog Clear
- Enable/disable fog reveal
- Fog tint style: Normal (overlay grid) or Custom colored tint
- Fog transparency (0.1 – 1.0)
- Custom color picker

### Points of Interest
- Master toggle for all POIs
- Individual filters: dungeons & raids, same-faction flights, opposing-faction flights, spirit healers, zone crossings

### Battlefield
- Enable/disable enhanced battlefield map
- Unlock for dragging
- Center on player
- Group and player arrow sizes
- Battlefield map size and opacity
- Maximum zoom limit

### Group Icons
- Class-colored icons with subgroup numbers (1–8)
- Visual states: dead (grey), in-combat (red), AFK (purple)

### Waypoints
- Enable/disable waypoint system
- Arrival distance threshold
- Arrow scale and alpha
- Show estimated time of arrival (ETA)

---

## Per-Character Settings

CartoMapper supports per-character setting overrides. Enable the **Per-Character Settings** checkbox in the configuration panel header to create a separate profile for the current character. Changes made while this checkbox is active will only affect that character.

---

## Architecture

The addon is modular. Each feature is a separate Lua file that registers itself with the core:

| Module | File | Description |
| --- | --- | --- |
| Core | `CartoMapper.lua` | Initialization, module loader, minimap button, slash commands |
| Database | `DB.lua` | SavedVariables management, per-character profiles, migration |
| Zone Info | `ZoneInfo.lua` | Zone level ranges, fishing skill data, town/city icon hiding |
| Coordinates | `Coords.lua` | Cursor and player coordinate display |
| Fog Clear | `FogClear.lua` | Unexplored area overlay rendering |
| Battle Map | `BattleMap.lua` | Battlefield minimap customization |
| Group Icons | `GroupIcons.lua` | Class-colored party/raid icons |
| Zoom | `Zoom.lua` | Scroll-to-zoom, drag-to-pan, frame scaling |
| POIs | `POIs.lua` | Points of interest database and rendering |
| Instance Maps | `InstanceMaps.lua` | Offline dungeon, raid, and battleground map viewing |
| Waypoints | `Waypoints.lua` | Navigation arrow, cross-zone routing, and path gates |
| Config | `Config.lua` | Options panel GUI |

---

## Key Bindings

You can bind the **Toggle Options Panel** command to a key in the game's Key Bindings menu, under the `CartoMapper` header.

---

## Credits

CartoMapper was built by analyzing and integrating database/coordinate work from these addons:

- **Mapster** — Overlay database format
- **Magnify-WotLK** — Zoom/pan framework
- **Leatrix Maps** — Coordinate system
- **MozzFullWorldMap** — Fog reveal data

---

## Support

If CartoMapper improves your experience, consider supporting development:

**[Buy Me A Coffee](https://buymeacoffee.com/zendevve)**
