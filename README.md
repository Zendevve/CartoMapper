# 🗺️ CartoMapper

**The Ultimate Map Enhancement Addon for World of Warcraft: Wrath of the Lich King (3.3.5a)**

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/zendevve)

---

## 🌟 The Vision & Craftsmanship

For years, WotLK players have had to choose between running multiple heavy, conflicting map addons or settling for Blizzard's clunky, outdated default map. 

**CartoMapper** was born from a desire for perfection. We meticulously reverse-engineered four of the greatest legacy map addons—**Mapster**, **Magnify-WotLK**, **Leatrix Maps**, and **MozzFullWorldMap**—deconstructing their databases and features, and stitching them back together into a single, cohesive, ultra-lightweight, and optimized master addon.

This isn't a copy-paste compilation. It required custom script compilers to port old BCC database keys to WotLK zone IDs, fixing 15-year-old Blizzard coordinate rendering bugs, and writing custom Lua overrides to prevent player pin drift during zoom and pan operations. Every line of code was crafted to ensure maximum frame rate and zero memory bloat.

---

## ✨ Features

*   🔍 **Smooth Scroll-to-Zoom & Drag-to-Pan**: Seamlessly zoom in towards your cursor and pan around the map. 
*   🎯 **Zero-Drift Scale Correction**: Map pins (player arrow, raid members, flags, corpse, vehicles) scale dynamically and remain *perfectly* anchored to their actual coordinate positions on zoom.
*   🧭 **High-Definition 2D Player Arrow**: Replaced the default 3D arrow with a high-definition 2D texture that clips properly inside the scroll viewport (so your arrow never awkwardly renders off the map edge).
*   🌫️ **FogClear (Reveal Unexplored Areas)**: Automatically renders unexplored map regions as transparent overlays. Includes custom color styling options.
*   📍 **Point of Interest (POI) Database**: Built-in coordinates for all dungeons, raids, flight paths, spirit healers, and zone transitions with interactive tooltips and click-to-transition map mechanics.
*   👥 **Class-Colored Group Icons**: Party and raid members are shown with class colors and subgroup numbers (1–8), complete with pulsing indicators for dead (grey), in-combat (red), and AFK (purple) states.
*   📐 **Cursor & Player Coordinates**: Lightweight, precise coordinates rendered at the bottom of the map.
*   🖥️ **Ctrl + Scroll Window Scaling**: Easily scale the windowed map frame size up or down on the fly.
*   ⚔️ **Borderless Battlefield Minimap (Shift+M)**: Hides bulky default borders and base tiles for a sleek, transparent overlay.

---

## ☕ Support the Journey (Why Donate?)

Building **CartoMapper** took dozens of hours of deep reverse-engineering, database translation, UI layout alignment, and client debugging. We believe that WotLK players deserve a modern, lag-free map experience without having to manage multiple bloated addons.

This project is completely free, open-source, and ad-free. If CartoMapper has saved you space in your addon folder, prevented UI performance hiccups, or made your journey through Azeroth and Northrend more enjoyable, please consider supporting the project:

### [👉 Click here to buy me a coffee! ☕](https://buymeacoffee.com/zendevve)

*Your support is incredibly meaningful. It allows me to dedicate time to maintaining this addon, fixing bugs, and developing future features for the classic community.*

---

## ⚙️ Installation

1.  Download the repository.
2.  Extract the `CartoMapper` folder to your WoW installation directory:
    `World of Warcraft\Interface\AddOns\`
3.  Ensure the folder is named exactly `CartoMapper` (not `CartoMapper-main`).
4.  Log into the game and enjoy a beautifully enhanced map!

---

## 🛠️ Slash Commands

Use `/cm` or `/cartomapper` in-game to manage settings:

*   `/cm status` — Displays the current status of all modular features.
*   `/cm toggle <option>` — Toggles a specific module.
    *   *Options*: `zoom`, `coords`, `battlemap`, `groupicons`, `fogclear`, `pois`
*   `/reload` — Reloads the UI to apply toggled module changes.

---

*Thank you for being part of the journey. See you in Azeroth!*
