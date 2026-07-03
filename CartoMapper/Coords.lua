--[[--------------------------------------------------------------------------------------------
Coords.lua
Coordinate display for the World Map.

Player speed and waypoint ETA are appended to the coordinate readout.
Speed uses the WoW yards-per-coordinate-unit constant (4.575) as documented
in Carbonite's PlyrSpeed calculation (refs/Carbonite/NxMap.lua:4368-4375).
--------------------------------------------------------------------------------------------]]--

local Coords = {}
CartoMapper.modules["coords"] = Coords
Coords.liveToggle = true

Coords.defaults = {
    coordsSpeed = true,
}

local coordstext

-- Speedometer state.  We track the previous player coordinate sample and
-- accumulated elapsed time so we can compute the smoothed (avg) yards/sec.
local prevPX, prevPY = nil, nil
local prevSampleTime = 0
local smoothedSpeed = 0
local SPEED_SAMPLE_INTERVAL = 250 -- ms; Carbonite samples every tmDif on a tight loop, 250ms matches WoW OnUpdate cadence

local function MouseXY()
    local left, top = WorldMapDetailFrame:GetLeft(), WorldMapDetailFrame:GetTop()
    local width, height = WorldMapDetailFrame:GetWidth(), WorldMapDetailFrame:GetHeight()
    local scale = WorldMapDetailFrame:GetEffectiveScale()

    if not left or not top or not width or not height or not scale then return nil, nil end

    local x, y = GetCursorPosition()
    local cx = (x/scale - left) / width
    local cy = (top - y/scale) / height

    if cx < 0 or cx > 1 or cy < 0 or cy > 1 then
        return nil, nil
    end

    if WorldMapScrollFrame and WorldMapScrollFrame:IsShown() and not WorldMapScrollFrame:IsMouseOver() then
        return nil, nil
    end

    return cx, cy
end

local function OnUpdate(self, elapsed)
    local cx, cy = MouseXY()
    local px, py = GetPlayerMapPosition("player")
    local acc = CartoMapper.DB.GetOpt("coordsAccuracy") or 1

    local pStr, cStr
    if px and px > 0 and py and py > 0 then
        pStr = string.format("P: %." .. acc .. "f, %." .. acc .. "f", px * 100, py * 100)
    end
    if cx then
        cStr = string.format("C: %." .. acc .. "f, %." .. acc .. "f", cx * 100, cy * 100)
    end

    local suffix = ""
    if CartoMapper.DB.GetOpt("coordsSpeed") and px and px > 0 and py and py > 0 then
        -- Compute instantaneous speed over the sample interval; collapse
        -- pathological jumps (mounts, teleports) into zero to avoid spikes.
        prevSampleTime = prevSampleTime + elapsed * 1000
        if prevSampleTime >= SPEED_SAMPLE_INTERVAL then
            if prevPX and prevPY then
                local dCoord = math.sqrt((px - prevPX) ^ 2 + (py - prevPY) ^ 2)
                local yardsTraveled = dCoord * 4.575 -- WoW yards per coordinate unit
                local dt = prevSampleTime / 1000
                if yardsTraveled < 100 and dt > 0 then
                    local instant = yardsTraveled / dt
                    smoothedSpeed = 0.85 * smoothedSpeed + 0.15 * instant
                else
                    smoothedSpeed = 0
                end
            end
            prevPX, prevPY = px, py
            prevSampleTime = 0
        end

        if smoothedSpeed > 0.5 then
            suffix = string.format("   %.1f yd/s", smoothedSpeed)

            -- Append ETA when a waypoint is active.  Compute top-down distance
            -- using the same 4.575 yards-unit constant.
            local waypoints = CartoMapper.modules["waypoints"]
            local active = waypoints and waypoints.GetActive and waypoints.GetActive()
            if active and active.zone then
                local playerZone = (function()
                    local c = GetCurrentMapContinent()
                    local z = GetCurrentMapZone()
                    if c > 0 and z > 0 then
                        local zones = { GetMapZones(c) }
                        return zones[z]
                    end
                    return nil
                end)()
                if playerZone == active.zone then
                    local dx = (active.x / 100 - px) * 4.575
                    local dy = (active.y / 100 - py) * 4.575
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist > 0 then
                        local eta = dist / smoothedSpeed
                        if eta > 3600 then
                            suffix = suffix .. string.format("   ETA %d:%02d:%02d", eta / 3600, (eta % 3600) / 60, eta % 60)
                        else
                            suffix = suffix .. string.format("   ETA %d:%02d", eta / 60, eta % 60)
                        end
                    end
                end
            end
        end
    else
        -- Reset speed state when no player position (loading screen, instance transition).
        prevPX, prevPY = nil, nil
        prevSampleTime = 0
        smoothedSpeed = 0
    end

    if pStr and cStr then
        coordstext:SetText(pStr .. "   " .. cStr .. suffix)
    elseif pStr then
        coordstext:SetText(pStr .. suffix)
    elseif cStr then
        coordstext:SetText(cStr)
    else
        coordstext:SetText("")
    end
end

local function UpdatePosition()
    if not coordstext then return end
    local display = _G["CartoMapper_CoordsFrame"]
    if not display then return end

    display:ClearAllPoints()
    if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        display:SetPoint("BOTTOM", WorldMapPositioningGuide, "BOTTOM", 0, -2)
    else
        display:SetPoint("BOTTOM", WorldMapPositioningGuide, "BOTTOM", 0, 10)
    end
    display:SetFrameLevel((WorldMapFrame:GetFrameLevel() or 1) + 15)

    coordstext:ClearAllPoints()
    coordstext:SetPoint("CENTER", display, "CENTER", 0, 0)
end

function Coords.Enable()
    if Coords.enabled then 
        local frame = _G["CartoMapper_CoordsFrame"]
        if frame then 
            frame:Show() 
            frame:SetFrameLevel((WorldMapFrame:GetFrameLevel() or 1) + 15)
        end
        return 
    end
    Coords.enabled = true

    local display = _G["CartoMapper_CoordsFrame"] or CreateFrame("Frame", "CartoMapper_CoordsFrame", WorldMapFrame)
    display:SetSize(400, 20)
    display:SetFrameLevel((WorldMapFrame:GetFrameLevel() or 1) + 15)

    if not coordstext then
        coordstext = display:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    end
    
    UpdatePosition()
    display:SetScript("OnUpdate", OnUpdate)
    display:Show()

    -- Update position when map changes sizes
    hooksecurefunc("WorldMapFrame_SetFullMapView", UpdatePosition)
    hooksecurefunc("WorldMapFrame_SetQuestMapView", UpdatePosition)
    hooksecurefunc("WorldMap_ToggleSizeDown", UpdatePosition)
    hooksecurefunc("WorldMap_ToggleSizeUp", UpdatePosition)
end

function Coords.Disable()
    local frame = _G["CartoMapper_CoordsFrame"]
    if frame then
        frame:Hide()
        frame:SetScript("OnUpdate", nil)
    end
end
