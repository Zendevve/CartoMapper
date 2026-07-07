--[[--------------------------------------------------------------------------------------------
Waypoints.lua
Waypoints and navigation system (TomTom replacement).
--------------------------------------------------------------------------------------------]]--

local Waypoints = {}
CartoMapper.modules["waypoints"] = Waypoints
Waypoints.liveToggle = true

Waypoints.defaults = {
    waypoints = true,
    waypointsArrowX = nil,
    waypointsArrowY = nil,
    waypointsArrivalDist = 15,
    waypointsArrowScale = 1.0,
    waypointsArrowAlpha = 1.0,
    waypointsShowETA = true,
    corpseTracker = true,
    arrivalSound = true,
    finalArrivalSoundPath = "Sound\\Interface\\RaidWarning.wav",
    gateArrivalSoundPath = "Sound\\Interface\\LevelUp.wav",
}

-- Internal state
local activeWaypoints = {}
local pinPool = {}
local arrowFrame = nil
local zoneMapList = {}

-- Approximate zone sizes in yards (fallback defaults)
local zoneWidth = 2000
local zoneHeight = 1333

local function GetYardVectors(x1, y1, x2, y2)
    local dx = (x2 - x1) * zoneWidth
    local dy = (y2 - y1) * zoneHeight * 1.5
    return dx, dy
end

local function GetDistanceInYards(x1, y1, x2, y2)
    local dx, dy = GetYardVectors(x1, y1, x2, y2)
    return math.sqrt(dx*dx + dy*dy)
end

-- Absolute Zone Transitions and Cities Portal Database
local zoneTransitions = {
    -- Eastern Kingdoms:
    ["Elwynn Forest"] = {
        ["Westfall"] = { x = 0.5, y = 73.4 },
        ["Duskwood"] = { x = 70.0, y = 92.0 },
        ["Redridge Mountains"] = { x = 94.0, y = 72.0 },
        ["Stormwind City"] = { x = 32.0, y = 50.0 },
    },
    ["Westfall"] = {
        ["Elwynn Forest"] = { x = 95.0, y = 34.0 },
        ["Duskwood"] = { x = 86.0, y = 47.0 },
    },
    ["Duskwood"] = {
        ["Elwynn Forest"] = { x = 50.0, y = 14.0 },
        ["Westfall"] = { x = 18.0, y = 32.0 },
        ["Redridge Mountains"] = { x = 82.0, y = 30.0 },
        ["Stranglethorn Vale"] = { x = 46.0, y = 87.0 },
    },
    ["Redridge Mountains"] = {
        ["Elwynn Forest"] = { x = 16.0, y = 83.0 },
        ["Duskwood"] = { x = 27.0, y = 87.0 },
        ["Burning Steppes"] = { x = 35.0, y = 23.0 },
    },
    ["Burning Steppes"] = {
        ["Redridge Mountains"] = { x = 80.0, y = 85.0 },
        ["Searing Gorge"] = { x = 23.0, y = 25.0 },
    },
    ["Searing Gorge"] = {
        ["Burning Steppes"] = { x = 35.0, y = 85.0 },
        ["Badlands"] = { x = 85.0, y = 60.0 },
    },
    ["Badlands"] = {
        ["Searing Gorge"] = { x = 15.0, y = 60.0 },
        ["Loch Modan"] = { x = 45.0, y = 15.0 },
    },
    ["Loch Modan"] = {
        ["Badlands"] = { x = 45.0, y = 85.0 },
        ["Dun Morogh"] = { x = 18.0, y = 50.0 },
        ["Wetlands"] = { x = 45.0, y = 10.0 },
    },
    ["Dun Morogh"] = {
        ["Loch Modan"] = { x = 85.0, y = 45.0 },
        ["Ironforge"] = { x = 62.0, y = 35.0 },
    },
    ["Wetlands"] = {
        ["Loch Modan"] = { x = 45.0, y = 90.0 },
        ["Arathi Highlands"] = { x = 50.0, y = 10.0 },
    },
    ["Arathi Highlands"] = {
        ["Wetlands"] = { x = 50.0, y = 90.0 },
        ["Hillsbrad Foothills"] = { x = 15.0, y = 45.0 },
    },
    ["Hillsbrad Foothills"] = {
        ["Arathi Highlands"] = { x = 85.0, y = 45.0 },
        ["The Hinterlands"] = { x = 85.0, y = 25.0 },
        ["Silverpine Forest"] = { x = 15.0, y = 45.0 },
        ["Alterac Mountains"] = { x = 45.0, y = 20.0 },
    },
    ["The Hinterlands"] = {
        ["Hillsbrad Foothills"] = { x = 15.0, y = 75.0 },
    },
    ["Silverpine Forest"] = {
        ["Hillsbrad Foothills"] = { x = 85.0, y = 45.0 },
        ["Tirisfal Glades"] = { x = 45.0, y = 10.0 },
        ["Ruins of Gilneas"] = { x = 45.0, y = 90.0 },
    },
    ["Tirisfal Glades"] = {
        ["Silverpine Forest"] = { x = 45.0, y = 90.0 },
        ["Western Plaguelands"] = { x = 85.0, y = 60.0 },
        ["Undercity"] = { x = 60.0, y = 65.0 },
    },
    ["Western Plaguelands"] = {
        ["Tirisfal Glades"] = { x = 15.0, y = 60.0 },
        ["Eastern Plaguelands"] = { x = 85.0, y = 60.0 },
    },
    ["Eastern Plaguelands"] = {
        ["Western Plaguelands"] = { x = 15.0, y = 60.0 },
    },
    ["Stranglethorn Vale"] = {
        ["Duskwood"] = { x = 36.0, y = 8.0 },
    },
    
    -- Major City Portals/Trams
    ["Stormwind City"] = {
        ["Ironforge"] = { x = 60.0, y = 60.0 },
        ["Elwynn Forest"] = { x = 75.0, y = 75.0 },
    },
    ["Ironforge"] = {
        ["Stormwind City"] = { x = 60.0, y = 60.0 },
        ["Dun Morogh"] = { x = 50.0, y = 50.0 },
    },
    ["Undercity"] = {
        ["Tirisfal Glades"] = { x = 50.0, y = 50.0 },
    },

    -- Kalimdor:
    ["Durotar"] = {
        ["Orgrimmar"] = { x = 45.0, y = 10.0 },
        ["The Barrens"] = { x = 15.0, y = 45.0 },
    },
    ["Orgrimmar"] = {
        ["Durotar"] = { x = 50.0, y = 80.0 },
    },
    ["The Barrens"] = {
        ["Durotar"] = { x = 85.0, y = 45.0 },
        ["Mulgore"] = { x = 45.0, y = 55.0 },
        ["Stonetalon Mountains"] = { x = 45.0, y = 25.0 },
        ["Ashenvale"] = { x = 50.0, y = 10.0 },
        ["Thousand Needles"] = { x = 45.0, y = 90.0 },
        ["Dustwallow Marsh"] = { x = 75.0, y = 65.0 },
    },
    ["Mulgore"] = {
        ["The Barrens"] = { x = 85.0, y = 50.0 },
        ["Thunder Bluff"] = { x = 45.0, y = 45.0 },
    },
    ["Thunder Bluff"] = {
        ["Mulgore"] = { x = 50.0, y = 50.0 },
    },
    ["Ashenvale"] = {
        ["The Barrens"] = { x = 50.0, y = 90.0 },
        ["Stonetalon Mountains"] = { x = 35.0, y = 80.0 },
        ["Darkshore"] = { x = 35.0, y = 15.0 },
        ["Azshara"] = { x = 85.0, y = 60.0 },
    },
    ["Darkshore"] = {
        ["Ashenvale"] = { x = 45.0, y = 90.0 },
    },
    ["Stonetalon Mountains"] = {
        ["The Barrens"] = { x = 75.0, y = 80.0 },
        ["Ashenvale"] = { x = 45.0, y = 20.0 },
    },
    ["Dustwallow Marsh"] = {
        ["The Barrens"] = { x = 25.0, y = 35.0 },
    },
    ["Thousand Needles"] = {
        ["The Barrens"] = { x = 45.0, y = 15.0 },
        ["Tanaris"] = { x = 80.0, y = 85.0 },
    },
    ["Tanaris"] = {
        ["Thousand Needles"] = { x = 15.0, y = 15.0 },
        ["Un'Goro Crater"] = { x = 25.0, y = 45.0 },
    },
    ["Un'Goro Crater"] = {
        ["Tanaris"] = { x = 85.0, y = 45.0 },
        ["Silithus"] = { x = 15.0, y = 45.0 },
    },
    ["Silithus"] = {
        ["Un'Goro Crater"] = { x = 85.0, y = 45.0 },
    },
}

-- Case-Insensitive BFS Zone Pathfinder
local function FindZonePath(startZone, endZone)
    if not startZone or not endZone then return nil end
    local s = string.lower(startZone)
    local e = string.lower(endZone)
    if s == e then
        return { startZone }
    end
    
    local queue = { { startZone } }
    local visited = { [s] = true }
    
    while #queue > 0 do
        local path = table.remove(queue, 1)
        local current = path[#path]
        local currentLower = string.lower(current)
        
        local connections = nil
        for k, v in pairs(zoneTransitions) do
            if string.lower(k) == currentLower then
                connections = v
                break
            end
        end
        
        if connections then
            for neighbor, _ in pairs(connections) do
                local nLower = string.lower(neighbor)
                if nLower == e then
                    local newPath = { unpack(path) }
                    table.insert(newPath, neighbor)
                    return newPath
                elseif not visited[nLower] then
                    visited[nLower] = true
                    local newPath = { unpack(path) }
                    table.insert(newPath, neighbor)
                    table.insert(queue, newPath)
                end
            end
        end
    end
    return nil
end

-- Track flying capabilities on player loading / continental requirements
function Waypoints.CheckFlyingCapability()
    local isCapable = false
    local continent = GetCurrentMapContinent()
    
    if continent == 3 then -- Outland
        isCapable = IsSpellKnown(34090) or IsSpellKnown(34091)
    elseif continent == 4 then -- Northrend
        isCapable = IsSpellKnown(54197)
    end
    
    Waypoints.isFlyingCapable = isCapable
    return isCapable
end

-- Builds a list of zone names to easily lookup ID and continent
local function BuildZoneMap()
    if next(zoneMapList) then return end
    local continents = { GetMapContinents() }
    for cId, cName in ipairs(continents) do
        local zones = { GetMapZones(cId) }
        for zId, zName in ipairs(zones) do
            zoneMapList[string.lower(zName)] = { continent = cId, zoneIndex = zId, name = zName }
        end
    end
end

-- Find a zone dynamically using fuzzy matching
local function GetZoneInfoByName(name)
    if not name or name == "" then return nil end
    local lowerName = string.lower(name)
    BuildZoneMap()
    
    if zoneMapList[lowerName] then
        return zoneMapList[lowerName]
    end
    
    for k, v in pairs(zoneMapList) do
        if string.find(k, lowerName, 1, true) then
            return v
        end
    end
    return nil
end

-- Pin Scaling handler to ensure map pins are not bloated when zooming in
local function UpdatePinScales()
    if not WorldMapDetailFrame then return end
    local detailScale = WorldMapDetailFrame:GetScale() or 1.0
    local scrollScale = WORLDMAP_SETTINGS.size
    if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE and CartoMapper.DB.GetOpt("borderless") then
        scrollScale = 1.0
    end
    local pinScale = 1 / (detailScale * scrollScale)
    for _, pin in ipairs(pinPool) do
        if pin:IsShown() and pin.origX and pin.origY then
            pin:SetScale(pinScale)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", pin.origX * detailScale, pin.origY * detailScale)
        end
    end
end

-- Refreshes the red waypoint pin overlays on the world map
function Waypoints.UpdateMapPins()
    -- Hide all pins in the pool first
    for _, pin in ipairs(pinPool) do
        pin:Hide()
    end
    
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    if not CartoMapper.DB.GetOpt("waypoints") then return end
    
    local currentContinent = GetCurrentMapContinent()
    local currentZone = GetCurrentMapZone()
    
    -- Handle continent or cosmic maps
    if currentContinent <= 0 or currentZone <= 0 then return end
    
    local zones = { GetMapZones(currentContinent) }
    local zName = zones[currentZone]
    if not zName then return end
    
    local pinIndex = 1
    local w = WorldMapDetailFrame:GetWidth()
    local h = WorldMapDetailFrame:GetHeight()
    local detailScale = WorldMapDetailFrame:GetScale() or 1.0
    
    for _, wp in ipairs(activeWaypoints) do
        if wp.zone == zName then
            local pin = Waypoints.GetPinFrame(pinIndex)
            pin.wp = wp
            
            if wp.isGate then
                pin.texture:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
                pin:SetSize(28, 28)
            else
                pin.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                pin:SetSize(38, 38)
            end
            
            local x = (wp.x / 100) * w
            local y = -(wp.y / 100) * h
            pin.origX = x
            pin.origY = y
            
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", x * detailScale, y * detailScale)
            pin:Show()
            
            pinIndex = pinIndex + 1
        end
    end
    
    UpdatePinScales()
end

-- Get or instantiate a pin from the frame pool
function Waypoints.GetPinFrame(index)
    if not pinPool[index] then
        local pin = CreateFrame("Button", "CartoMapper_WaypointPin" .. index, WorldMapDetailFrame)
        pin:SetSize(38, 38)
        pin:SetFrameLevel(WorldMapDetailFrame:GetFrameLevel() + 20)
        pin:RegisterForClicks("AnyUp")
        
        local tex = pin:CreateTexture(nil, "OVERLAY")
        tex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up") -- Red Cross
        tex:SetAllPoints(pin)
        pin.texture = tex
        
        pin:SetScript("OnEnter", function(self)
            WorldMapTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
            WorldMapTooltip:ClearLines()
            if self.wp.desc then
                WorldMapTooltip:AddLine(self.wp.desc, 1, 1, 1)
                WorldMapTooltip:AddLine(string.format("%s (%.1f, %.1f)", self.wp.zone, self.wp.x, self.wp.y), 0.8, 0.8, 0.8)
            else
                WorldMapTooltip:AddLine(string.format("Waypoint (%.1f, %.1f)", self.wp.x, self.wp.y), 1, 1, 1)
            end
            WorldMapTooltip:AddLine("Left-click to navigate | Right-click to remove", 0.5, 0.5, 0.5)
            WorldMapTooltip:Show()
            
            if WorldMapTooltip:GetFrameStrata() ~= "TOOLTIP" then
                WorldMapTooltip:SetFrameStrata("TOOLTIP")
            end
        end)
        
        pin:SetScript("OnLeave", function(self)
            WorldMapTooltip:Hide()
        end)
        
        pin:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                WorldMapTooltip:Hide()
                local wp = self.wp
                local f = CreateFrame("Frame")
                f:SetScript("OnUpdate", function(self)
                    self:SetScript("OnUpdate", nil)
                    Waypoints.Remove(wp)
                end)
            elseif button == "LeftButton" then
                WorldMapTooltip:Hide()
                Waypoints.SetActive(self.wp)
            end
        end)
        
        pinPool[index] = pin
    end
    return pinPool[index]
end

local function GetColorGradient(perc)
    -- Interpolate between Red (1.0, 0.1, 0.1), Yellow (1.0, 1.0, 0.1), and Green (0.1, 1.0, 0.1)
    if perc >= 0.5 then
        -- Interpolate between Yellow (0.5) and Green (1.0)
        local factor = (perc - 0.5) * 2 -- 0 to 1
        local r = 1.0 - 0.9 * factor
        local g = 1.0
        local b = 0.1
        return r, g, b
    else
        -- Interpolate between Red (0.0) and Yellow (0.5)
        local factor = perc * 2 -- 0 to 1
        local r = 1.0
        local g = 0.1 + 0.9 * factor
        local b = 0.1
        return r, g, b
    end
end

-- Navigation HUD Arrow Update loop
local last_active_wp_id = nil
local last_px, last_py = nil, nil
local last_zone = nil
local smoothed_speed = 0
local lastUpdate = 0

local function Arrow_OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < 0.05 then return end
    
    -- Hide arrow in instances (dungeons, raids, battlegrounds)
    if IsInInstance() then
        lastUpdate = 0
        self:Hide()
        return
    end
    
    local wp = Waypoints.GetActive()
    if not wp then
        lastUpdate = 0
        self:Hide()
        return
    end
    
    -- Apply user-configured arrow scale and alpha
    local arrowScale = CartoMapper.DB.GetOpt("waypointsArrowScale") or 1.0
    local arrowAlpha = CartoMapper.DB.GetOpt("waypointsArrowAlpha") or 1.0
    self:SetScale(arrowScale)
    self:SetAlpha(arrowAlpha)
    
    local px, py = GetPlayerMapPosition("player")
    if not px or px == 0 or py == 0 then
        lastUpdate = 0
        self.text:SetText("No Position Signal")
        self.arrowTex:SetRotation(0)
        self.arrowTex:SetVertexColor(0.6, 0.6, 0.6, 0.6)
        last_px, last_py = nil, nil
        return
    end
    
    -- Check if player is in the same zone as target waypoint
    local continents = { GetMapContinents() }
    local currentContinent = GetCurrentMapContinent()
    local currentZone = GetCurrentMapZone()
    if currentContinent <= 0 or currentZone <= 0 then
        lastUpdate = 0
        self.text:SetText(string.format("Go to:\n%s", wp.zone))
        self.arrowTex:SetRotation(0)
        self.arrowTex:SetVertexColor(0.6, 0.6, 0.6, 0.6)
        last_px, last_py = nil, nil
        return
    end
    
    local zones = { GetMapZones(currentContinent) }
    local playerZoneName = zones[currentZone]
    
    -- Auto-pruning of bypassed gates
    if wp.isGate and playerZoneName then
        local foundCurrentZoneGateIndex = nil
        for i, w in ipairs(activeWaypoints) do
            if w.zone == playerZoneName then
                foundCurrentZoneGateIndex = i
                break
            end
        end
        
        local foundTargetIndex = nil
        for i, w in ipairs(activeWaypoints) do
            if not w.isGate and w.zone == playerZoneName then
                foundTargetIndex = i
                break
            end
        end
        
        if foundTargetIndex then
            -- Player reached the final zone! Remove all intermediate gates for this target
            for i = foundTargetIndex - 1, 1, -1 do
                local w = activeWaypoints[i]
                if w.isGate then
                    table.remove(activeWaypoints, i)
                end
            end
            CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
            last_px, last_py = nil, nil
            smoothed_speed = 0
            return
        elseif foundCurrentZoneGateIndex and foundCurrentZoneGateIndex > 1 then
            -- Player skipped ahead to a later gate in the queue!
            -- Remove all preceding gates
            for i = foundCurrentZoneGateIndex - 1, 1, -1 do
                local w = activeWaypoints[i]
                if w.isGate then
                    table.remove(activeWaypoints, i)
                end
            end
            CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
            last_px, last_py = nil, nil
            smoothed_speed = 0
            return
        end
    end
    
    if playerZoneName ~= wp.zone then
        -- If flying is capable, allow pointing directly to destination across zone boundaries
        if not Waypoints.CheckFlyingCapability() then
            lastUpdate = 0
            self.text:SetText(string.format("Go to:\n%s", wp.zone))
            self.arrowTex:SetRotation(0)
            self.arrowTex:SetVertexColor(0.6, 0.6, 0.6, 0.6)
            last_px, last_py = nil, nil
            return
        end
    end
    
    -- Reset tracking state on zone changes or target changes
    if last_zone ~= currentZone or last_active_wp_id ~= wp.id then
        last_zone = currentZone
        last_active_wp_id = wp.id
        last_px, last_py = nil, nil
        smoothed_speed = 0
    end
    
    -- Running velocity filter (calculate speed based on actual coordinates displacement)
    if last_px and last_py then
        local moveDist = GetDistanceInYards(last_px, last_py, px, py)
        local dt = lastUpdate
        if dt > 0 then
            -- Avoid speed spikes from teleports, zoning, or jumps (threshold 100 yards)
            if moveDist < 100 then
                local instant_speed = moveDist / dt
                -- Running filter: 0.85 old + 0.15 new
                smoothed_speed = 0.85 * smoothed_speed + 0.15 * instant_speed
            else
                smoothed_speed = 0
            end
        end
    else
        smoothed_speed = 0
    end
    last_px, last_py = px, py
    
    local dist = GetDistanceInYards(px, py, wp.x / 100, wp.y / 100)
    
    -- Check if reached (within configurable arrival distance)
    -- Skip auto-clear if player is on a taxi/flight path
    local arrivalDist = CartoMapper.DB.GetOpt("waypointsArrivalDist") or 15
    if dist < arrivalDist and not UnitOnTaxi("player") then
        if wp.isCorpse and not UnitIsGhost("player") then
            -- Skip clearing it since they haven't released their spirit (are not a ghost) yet
        else
            lastUpdate = 0
            if CartoMapper.DB.GetOpt("arrivalSound") then
                if wp.isGate then
                    local gateSound = CartoMapper.DB.GetOpt("gateArrivalSoundPath") or "Sound\\Interface\\LevelUp.wav"
                    PlaySoundFile(gateSound)
                else
                    local finalSound = CartoMapper.DB.GetOpt("finalArrivalSoundPath") or "Sound\\Interface\\RaidWarning.wav"
                    PlaySoundFile(finalSound)
                end
            end
            UIErrorsFrame:AddMessage("Waypoint Reached!", 0.1, 1.0, 0.1, 1.0, 5)
            print("|cff00ff00[CartoMapper] Reached Waypoint: " .. (wp.desc or string.format("%.1f, %.1f", wp.x, wp.y)) .. "|r")
            Waypoints.Remove(wp)
            return
        end
    end
    
    lastUpdate = 0
    
    -- Calculate yaw rotation using corrected aspect ratio vectors
    local target_x, target_y = wp.x / 100, wp.y / 100
    local dx = (target_x - px) * zoneWidth
    local dy = (py - target_y) * zoneHeight * 1.5
    
    local targetAngle = math.atan2(dx, dy)
    local facing = GetPlayerFacing() or 0
    local rotation = -(targetAngle + facing)
    
    self.arrowTex:SetRotation(rotation)
    
    -- Calculate relative angle difference (-pi to pi)
    local relAngle = rotation % (math.pi * 2)
    if relAngle > math.pi then
        relAngle = relAngle - math.pi * 2
    elseif relAngle < -math.pi then
        relAngle = relAngle + math.pi * 2
    end
    
    -- Dynamic colors: Green (<10 degrees), Yellow (<45 degrees), Red (>45 degrees)
    -- Interpolate smoothly between states
    local deviation = math.abs(relAngle)
    local r, g, b
    if deviation < 0.1745 then
        -- Green
        r, g, b = 0.1, 1.0, 0.1
    elseif deviation < 0.7854 then
        -- Interpolate Green to Yellow
        local factor = (deviation - 0.1745) / (0.7854 - 0.1745)
        r = 0.1 + 0.9 * factor
        g = 1.0
        b = 0.1
    else
        -- Interpolate Yellow to Red
        local factor = (deviation - 0.7854) / (math.pi - 0.7854)
        r = 1.0
        g = 1.0 - 0.9 * factor
        b = 0.1
    end
    
    -- Apply ADD blend mode for soft glow when approaching (<60 yards)
    if dist < 60 then
        self.arrowTex:SetBlendMode("ADD")
        local glowAlpha = (1.0 - (dist / 60) * 0.6) * arrowAlpha
        self.arrowTex:SetVertexColor(r, g, b, glowAlpha)
    else
        self.arrowTex:SetBlendMode("BLEND")
        self.arrowTex:SetVertexColor(r, g, b, arrowAlpha)
    end
    
    -- Format distance and ETA
    local etaText = ""
    -- Only show ETA if we have positive speed (min threshold 0.5 yards/s)
    if CartoMapper.DB.GetOpt("waypointsShowETA") and smoothed_speed > 0.5 then
        local eta = dist / smoothed_speed
        if eta > 3600 then
            etaText = string.format(" (%d:%02d:%02d)", eta / 3600, (eta % 3600) / 60, eta % 60)
        else
            etaText = string.format(" (%d:%02d)", eta / 60, eta % 60)
        end
    end
    
    local distText = string.format("%d yards%s", math.floor(dist), etaText)
    if wp.desc then
        self.text:SetText(string.format("%s\n%s", wp.desc, distText))
    else
        self.text:SetText(string.format("Waypoint (%.1f, %.1f)\n%s", wp.x, wp.y, distText))
    end
end

local function SetClosestWaypoint()
    SetMapToCurrentZone()
    local px, py = GetPlayerMapPosition("player")
    if not px or px == 0 or py == 0 then return nil end
    
    local c = GetCurrentMapContinent()
    local z = GetCurrentMapZone()
    if c <= 0 or z <= 0 then return nil end
    local zones = { GetMapZones(c) }
    local currentZoneName = zones[z]
    if not currentZoneName then return nil end
    
    local closestWp = nil
    local minDistance = math.huge
    
    for _, wp in ipairs(activeWaypoints) do
        if wp.zone == currentZoneName then
            local dist = GetDistanceInYards(px, py, wp.x / 100, wp.y / 100)
            if dist < minDistance then
                minDistance = dist
                closestWp = wp
            end
        end
    end
    
    return closestWp
end

-- Dropdown Menu for Arrow Right-Click Actions
local arrowMenuFrame
function Waypoints.OpenArrowMenu()
    if not arrowMenuFrame then
        arrowMenuFrame = CreateFrame("Frame", "CartoMapper_ArrowMenuFrame", UIParent, "UIDropDownMenuTemplate")
    end
    
    local menuTable = {
        {
            text = "CartoMapper Navigation HUD",
            isTitle = true,
            notCheckable = true,
        },
        {
            text = "Clear Active Waypoint",
            notCheckable = true,
            func = function()
                local active = Waypoints.GetActive()
                if active then
                    Waypoints.Remove(active)
                end
            end
        },
        {
            text = "Clear All Waypoints",
            notCheckable = true,
            func = function()
                Waypoints.ClearAll()
            end
        },
        {
            text = "Lock HUD Arrow",
            checked = function() return CartoMapper.DB.GetOpt("lockMap") end,
            func = function()
                local val = CartoMapper.DB.GetOpt("lockMap")
                CartoMapper.DB.SetOpt("lockMap", not val)
            end
        },
        {
            text = "Show ETA Display",
            checked = function() return CartoMapper.DB.GetOpt("waypointsShowETA") end,
            func = function()
                local val = CartoMapper.DB.GetOpt("waypointsShowETA")
                CartoMapper.DB.SetOpt("waypointsShowETA", not val)
            end
        },
        {
            text = "Close Menu",
            notCheckable = true,
            func = function() end
        }
    }
    
    EasyMenu(menuTable, arrowMenuFrame, "cursor", 0, 0, "MENU")
end

-- Create the arrow frame
local function CreateArrowFrame()
    if arrowFrame then return end
    
    arrowFrame = CreateFrame("Frame", "CartoMapper_WaypointArrow", UIParent)
    arrowFrame:SetSize(64, 64)
    arrowFrame:SetFrameStrata("HIGH")
    arrowFrame:SetClampedToScreen(true)
    
    local x = CartoMapper.DB.GetOpt("waypointsArrowX")
    local y = CartoMapper.DB.GetOpt("waypointsArrowY")
    if x and y then
        arrowFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    else
        arrowFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end
    
    arrowFrame:SetMovable(true)
    arrowFrame:EnableMouse(true)
    arrowFrame:RegisterForDrag("LeftButton")
    arrowFrame:SetScript("OnDragStart", function(self)
        if not CartoMapper.DB.GetOpt("lockMap") then
            self:StartMoving()
        end
    end)
    arrowFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local left = self:GetLeft()
        local bottom = self:GetBottom()
        CartoMapper.DB.SetOpt("waypointsArrowX", left)
        CartoMapper.DB.SetOpt("waypointsArrowY", bottom)
    end)
    arrowFrame:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            Waypoints.OpenArrowMenu()
        end
    end)
    
    -- Add circular background backing
    local bg = arrowFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(60, 60)
    bg:SetPoint("CENTER", arrowFrame, "CENTER", 0, 0)
    bg:SetAlpha(0.6)
    arrowFrame.bg = bg
    
    -- Arrow Texture
    local tex = arrowFrame:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\AddOns\\CartoMapper\\assets\\WorldMapArrow")
    tex:SetSize(32, 32)
    tex:SetPoint("CENTER", arrowFrame, "CENTER", 0, 0)
    arrowFrame.arrowTex = tex
    
    -- Text Label
    local text = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("TOP", arrowFrame, "BOTTOM", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetTextColor(1, 1, 1, 1)
    arrowFrame.text = text
    
    arrowFrame:SetScript("OnUpdate", Arrow_OnUpdate)
end

-- API Lifecycle
function Waypoints.Enable()
    Waypoints.enabled = true
    
    -- Populate waypoints from DB
    activeWaypoints = {}
    local saved = CartoMapper.DB.GetOpt("waypointsList") or {}
    for _, wp in ipairs(saved) do
        table.insert(activeWaypoints, wp)
    end
    
    -- Register slash commands
    SLASH_CARTOMAPPER_WAY1 = "/way"
    SlashCmdList["CARTOMAPPER_WAY"] = function(msg)
        if not CartoMapper.DB.GetOpt("waypoints") then return end
        Waypoints.HandleSlashCommand(msg)
    end
    
    SLASH_CARTOMAPPER_WAYBACK1 = "/wayback"
    SLASH_CARTOMAPPER_WAYBACK2 = "/wayb"
    SlashCmdList["CARTOMAPPER_WAYBACK"] = function()
        if not CartoMapper.DB.GetOpt("waypoints") then return end
        Waypoints.WayBack()
    end
    
    SLASH_CARTOMAPPER_CLOSEST1 = "/cway"
    SLASH_CARTOMAPPER_CLOSEST2 = "/closestway"
    SlashCmdList["CARTOMAPPER_CLOSEST"] = function()
        if not CartoMapper.DB.GetOpt("waypoints") then return end
        local closest = SetClosestWaypoint()
        if closest then
            Waypoints.SetActive(closest)
            print("|cff00ff00[CartoMapper] Active waypoint set to closest: " .. (closest.desc or string.format("%.1f, %.1f", closest.x, closest.y)) .. "|r")
        else
            print("|cffff0000[CartoMapper] No waypoints found in your current zone.|r")
        end
    end
    
    -- Setup secure hooks for mapping
    if not Waypoints.hookedPOI then
        hooksecurefunc("WorldMapFrame_Update", Waypoints.UpdateMapPins)
        hooksecurefunc("WorldMapFrame_SetPOIMaxBounds", UpdatePinScales)
        Waypoints.hookedPOI = true
    end
    
    -- Initialize event listener for flying capability and death/corpse checks
    if not Waypoints.eventFrame then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("SPELLS_CHANGED")
        f:RegisterEvent("PLAYER_DEAD")
        f:RegisterEvent("PLAYER_ALIVE")
        f:RegisterEvent("PLAYER_UNGHOST")
        f:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED" then
                Waypoints.CheckFlyingCapability()
            elseif event == "PLAYER_DEAD" then
                if CartoMapper.DB.GetOpt("corpseTracker") then
                    SetMapToCurrentZone()
                    local c = GetCurrentMapContinent()
                    local z = GetCurrentMapZone()
                    local zoneName = nil
                    if c > 0 and z > 0 then
                        local zones = { GetMapZones(c) }
                        zoneName = zones[z]
                    end
                    
                    local cx, cy = GetCorpseMapPosition()
                    if not cx or cx == 0 or cy == 0 then
                        cx, cy = GetPlayerMapPosition("player")
                    end
                    
                    if cx and cx > 0 and cy and cy > 0 and zoneName then
                        -- Remove existing corpse waypoints first
                        for i = #activeWaypoints, 1, -1 do
                            local w = activeWaypoints[i]
                            if w.isCorpse then
                                table.remove(activeWaypoints, i)
                            end
                        end
                        
                        local corpseWp = {
                            zone = zoneName,
                            x = cx * 100,
                            y = cy * 100,
                            desc = "My Corpse",
                            id = GetTime() .. "_corpse_" .. math.random(1000),
                            isCorpse = true
                        }
                        
                        table.insert(activeWaypoints, corpseWp)
                        CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
                        Waypoints.SetActive(corpseWp)
                        if WorldMapFrame and WorldMapFrame:IsShown() then
                            Waypoints.UpdateMapPins()
                        end
                        print("|cff00ff00[CartoMapper] Corpse waypoint set! Arrow is guiding you to your body.|r")
                    end
                end
            elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
                local found = false
                for i = #activeWaypoints, 1, -1 do
                    local w = activeWaypoints[i]
                    if w.isCorpse then
                        table.remove(activeWaypoints, i)
                        found = true
                    end
                end
                if found then
                    CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
                    local active = Waypoints.GetActive()
                    if active then
                        Waypoints.SetActive(active)
                    else
                        if arrowFrame then arrowFrame:Hide() end
                    end
                    if WorldMapFrame and WorldMapFrame:IsShown() then
                        Waypoints.UpdateMapPins()
                    end
                end
            end
        end)
        Waypoints.eventFrame = f
    end
    Waypoints.CheckFlyingCapability()
    
    -- Create HUD frame if there is an active waypoint
    local activeWp = Waypoints.GetActive()
    if activeWp then
        CreateArrowFrame()
        if arrowFrame then arrowFrame:Show() end
    end
    
    Waypoints.UpdateMapPins()
end

function Waypoints.Disable()
    Waypoints.enabled = false
    
    if arrowFrame then
        arrowFrame:Hide()
    end
    
    for _, pin in ipairs(pinPool) do
        pin:Hide()
    end
    
    if Waypoints.eventFrame then
        Waypoints.eventFrame:UnregisterAllEvents()
        Waypoints.eventFrame = nil
    end
end

-- Slash command parser and processor
function Waypoints.HandleSlashCommand(msg)
    if not msg or msg == "" then
        print("|cffffd700[CartoMapper] Waypoints Usage:|r")
        print("  |cff00ff00/way [x] [y] [desc]|r - Add waypoint in current zone")
        print("  |cff00ff00/way [zone] [x] [y] [desc]|r - Add waypoint in target zone")
        print("  |cff00ff00/way clear|r - Clear all active waypoints")
        print("  |cff00ff00/wayback|r or |cff00ff00/wayb|r - Bookmark current position")
        return
    end
    
    msg = msg:trim()
    if string.lower(msg) == "clear" then
        Waypoints.ClearAll()
        return
    end
    
    local startIdx, endIdx, xStr, yStr = string.find(msg, "(%d+%.?%d*)%s+(%d+%.?%d*)")
    if not startIdx then
        print("|cffff0000[CartoMapper] Invalid coordinates format! Use /way [zone] x y [desc]|r")
        return
    end
    
    local zoneNamePart = string.sub(msg, 1, startIdx - 1):trim()
    local descPart = string.sub(msg, endIdx + 1):trim()
    local x = tonumber(xStr)
    local y = tonumber(yStr)
    
    if x < 0 or x > 100 or y < 0 or y > 100 then
        print("|cffff0000[CartoMapper] Coordinate coordinates must be between 0 and 100!|r")
        return
    end
    
    local targetZone = nil
    if zoneNamePart ~= "" then
        local zoneInfo = GetZoneInfoByName(zoneNamePart)
        if not zoneInfo then
            print(string.format("|cffff0000[CartoMapper] Zone '%s' could not be found!|r", zoneNamePart))
            return
        end
        targetZone = zoneInfo.name
    else
        -- Use map zone if map shown, else current zone
        SetMapToCurrentZone()
        local c = GetCurrentMapContinent()
        local z = GetCurrentMapZone()
        local zones = { GetMapZones(c) }
        targetZone = zones[z]
    end
    
    if not targetZone then
        print("|cffff0000[CartoMapper] Current zone could not be determined. Please write /way [zone] x y|r")
        return
    end
    
    local wp = {
        zone = targetZone,
        x = x,
        y = y,
        desc = (descPart ~= "") and descPart or nil,
        id = GetTime() .. "_" .. math.random(1000)
    }
    
    Waypoints.Add(wp)
end

-- Core Add/Remove/Clear operations
-- skipActivate: if true, the waypoint is saved but NOT set as the active arrow target
function Waypoints.Add(wp, skipActivate)
    -- Duplicate waypoint prevention: skip if same zone + coords (within 0.5) already exist
    for _, existing in ipairs(activeWaypoints) do
        if existing.zone == wp.zone and math.abs(existing.x - wp.x) < 0.5 and math.abs(existing.y - wp.y) < 0.5 then
            if not skipActivate then
                print(string.format("|cffffd700[CartoMapper] Waypoint already exists near (%.1f, %.1f) in %s. Setting as active.|r", wp.x, wp.y, wp.zone))
                Waypoints.SetActive(existing)
            else
                print(string.format("|cffffd700[CartoMapper] Waypoint already exists near (%.1f, %.1f) in %s.|r", wp.x, wp.y, wp.zone))
            end
            return
        end
    end
    
    if wp.isGate then
        table.insert(activeWaypoints, wp)
        CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
        if not skipActivate then
            Waypoints.SetActive(wp)
        end
        if WorldMapFrame and WorldMapFrame:IsShown() then
            Waypoints.UpdateMapPins()
        end
        return
    end
    
    -- Normal waypoint: split if cross-zone and not flying capable
    SetMapToCurrentZone()
    local c = GetCurrentMapContinent()
    local z = GetCurrentMapZone()
    local playerZoneName = nil
    if c > 0 and z > 0 then
        local zones = { GetMapZones(c) }
        playerZoneName = zones[z]
    end
    
    local startZone = nil
    if #activeWaypoints > 0 then
        startZone = activeWaypoints[#activeWaypoints].zone
    else
        startZone = playerZoneName
    end
    
    local splitList = {}
    local path = nil
    if startZone and wp.zone and startZone ~= wp.zone and not Waypoints.CheckFlyingCapability() then
        path = FindZonePath(startZone, wp.zone)
    end
    
    if path and #path > 1 then
        -- Generate transition gate waypoints
        for i = 1, #path - 1 do
            local zoneA = path[i]
            local zoneB = path[i+1]
            
            -- Find transition gate coordinates
            local gate = nil
            for k, v in pairs(zoneTransitions) do
                if string.lower(k) == string.lower(zoneA) then
                    for destZone, coords in pairs(v) do
                        if string.lower(destZone) == string.lower(zoneB) then
                            gate = coords
                            break
                        end
                    end
                end
            end
            
            if gate then
                local gateWp = {
                    zone = zoneA,
                    x = gate.x,
                    y = gate.y,
                    desc = "Gate to " .. zoneB,
                    id = GetTime() .. "_gate_" .. i .. "_" .. math.random(1000),
                    isGate = true,
                    parentWpId = wp.id
                }
                table.insert(splitList, gateWp)
            end
        end
        
        -- Append the final target
        table.insert(splitList, wp)
        
        -- Path Pruning Sweep 1: Proximity Prune (remove first gate if already standing next to it)
        local px, py = GetPlayerMapPosition("player")
        if px and px > 0 and py > 0 and #splitList > 1 and playerZoneName == splitList[1].zone then
            local firstGate = splitList[1]
            local distToGate = GetDistanceInYards(px, py, firstGate.x / 100, firstGate.y / 100)
            local arrivalDist = CartoMapper.DB.GetOpt("waypointsArrivalDist") or 15
            if distToGate < (arrivalDist + 20) then
                table.remove(splitList, 1)
            end
        end
        
        -- Path Pruning Sweep 2: Direction-change prune (straighten path if any 3 consecutive nodes are linear)
        local idx = 2
        while idx < #splitList do
            local p1 = splitList[idx-1]
            local p2 = splitList[idx]
            local p3 = splitList[idx+1]
            
            if p1.zone == p2.zone and p2.zone == p3.zone then
                local dx1 = p2.x - p1.x
                local dy1 = (p1.y - p2.y) * 1.5
                local dx2 = p3.x - p2.x
                local dy2 = (p2.y - p3.y) * 1.5
                
                local angle1 = math.atan2(dx1, dy1)
                local angle2 = math.atan2(dx2, dy2)
                local diff = math.abs(angle1 - angle2)
                if diff > math.pi then
                    diff = math.pi * 2 - diff
                end
                
                -- Prune midpoint if direction change is less than 15 degrees (0.262 radians)
                if diff < 0.262 then
                    table.remove(splitList, idx)
                else
                    idx = idx + 1
                end
            else
                idx = idx + 1
            end
        end
        
        -- Add remaining split waypoints to active list
        local routeStr = ""
        for _, item in ipairs(splitList) do
            table.insert(activeWaypoints, item)
            if item.isGate then
                if routeStr == "" then
                    routeStr = item.zone
                end
                routeStr = routeStr .. " -> " .. item.desc:sub(9)
            end
        end
        
        if routeStr ~= "" then
            print(string.format("|cff00ff00[CartoMapper] Route generated: %s|r", routeStr))
        end
        
        CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
        
        if not skipActivate and #splitList > 0 then
            Waypoints.SetActive(splitList[1])
        end
    else
        -- Same zone, flying capable, or no transition path found: add directly
        table.insert(activeWaypoints, wp)
        CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
        if not skipActivate then
            Waypoints.SetActive(wp)
        end
    end
    
    if WorldMapFrame and WorldMapFrame:IsShown() then
        Waypoints.UpdateMapPins()
    end
end

function Waypoints.Remove(wp)
    local wasActive = wp.active
    
    -- Unconditionally remove associated gates if removing a parent waypoint
    if not wp.isGate then
        for i = #activeWaypoints, 1, -1 do
            local w = activeWaypoints[i]
            if w.isGate and w.parentWpId == wp.id then
                table.remove(activeWaypoints, i)
            end
        end
    end
    
    local index = nil
    for i, w in ipairs(activeWaypoints) do
        if w.id == wp.id then
            index = i
            break
        end
    end
    
    if index then
        table.remove(activeWaypoints, index)
    end
    
    CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
    
    -- If active waypoint was removed, switch arrow target
    if wasActive then
        if #activeWaypoints > 0 then
            local closest = SetClosestWaypoint()
            if closest then
                Waypoints.SetActive(closest)
            else
                Waypoints.SetActive(activeWaypoints[1])
            end
        else
            if arrowFrame then arrowFrame:Hide() end
        end
    elseif #activeWaypoints == 0 then
        if arrowFrame then arrowFrame:Hide() end
    end
    
    if WorldMapFrame and WorldMapFrame:IsShown() then
        Waypoints.UpdateMapPins()
    end
end

function Waypoints.ClearAll()
    activeWaypoints = {}
    CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
    
    if arrowFrame then
        arrowFrame:Hide()
    end
    
    if WorldMapFrame and WorldMapFrame:IsShown() then
        Waypoints.UpdateMapPins()
    end
    
    print("|cff00ff00[CartoMapper] Cleared all active waypoints.|r")
end

function Waypoints.GetActive()
    for _, wp in ipairs(activeWaypoints) do
        if wp.active then return wp end
    end
    
    if #activeWaypoints > 0 then
        activeWaypoints[1].active = true
        return activeWaypoints[1]
    end
    return nil
end

function Waypoints.SetActive(wp)
    for _, w in ipairs(activeWaypoints) do
        w.active = (w.id == wp.id)
    end
    CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
    
    if not arrowFrame then
        CreateArrowFrame()
    end
    
    if arrowFrame then
        arrowFrame:Show()
    end
end

-- Bridge API for mouse clicks on the map
function CartoMapper.AddWaypointAt(x, y)
    if not CartoMapper.DB.GetOpt("waypoints") then return end
    
    local c = GetCurrentMapContinent()
    local z = GetCurrentMapZone()
    local zones = { GetMapZones(c) }
    local targetZone = zones[z]
    
    if not targetZone then
        print("|cffff0000[CartoMapper] Current zone could not be determined.|r")
        return
    end
    
    local wp = {
        zone = targetZone,
        x = x,
        y = y,
        desc = string.format("Custom Pin (%.1f, %.1f)", x, y),
        id = GetTime() .. "_" .. math.random(1000)
    }
    
    Waypoints.Add(wp)
end

-- /wayback: Bookmark current player position as a waypoint
function Waypoints.WayBack()
    SetMapToCurrentZone()
    local px, py = GetPlayerMapPosition("player")
    if not px or px == 0 or py == 0 then
        print("|cffff0000[CartoMapper] Cannot determine your current position.|r")
        return
    end
    
    local c = GetCurrentMapContinent()
    local z = GetCurrentMapZone()
    local zones = { GetMapZones(c) }
    local targetZone = zones[z]
    
    if not targetZone then
        print("|cffff0000[CartoMapper] Current zone could not be determined.|r")
        return
    end
    
    local wp = {
        zone = targetZone,
        x = px * 100,
        y = py * 100,
        desc = "Wayback: " .. targetZone,
        id = GetTime() .. "_" .. math.random(1000)
    }
    
    Waypoints.Add(wp, true) -- skipActivate: don't point arrow at the spot we're standing on
    print("|cff00ff00[CartoMapper] Position bookmarked. Use /way to navigate back later.|r")
end

-- Direct Chat Coordinate Detection (Social Integration)
local function ParseAndHyperlinkCoords(msg)
    if not msg then return nil end
    if not CartoMapper.DB.GetOpt("waypoints") then return msg end
    
    local result = msg
    local startPos = 1
    
    while true do
        local startIdx, endIdx, xStr, yStr = string.find(result, "(%d+%.?%d*)%s*[,%s]%s*(%d+%.?%d*)", startPos)
        if not startIdx then break end
        
        local x = tonumber(xStr)
        local y = tonumber(yStr)
        
        -- Validate coordinates range (0 to 100)
        if x and y and x >= 0 and x <= 100 and y >= 0 and y <= 100 then
            local coordsText = string.sub(result, startIdx, endIdx)
            local link = string.format("|Hcmway:%s:%s|h|cff00ff00[%s]|h|r", xStr, yStr, coordsText)
            result = string.sub(result, 1, startIdx - 1) .. link .. string.sub(result, endIdx + 1)
            startPos = startIdx + string.len(link)
        else
            startPos = endIdx + 1
        end
    end
    return result
end

local channels = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_BATTLEGROUND",
    "CHAT_MSG_BATTLEGROUND_LEADER",
    "CHAT_MSG_CHANNEL"
}

local function ChatFilter(self, event, msg, ...)
    local newMsg = ParseAndHyperlinkCoords(msg)
    return false, newMsg, ...
end

for _, chan in ipairs(channels) do
    ChatFrame_AddMessageEventFilter(chan, ChatFilter)
end

-- Hyperlink Click Interceptor
local origSetItemRef = SetItemRef
function SetItemRef(link, text, button, chatFrame)
    if link:sub(1, 5) == "cmway" then
        local _, xStr, yStr = string.split(":", link)
        local x = tonumber(xStr)
        local y = tonumber(yStr)
        if x and y then
            SetMapToCurrentZone()
            local c = GetCurrentMapContinent()
            local z = GetCurrentMapZone()
            local zoneName = nil
            if c > 0 and z > 0 then
                local zones = { GetMapZones(c) }
                zoneName = zones[z]
            end
            
            if zoneName then
                local wp = {
                    zone = zoneName,
                    x = x,
                    y = y,
                    desc = "Chat Link Waypoint",
                    id = GetTime() .. "_" .. math.random(1000)
                }
                Waypoints.Add(wp)
            else
                print("|cffff0000[CartoMapper] Could not determine current zone to add chat waypoint.|r")
            end
        end
        return
    end
    return origSetItemRef(link, text, button, chatFrame)
end

-- Offline Dungeon Floor Quick-Cycling
if WorldMapFrame then
    WorldMapFrame:HookScript("OnKeyDown", function(self, key)
        if not WorldMapFrame:IsShown() then return end
        if key == "PAGEUP" or key == "PAGEDOWN" then
            local numFloors = GetNumDungeonMapLevels()
            if numFloors and numFloors > 1 then
                local currentFloor = GetCurrentMapDungeonLevel()
                local newFloor = currentFloor
                if key == "PAGEUP" then
                    newFloor = currentFloor + 1
                    if newFloor > numFloors then newFloor = 1 end
                else
                    newFloor = currentFloor - 1
                    if newFloor < 1 then newFloor = numFloors end
                end
                SetDungeonMapLevel(newFloor)
            end
        end
    end)
end
