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
}

-- Internal state
local activeWaypoints = {}
local pinPool = {}
local arrowFrame = nil
local zoneMapList = {}

-- Approximate zone sizes in yards (fallback defaults)
local zoneWidth = 2000
local zoneHeight = 1333

local function GetDistanceInYards(x1, y1, x2, y2)
    local dx = (x2 - x1) * zoneWidth
    local dy = (y2 - y1) * zoneHeight
    return math.sqrt(dx*dx + dy*dy)
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
        if pin:IsShown() then
            pin:SetScale(pinScale)
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
    
    for _, wp in ipairs(activeWaypoints) do
        if wp.zone == zName then
            local pin = Waypoints.GetPinFrame(pinIndex)
            pin.wp = wp
            
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", (wp.x / 100) * w, -(wp.y / 100) * h)
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
        pin:SetSize(18, 18)
        pin:SetFrameLevel(WorldMapDetailFrame:GetFrameLevel() + 20)
        
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
        
        pin:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                WorldMapTooltip:Hide()
                Waypoints.Remove(self.wp)
            elseif button == "LeftButton" then
                WorldMapTooltip:Hide()
                Waypoints.SetActive(self.wp)
            end
        end)
        
        pinPool[index] = pin
    end
    return pinPool[index]
end

-- Navigation HUD Arrow Update loop
local lastUpdate = 0
local function Arrow_OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < 0.05 then return end
    lastUpdate = 0
    
    local wp = Waypoints.GetActive()
    if not wp then
        self:Hide()
        return
    end
    
    local px, py = GetPlayerMapPosition("player")
    if not px or px == 0 or py == 0 then
        self.text:SetText("No Position Signal")
        self.arrowTex:SetRotation(0)
        self.arrowTex:SetVertexColor(0.6, 0.6, 0.6, 0.6)
        return
    end
    
    -- Check if player is in the same zone as target waypoint
    local continents = { GetMapContinents() }
    local currentContinent = GetCurrentMapContinent()
    local currentZone = GetCurrentMapZone()
    if currentContinent <= 0 or currentZone <= 0 then
        self.text:SetText(string.format("Go to:\n%s", wp.zone))
        self.arrowTex:SetRotation(0)
        self.arrowTex:SetVertexColor(0.6, 0.6, 0.6, 0.6)
        return
    end
    
    local zones = { GetMapZones(currentContinent) }
    local playerZoneName = zones[currentZone]
    
    if playerZoneName ~= wp.zone then
        self.text:SetText(string.format("Go to:\n%s", wp.zone))
        self.arrowTex:SetRotation(0)
        self.arrowTex:SetVertexColor(0.6, 0.6, 0.6, 0.6)
        return
    end
    
    -- Waypoint is in the same zone
    self.arrowTex:SetVertexColor(0.1, 1.0, 0.1, 1.0) -- Active green arrow
    
    local dist = GetDistanceInYards(px, py, wp.x / 100, wp.y / 100)
    
    -- Check if reached (within 8 yards)
    if dist < 8 then
        PlaySoundFile("Sound\\Interface\\LevelUp.wav")
        UIErrorsFrame:AddMessage("Waypoint Reached!", 0.1, 1.0, 0.1, 1.0, 5)
        print("|cff00ff00[CartoMapper] Reached Waypoint: " .. (wp.desc or string.format("%.1f, %.1f", wp.x, wp.y)) .. "|r")
        Waypoints.Remove(wp)
        return
    end
    
    -- Calculate yaw rotation
    local dx = (wp.x / 100) - px
    local dy = py - (wp.y / 100)
    
    local targetAngle = math.atan2(dx * 1.5, dy)
    local facing = GetPlayerFacing() or 0
    local rotation = -(targetAngle + facing)
    
    self.arrowTex:SetRotation(rotation)
    
    local distText = string.format("%d yards", math.floor(dist))
    if wp.desc then
        self.text:SetText(string.format("%s\n%s", wp.desc, distText))
    else
        self.text:SetText(string.format("Waypoint (%.1f, %.1f)\n%s", wp.x, wp.y, distText))
    end
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
    
    -- Register slash command
    SLASH_CARTOMAPPER_WAY1 = "/way"
    SlashCmdList["CARTOMAPPER_WAY"] = function(msg)
        if not CartoMapper.DB.GetOpt("waypoints") then return end
        Waypoints.HandleSlashCommand(msg)
    end
    
    -- Setup secure hooks for mapping
    if not Waypoints.hookedPOI then
        hooksecurefunc("WorldMapFrame_Update", Waypoints.UpdateMapPins)
        hooksecurefunc("WorldMapFrame_SetPOIMaxBounds", UpdatePinScales)
        Waypoints.hookedPOI = true
    end
    
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
end

-- Slash command parser and processor
function Waypoints.HandleSlashCommand(msg)
    if not msg or msg == "" then
        print("|cffffd700[CartoMapper] Waypoints Usage:|r")
        print("  |cff00ff00/way [x] [y] [desc]|r - Add waypoint in current zone")
        print("  |cff00ff00/way [zone] [x] [y] [desc]|r - Add waypoint in target zone")
        print("  |cff00ff00/way clear|r - Clear all active waypoints")
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
function Waypoints.Add(wp)
    table.insert(activeWaypoints, wp)
    CartoMapper.DB.SetOpt("waypointsList", activeWaypoints)
    
    print(string.format("|cff00ff00[CartoMapper] Added waypoint: %s (%.1f, %.1f)%s|r", 
        wp.zone, wp.x, wp.y, wp.desc and (" - " .. wp.desc) or ""))
        
    Waypoints.SetActive(wp)
    
    if WorldMapFrame and WorldMapFrame:IsShown() then
        Waypoints.UpdateMapPins()
    end
end

function Waypoints.Remove(wp)
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
    local activeWp = Waypoints.GetActive()
    if activeWp and activeWp.id == wp.id then
        if #activeWaypoints > 0 then
            Waypoints.SetActive(activeWaypoints[#activeWaypoints])
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
        activeWaypoints[#activeWaypoints].active = true
        return activeWaypoints[#activeWaypoints]
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
