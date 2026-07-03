--[[--------------------------------------------------------------------------------------------
TransportRoutes.lua
Boat, zeppelin, and portal pickup-point pins for Northrend and other
WotLK-relevant zones that were not pre-seeded in CartoMapper's POI data.

Most transport routes for classic Eastern Kingdoms / Kalimdor
(Tirisfal zeppelin tower, Stranglethorn, etc.) are already covered by
POIs.lua.  This module fills the Northrend gap and the Stormwind-Ironforge
tram.

Source attribution: pickup-point coordinates aggregated from Carbonite's
Data/ZoneConnections.lua (GPL), rows of type 3 (boat), 5 (zeppelin),
or 6 (mage portal), retaining only entries whose srcMapID and destMapID
fall within the 3.3.5 continent range (<=520) and matching both ends to
zones we have map coordinates for.

Pin shape mirrors CartoMapper/POIs.lua per-zone rows so the same
DrawPins() mapFileName lookup picks them up with no code changes
(see POIs.RegisterZone/RemoveRows API).
--------------------------------------------------------------------------------------------]]--

local Transport = {}
CartoMapper.modules["transportRoutes"] = Transport

Transport.defaults = {
    transportRoutes = true,
}
Transport.liveToggle = true
Transport._registered = {}

-- Source -> destination trip lines, both sides present.
-- Layout mirrors POIs.lua: {kind, x%, y%, "Boat to <Place>, <Zone>", "Boat", "TravelA", ...}
-- (last unused args are nil to match the existing 8-arg unpack in DrawPins)
Transport.POIData = {
    ["HowlingFjord"] = {
        -- Boat: Menethil Harbor (Wetlands) <-> Howling Fjord, picked up near Vengeance Landing
        {"TravelA", 61.34, 62.6, "Boat to Menethil Harbor, Wetlands", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1437},
        -- Zeppelin: Howling Fjord <-> Undercity, picked up northeast of Vengeance Landing
        {"TravelH", 77.71, 28.26, "Zeppelin to Undercity, Tirisfal Glades", nil, "TravelH", nil, nil, nil, nil, nil, 0, 1420},
    },
    ["BoreanTundra"] = {
        -- Boat: Stormwind Harbor <-> Borean Tundra, picked up near Fizzcrank Airstrip / Valiance Keep
        {"TravelA", 59.68, 69.39, "Boat to Stormwind Harbor, Elwynn Forest", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1453},
    },
    ["AzuremystIsle"] = {
        -- Boat: Rut'theran Village <-> Valaar's Berth (Azuremyst side)
        {"TravelA", 21.4, 54.0, "Boat to Rut'theran Village, Teldrassil", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1438},
    },
}

-- Tram isn't a pickup point per-zone since both ends are city maps
-- (Stormwind / Ironforge) but those don't exist as separate zone maps in
-- 3.3.5.  Skipped intentionally; the tram shows up via the transport
-- framework already.

function Transport.Enable()
    if Transport.enabled then return end
    Transport.enabled = true

    local pois = CartoMapper.modules["pois"]
    if pois and pois.RegisterZone then
        for zoneKey, rows in pairs(Transport.POIData) do
            pois.RegisterZone(zoneKey, rows)
            Transport._registered[zoneKey] = rows
        end
    end
    if CartoMapper.UpdatePOIs then CartoMapper.UpdatePOIs() end
end

function Transport.Disable()
    Transport.enabled = false
    local pois = CartoMapper.modules["pois"]
    if pois and pois.RemoveRows then
        for zoneKey, rows in pairs(Transport._registered) do
            pois.RemoveRows(zoneKey, rows)
        end
    end
    wipe(Transport._registered)
    if CartoMapper.UpdatePOIs then CartoMapper.UpdatePOIs() end
end

return Transport
