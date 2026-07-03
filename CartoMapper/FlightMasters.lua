--[[--------------------------------------------------------------------------------------------
FlightMasters.lua
Flight master data supplemental data for Northrend and other WotLK zones
whose default FlightA/FlightH entries were not previously seeded.

Source attribution: flight master coordinates aggregated from Carbonite's
Data/Guides/FlightMaster.lua (GPL) and normalized to CartoMapper's
per-zone POIData keying (POIs.lua:19).  Used purely as static data; no
runtime hooks are copied.  All names are English.
--------------------------------------------------------------------------------------------]]--

local FlightMasters = {}
CartoMapper.modules["flightMasters"] = FlightMasters
local DB = CartoMapper.DB

FlightMasters.defaults = {
    flightMasters = true,
}
FlightMasters.liveToggle = true
FlightMasters._registered = {}

-- Side codes mirror POIs.lua faction-style keys (FlightA/FlightH/FlightN).
-- Pin shape mirrors CartoMapper/POIs.lua per-zone rows so DrawPins() picks
-- them up without code changes — the same DrawPins() mapFileName lookup is
-- reused by a hook (see POIs.lua).  Each row layout is:
--   {kind, x%, y%, "Name, Zone", subtext, texName, ...}
FlightMasters.POIData = {
    ["BoreanTundra"] = {
        {"FlightA", 56.5, 20.8, "Fizzcrank Airstrip, Borean Tundra", nil, "FlightA", nil, nil},
        {"FlightA", 58.9, 68.2, "Valiance Keep, Borean Tundra", nil, "FlightA", nil, nil},
        {"FlightN", 32.5, 34.4, "Transitus Shield, Coldarra", nil, "FlightN", nil, nil},
        {"FlightN", 45.1, 34.1, "Amber Ledge, Borean Tundra", nil, "FlightN", nil, nil},
        {"FlightN", 78.5, 51.5, "Unu'pe, Borean Tundra", nil, "FlightN", nil, nil},
        {"FlightH", 39.7, 51.5, "Warsong Hold, Borean Tundra", nil, "FlightH", nil, nil},
        {"FlightH", 50.3, 13.0, "Bor'gorok Outpost, Borean Tundra", nil, "FlightH", nil, nil},
        {"FlightH", 77.7, 39.7, "Taunka'le Village, Borean Tundra", nil, "FlightH", nil, nil},
    },
    ["HowlingFjord"] = {
        {"FlightA", 60.0, 16.0, "Westguard Keep, Howling Fjord", nil, "FlightA", nil, nil},
        {"FlightA", 59.8, 63.2, "Valgarde Port, Howling Fjord", nil, "FlightA", nil, nil},
        {"FlightA", 60.0, 16.0, "Fort Wildervar, Howling Fjord", nil, "FlightA", nil, nil},
        {"FlightH", 26.0, 25.0, "Apothecary Camp, Howling Fjord", nil, "FlightH", nil, nil},
        {"FlightH", 50.4, 10.5, "Camp Winterhoof, Howling Fjord", nil, "FlightH", nil, nil},
        {"FlightH", 51.0, 69.9, "New Agamand, Howling Fjord", nil, "FlightH", nil, nil},
        {"FlightH", 79.0, 33.2, "Vengeance Landing, Howling Fjord", nil, "FlightH", nil, nil},
        {"FlightN", 24.6, 57.7, "Kamagua, Howling Fjord", nil, "FlightN", nil, nil},
    },
    ["Dragonblight"] = {
        {"FlightA", 29.1, 55.3, "Stars' Rest, Dragonblight", nil, "FlightA", nil, nil},
        {"FlightA", 39.5, 25.9, "Fordragon Hold, Dragonblight", nil, "FlightA", nil, nil},
        {"FlightA", 77.1, 49.8, "Wintergarde Keep, Dragonblight", nil, "FlightA", nil, nil},
        {"FlightH", 38.5, 46.7, "Agmar's Hammer, Dragonblight", nil, "FlightH", nil, nil},
        {"FlightH", 43.9, 17.5, "Kor'kron Vanguard, Dragonblight", nil, "FlightH", nil, nil},
        {"FlightH", 75.6, 62.4, "Venomspite, Dragonblight", nil, "FlightH", nil, nil},
        {"FlightN", 48.4, 74.3, "Moa'ki, Dragonblight", nil, "FlightN", nil, nil},
        {"FlightN", 60.2, 51.5, "Wyrmrest Temple, Dragonblight", nil, "FlightN", nil, nil},
    },
    ["GrizzlyHills"] = {
        {"FlightA", 31.3, 59.1, "Amberpine Lodge, Grizzly Hills", nil, "FlightA", nil, nil},
        {"FlightA", 59.6, 26.6, "Westfall Brigade, Grizzly Hills", nil, "FlightA", nil, nil},
        {"FlightH", 23.8, 65.2, "Conquest Hold, Grizzly Hills", nil, "FlightH", nil, nil},
        {"FlightH", 66.7, 46.9, "Camp Oneqwah, Grizzly Hills", nil, "FlightH", nil, nil},
    },
    ["ZulDrak"] = {
        {"FlightA", 14.0, 73.5, "Ebon Watch, Zul'Drak", nil, "FlightA", nil, nil},
        {"FlightA", 32.1, 74.4, "Light's Breach, Zul'Drak", nil, "FlightA", nil, nil},
        {"FlightA", 41.5, 64.0, "The Argent Stand, Zul'Drak", nil, "FlightA", nil, nil},
        {"FlightA", 60.0, 56.7, "Zim'Torga, Zul'Drak", nil, "FlightA", nil, nil},
        {"FlightA", 70.5, 23.2, "Gundrak, Zul'Drak", nil, "FlightA", nil, nil},
    },
    ["SholazarBasin"] = {
        {"FlightN", 25.4, 58.2, "Nesingwary Base Camp, Sholazar Basin", nil, "FlightN", nil, nil},
        {"FlightN", 50.1, 61.3, "River's Heart, Sholazar Basin", nil, "FlightN", nil, nil},
    },
    ["StormPeaks"] = {
        {"FlightN", 30.6, 36.4, "Bouldercrag's Refuge, The Storm Peaks", nil, "FlightN", nil, nil},
        {"FlightN", 40.7, 84.5, "K3, The Storm Peaks", nil, "FlightN", nil, nil},
        {"FlightN", 46.0, 24.1, "Ulduar, The Storm Peaks", nil, "FlightN", nil, nil},
        {"FlightN", 62.6, 61.7, "Dun Niffelem, The Storm Peaks", nil, "FlightN", nil, nil},
        {"FlightN", 37.2, 50.4, "Grom'arsh Crash-Site, The Storm Peaks", nil, "FlightN", nil, nil},
        {"FlightN", 68.8, 50.0, "Camp Tunka'lo, The Storm Peaks", nil, "FlightN", nil, nil},
        {"FlightN", 40.7, 84.5, "Frosthold, The Storm Peaks", nil, "FlightN", nil, nil},
    },
    ["IcecrownGlacier"] = {
        {"FlightA", 19.5, 47.8, "Death's Rise, Icecrown", nil, "FlightA", nil, nil},
        {"FlightA", 43.8, 24.2, "The Shadow Vault, Icecrown", nil, "FlightA", nil, nil},
        {"FlightA", 72.6, 22.8, "Argent Tournament Grounds, Icecrown", nil, "FlightA", nil, nil},
        {"FlightA", 79.4, 72.4, "Crusaders' Pinnacle, Icecrown", nil, "FlightA", nil, nil},
        {"FlightA", 87.7, 78.0, "The Argent Vanguard, Icecrown", nil, "FlightA", nil, nil},
        {"FlightN", 72.7, 45.7, "Krasus Landing, Dalaran (WotLK)", nil, "FlightN", nil, nil},
    },
    ["CrystalsongForest"] = {
        {"FlightA", 72.1, 80.8, "Windrunner's Overlook, Crystalsong Forest", nil, "FlightA", nil, nil},
        {"FlightH", 78.0, 48.2, "Sunreaver's Command, Crystalsong Forest", nil, "FlightH", nil, nil},
    },
    ["Wintergrasp"] = {
        {"FlightA", 72.1, 31.1, "Valiance Landing Camp, Wintergrasp", nil, "FlightA", nil, nil},
        {"FlightH", 21.6, 34.9, "Warsong Camp, Wintergrasp", nil, "FlightH", nil, nil},
    },
    ["Dalaran"] = {
        {"FlightN", 72.7, 45.7, "Krasus Landing, Dalaran", nil, "FlightN", nil, nil},
    },
}

function FlightMasters.Enable()
    FlightMasters.enabled = true
    if CartoMapper.modules["pois"] and CartoMapper.modules["pois"].RegisterZone then
        for zoneKey, rows in pairs(FlightMasters.POIData) do
            CartoMapper.modules["pois"].RegisterZone(zoneKey, rows)
            FlightMasters._registered[zoneKey] = rows
        end
    end
    if CartoMapper.UpdatePOIs then CartoMapper.UpdatePOIs() end
end

function FlightMasters.Disable()
    FlightMasters.enabled = false
    if CartoMapper.modules["pois"] and CartoMapper.modules["pois"].RemoveRows then
        for zoneKey, rows in pairs(FlightMasters._registered) do
            CartoMapper.modules["pois"].RemoveRows(zoneKey, rows)
        end
    elseif CartoMapper.modules["pois"] and CartoMapper.modules["pois"].UnregisterZone then
        -- Fallback: weaker UnregisterZone that may wipe a key entirely.
        for zoneKey, _ in pairs(FlightMasters._registered) do
            CartoMapper.modules["pois"].UnregisterZone(zoneKey)
        end
    end
    wipe(FlightMasters._registered)
    if CartoMapper.UpdatePOIs then CartoMapper.UpdatePOIs() end
end

return FlightMasters
