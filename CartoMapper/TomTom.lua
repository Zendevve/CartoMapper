--[[--------------------------------------------------------------------------------------------
TomTom.lua
TomTom API compatibility shim.

Exposes a global `TomTom` global object that mimics the public methods of
the TomTom addon used by hundreds of third-party addons.  Each method
maps onto CartoMapper's native waypoints API (CartoMapper/modules["waypoints"]).

Reference: the same surface Carbonite implements in
refs/Carbonite/NxMap.lua:9907-10008 (function Nx:TT*).
--------------------------------------------------------------------------------------------]]--

local Shim = {}
CartoMapper.modules["tomTomShim"] = Shim

-- Stable handle → waypoint-record map.  TomTom returns numeric/unique IDs;
-- we keep a lookup so RemoveWaypoint can find the right wp.
Shim._handles = {}

local function ResolveZone(cont, zoneId)
    if not cont or not zoneId or cont <= 0 then return nil end
    local zones = { GetMapZones(cont) }
    return zones[zoneId]
end

local function BuildHandle(uid)
    return "tt_" .. tostring(uid) .. "_" .. tostring(GetTime()):gsub("%.", "_") .. "_" .. tostring(math.random(10000))
end

local function AddWaypointInternal(zoneName, x, y, name, callbacks)
    if not CartoMapper.DB.GetOpt("waypoints") then return nil end
    local waypoints = CartoMapper.modules["waypoints"]
    if not waypoints or not waypoints.Add then return nil end

    local handle = BuildHandle()
    local wp = {
        zone = zoneName,
        x = x,
        y = y,
        desc = name,
        id = handle,
    }
    waypoints.Add(wp, false)
    Shim._handles[handle] = {
        wp = wp,
        uid = callbacks and callbacks.uid or nil,
        radius = callbacks and callbacks.radius or nil,
        radiusFunc = callbacks and callbacks.radiusFunc or nil,
        customTitle = callbacks and callbacks.title or nil,
    }
    return handle
end

function Shim:AddWaypoint(x, y, desc, persistent, minimap, world)
    -- TomTom/MetaMap-style: no zone, so use the currently-shown (or current)
    -- zone.  SetMapToCurrentZone first so x/y make sense in the active map.
    SetMapToCurrentZone()
    local c = GetCurrentMapContinent()
    local z = GetCurrentMapZone()
    local zoneName = ResolveZone(c, z)
    if not zoneName then return nil end
    return AddWaypointInternal(zoneName, x, y, desc, nil)
end

function Shim:AddZWaypoint(cont, zoneId, x, y, name, persistent, minimap, world, callbacks)
    local zoneName = ResolveZone(cont, zoneId)
    if not zoneName then return nil end
    return AddWaypointInternal(zoneName, x, y, name, callbacks)
end

function Shim:SetCustomWaypoint(cont, zoneId, x, y, callbacks)
    return self:AddZWaypoint(cont, zoneId, x, y, nil, false, nil, nil, callbacks)
end

function Shim:SetCustomMFWaypoint(areaId, floor, x, y, opts)
    -- MF (multi-floor) variants pass x/y as 0..1 fractions; convert to 0..100
    -- percent to match CartoMapper's POI-scale coordinates.
    local pct = (opts and opts["percent"] ~= false) ~= false
    local px = pct and (x * 100) or x
    local py = pct and (y * 100) or y
    return self:SetCustomWaypoint(nil, areaId, px, py, opts)
end

function Shim:RemoveWaypoint(handle)
    if not handle then return end
    local rec = Shim._handles[handle]
    if not rec then return end
    local waypoints = CartoMapper.modules["waypoints"]
    if waypoints and waypoints.Remove and rec.wp then
        waypoints.Remove(rec.wp)
    end
    Shim._handles[handle] = nil
end

function Shim:SetCrazyArrow(handle, dist, title)
    if not handle then return end
    local rec = Shim._handles[handle]
    if not rec then return end
    rec.customTitle = title
    rec.radius = dist
    -- CartoMapper doesn't yet expose a "crazy arrow" analog (radius-based HUD
    -- pulsing).  Surface the values via the desc so the HUD will at least
    -- surface them as the waypoint label until a richer analog is added.
    if rec.wp then
        rec.wp.desc = title or rec.wp.desc
        if dist and rec.wp then
            rec.wp._crazyDist = dist
        end
    end
end

function Shim:ClearAllWaypoints(_persistent)
    local waypoints = CartoMapper.modules["waypoints"]
    if waypoints and waypoints.ClearAll then
        waypoints.ClearAll()
    end
    wipe(Shim._handles)
end

function Shim:DetectWaypoints() end -- no-op: CartoMapper shows all waypoints already

-- Publish the global TomTom object so other addons calling
-- `TomTom:AddZWaypoint(...)` get our shim instead of erroring.
-- Only publish if no real TomTom is loaded — we never want to override
-- a user's actual TomTom installation (it does much more than this shim).
if not _G["TomTom"] or type(_G["TomTom"]) ~= "table" or _G["TomTom"].AddZWaypoint == nil then
    _G["TomTom"] = Shim
end

return Shim
