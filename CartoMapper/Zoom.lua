--[[--------------------------------------------------------------------------------------------
Zoom.lua
World Map Scroll-to-Zoom and Drag-to-Pan functionality.
Also handles Ctrl + Scroll windowed map scaling and inverse scale correction for map pins.
--------------------------------------------------------------------------------------------]]--

local Zoom = {}
CartoMapper.modules["zoom"] = Zoom

local MAX_ZOOM = 4.0
local ZOOM_STEP = 0.1
local MIN_ZOOM = 1.0

local MINIMODE_MIN_ZOOM = 0.5
local MINIMODE_MAX_ZOOM = 3.0
local MINIMODE_ZOOM_STEP = 0.05

local PreviousState = {
    panX = 0,
    panY = 0,
    scale = 1.0,
    zone = 0
}

local function SetPOIMaxBounds()
    WorldMapScrollFrame.maxY = WorldMapDetailFrame:GetHeight() * -WORLDMAP_SETTINGS.size + 12
    WorldMapScrollFrame.maxX = WorldMapDetailFrame:GetWidth() * WORLDMAP_SETTINGS.size + 12
end

local function SetDetailFrameScale(scale)
    WorldMapDetailFrame:SetScale(scale)
    SetPOIMaxBounds()

    -- Correct scaling on map sub-elements so they do not bloat when zoomed in
    local invScale = 1 / scale
    WorldMapPOIFrame:SetScale(1 / WORLDMAP_SETTINGS.size)
    WorldMapBlobFrame:SetScale(scale)

    WorldMapPlayer:SetScale(invScale)
    WorldMapDeathRelease:SetScale(invScale)
    WorldMapCorpse:SetScale(invScale)

    -- Party Members
    for i = 1, MAX_PARTY_MEMBERS do
        local f = _G["WorldMapParty" .. i]
        if f then f:SetScale(invScale) end
    end

    -- Raid Members
    for i = 1, MAX_RAID_MEMBERS do
        local f = _G["WorldMapRaid" .. i]
        if f then f:SetScale(invScale) end
    end

    -- Flags
    local numFlags = GetNumBattlefieldFlagPositions()
    for i = 1, numFlags do
        local f = _G["WorldMapFlag" .. i]
        if f then f:SetScale(invScale) end
    end

    -- Vehicles
    if MAP_VEHICLES then
        for i = 1, #MAP_VEHICLES do
            if MAP_VEHICLES[i] then MAP_VEHICLES[i]:SetScale(invScale) end
        end
    end

    WorldMapFrame_OnEvent(WorldMapFrame, "DISPLAY_SIZE_CHANGED")
end

local function PersistMapScrollAndPan()
    PreviousState.panX = WorldMapScrollFrame:GetHorizontalScroll()
    PreviousState.panY = WorldMapScrollFrame:GetVerticalScroll()
    PreviousState.scale = WorldMapDetailFrame:GetScale()
    PreviousState.zone = GetCurrentMapZone()
end

local function AfterScrollOrPan()
    PersistMapScrollAndPan()
    if WORLDMAP_SETTINGS.selectedQuest and WorldMapBlobFrame.DrawQuestBlob then
        WorldMapBlobFrame:DrawQuestBlob(WORLDMAP_SETTINGS.selectedQuestId, false)
        WorldMapBlobFrame:DrawQuestBlob(WORLDMAP_SETTINGS.selectedQuestId, true)
    end
end

-- Resize quest POI buttons so they do not drift or scale awkwardly
local function ResizeQuestPOIs()
    local QUEST_POI_MAX_TYPES = 4
    local POI_TYPE_MAX_BUTTONS = 25
    local scale = WorldMapDetailFrame:GetScale()

    local function resizePOI(poiButton)
        if not poiButton then return end
        local _, _, _, x, y = poiButton:GetPoint()
        if x and y then
            local s = WORLDMAP_SETTINGS.size / WorldMapDetailFrame:GetEffectiveScale()
            local posX = x * 1 / s
            local posY = y * 1 / s
            poiButton:SetScale(s)
            poiButton:SetPoint("CENTER", poiButton:GetParent(), "TOPLEFT", posX, posY)
        end
    end

    for i = 1, QUEST_POI_MAX_TYPES do
        for j = 1, POI_TYPE_MAX_BUTTONS do
            resizePOI(_G["poiWorldMapPOIFrame" .. i .. "_" .. j])
        end
    end
    if QUEST_POI_SWAP_BUTTONS then
        resizePOI(QUEST_POI_SWAP_BUTTONS["WorldMapPOIFrame"])
    end
end

local function updatePointRelativeTo(frame, newRelativeFrame)
    if not frame then return end
    local currentPoint, _currentRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY = frame:GetPoint()
    if currentPoint and currentRelativePoint then
        frame:ClearAllPoints()
        frame:SetPoint(currentPoint, newRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY)
    end
end

local function SetupWorldMapFrame()
    WorldMapScrollFrameScrollBar:Hide()
    WorldMapFrame:EnableMouse(true)
    WorldMapScrollFrame:EnableMouse(true)
    WorldMapScrollFrame.panning = false
    WorldMapScrollFrame.moved = false

    -- Adapt coordinates of quest tracker and frame positions based on WotLK sizes
    WorldMapScrollFrame:ClearAllPoints()
    if WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE then
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -726, -99)
        if WorldMapTrackQuest then
            WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 8, 4)
        end
    elseif WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        if WorldMapTrackQuest then
            WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9)
        end

        WorldMapFrame:SetPoint("TOPLEFT", WorldMapScreenAnchor or UIParent, 0, 0)
        WorldMapFrame:SetScale(CartoMapperDB.mapScale or 1.0)
        WorldMapFrame:SetMovable("true")
        WorldMapTitleButton:Show()
        WorldMapTitleButton:ClearAllPoints()
        WorldMapFrameTitle:Show()
        WorldMapFrameTitle:ClearAllPoints()
        WorldMapFrameTitle:SetPoint("CENTER", WorldMapTitleButton, "CENTER", 32, 0)

        if WORLDMAP_SETTINGS.advanced then
            WorldMapScrollFrame:SetPoint("TOPLEFT", 19, -42)
            WorldMapTitleButton:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 13, 0)
        else
            WorldMapScrollFrame:SetPoint("TOPLEFT", 37, -66)
            WorldMapTitleButton:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 13, -14)
        end
    else
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT", 11, -70.5)
        if WorldMapTrackQuest then
            WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9)
        end
    end

    WorldMapScrollFrame:SetScale(WORLDMAP_SETTINGS.size)
    SetDetailFrameScale(1.0)
    WorldMapDetailFrame:SetAllPoints(WorldMapScrollFrame)
    WorldMapScrollFrame:SetHorizontalScroll(0)
    WorldMapScrollFrame:SetVerticalScroll(0)

    -- Persist zoom across reopenings of the same zone
    if GetCurrentMapZone() == PreviousState.zone then
        SetDetailFrameScale(PreviousState.scale)
        WorldMapScrollFrame:SetHorizontalScroll(PreviousState.panX)
        WorldMapScrollFrame:SetVerticalScroll(PreviousState.panY)
    end

    WorldMapButton:SetScale(1.0)
    WorldMapButton:SetAllPoints(WorldMapDetailFrame)
    WorldMapButton:SetParent(WorldMapDetailFrame)
    WorldMapPOIFrame:SetParent(WorldMapDetailFrame)
    WorldMapBlobFrame:SetParent(WorldMapDetailFrame)
    WorldMapBlobFrame:ClearAllPoints()
    WorldMapBlobFrame:SetAllPoints(WorldMapDetailFrame)
    WorldMapPlayer:SetParent(WorldMapDetailFrame)

    -- Anchor Quest Log sub-elements to the scroll frame instead of the scaled detail frame
    updatePointRelativeTo(WorldMapQuestScrollFrame, WorldMapScrollFrame)
    updatePointRelativeTo(WorldMapQuestDetailScrollFrame, WorldMapScrollFrame)
end

-- Mouse Scroll Zoom Handler
local function WorldMapScrollFrame_OnMouseWheel(self, delta)
    -- Ctrl + Scroll scales the windowed world map frame itself
    if IsControlKeyDown() and WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        local oldScale = WorldMapFrame:GetScale()
        local newScale = oldScale + delta * MINIMODE_ZOOM_STEP
        newScale = math.max(MINIMODE_MIN_ZOOM, newScale)
        newScale = math.min(MINIMODE_MAX_ZOOM, newScale)

        WorldMapFrame:SetScale(newScale)
        CartoMapperDB.mapScale = newScale
        return
    end

    -- Scroll-wheel Zoom map detail
    local oldScrollH = WorldMapScrollFrame:GetHorizontalScroll()
    local oldScrollV = WorldMapScrollFrame:GetVerticalScroll()

    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / WorldMapScrollFrame:GetEffectiveScale()
    cursorY = cursorY / WorldMapScrollFrame:GetEffectiveScale()

    local frameX = cursorX - WorldMapScrollFrame:GetLeft()
    local frameY = WorldMapScrollFrame:GetTop() - cursorY

    local oldScale = WorldMapDetailFrame:GetScale()
    local newScale = oldScale * (1.0 + delta * ZOOM_STEP)
    newScale = math.max(MIN_ZOOM, newScale)
    newScale = math.min(MAX_ZOOM, newScale)

    SetDetailFrameScale(newScale)

    WorldMapScrollFrame.maxX = ((WorldMapDetailFrame:GetWidth() * newScale) - WorldMapScrollFrame:GetWidth()) / newScale
    WorldMapScrollFrame.maxY = ((WorldMapDetailFrame:GetHeight() * newScale) - WorldMapScrollFrame:GetHeight()) / newScale
    WorldMapScrollFrame.zoomedIn = WorldMapDetailFrame:GetScale() > MIN_ZOOM

    local centerX = oldScrollH + frameX / oldScale
    local centerY = oldScrollV + frameY / oldScale
    local newScrollH = centerX - frameX / newScale
    local newScrollV = centerY - frameY / newScale

    newScrollH = math.min(newScrollH, WorldMapScrollFrame.maxX)
    newScrollH = math.max(0, newScrollH)
    newScrollV = math.min(newScrollV, WorldMapScrollFrame.maxY)
    newScrollV = math.max(0, newScrollV)

    WorldMapScrollFrame:SetHorizontalScroll(newScrollH)
    WorldMapScrollFrame:SetVerticalScroll(newScrollV)
    AfterScrollOrPan()
end

-- Click and Drag Panning
local function WorldMapButton_OnMouseDown(self, button)
    if button == "LeftButton" and WorldMapScrollFrame.zoomedIn then
        WorldMapScrollFrame.panning = true
        local x, y = GetCursorPosition()
        WorldMapScrollFrame.cursorX = x
        WorldMapScrollFrame.cursorY = y
        WorldMapScrollFrame.x = WorldMapScrollFrame:GetHorizontalScroll()
        WorldMapScrollFrame.y = WorldMapScrollFrame:GetVerticalScroll()
        WorldMapScrollFrame.moved = false
    end
end

local function WorldMapButton_OnMouseUp(self, button)
    WorldMapScrollFrame.panning = false
    if not WorldMapScrollFrame.moved then
        -- Default zoom click (subzone/continent click)
        WorldMapButton_OnClick(WorldMapButton, button)
        -- Reset scale when changing zones
        SetDetailFrameScale(MIN_ZOOM)
        WorldMapScrollFrame:SetHorizontalScroll(0)
        WorldMapScrollFrame:SetVerticalScroll(0)
        AfterScrollOrPan()
        WorldMapScrollFrame.zoomedIn = false
    end
    WorldMapScrollFrame.moved = false
end

local function WorldMapScrollFrame_OnPan(cursorX, cursorY)
    local dX = WorldMapScrollFrame.cursorX - cursorX
    local dY = cursorY - WorldMapScrollFrame.cursorY
    local scale = WorldMapScrollFrame:GetEffectiveScale()
    dX = dX / scale
    dY = dY / scale
    if math.abs(dX) >= 1 or math.abs(dY) >= 1 then
        WorldMapScrollFrame.moved = true
        
        local x = math.max(0, dX + WorldMapScrollFrame.x)
        x = math.min(x, WorldMapScrollFrame.maxX)
        WorldMapScrollFrame:SetHorizontalScroll(x)

        local y = math.max(0, dY + WorldMapScrollFrame.y)
        y = math.min(y, WorldMapScrollFrame.maxY)
        WorldMapScrollFrame:SetVerticalScroll(y)
        AfterScrollOrPan()
    end
end

local function WorldMapButton_OnUpdate(self, elapsed)
    -- Handle map panning
    if WorldMapScrollFrame.panning then
        local x, y = GetCursorPosition()
        WorldMapScrollFrame_OnPan(x, y)
    end

    -- Handle map highlight
    local x, y = GetCursorPosition()
    x = x / self:GetEffectiveScale()
    y = y / self:GetEffectiveScale()

    local centerX, centerY = self:GetCenter()
    local width = self:GetWidth()
    local height = self:GetHeight()
    local adjustedY = (centerY + (height / 2) - y) / height
    local adjustedX = (x - (centerX - (width / 2))) / width

    local name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY
    if self:IsMouseOver() then
        name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = UpdateMapHighlight(adjustedX, adjustedY)
    end

    WorldMapFrame.areaName = name
    if not WorldMapFrame.poiHighlight then
        WorldMapFrameAreaLabel:SetText(name)
    end
    if fileName then
        WorldMapHighlight:SetTexCoord(0, texPercentageX, 0, texPercentageY)
        WorldMapHighlight:SetTexture("Interface\\WorldMap\\" .. fileName .. "\\" .. fileName .. "Highlight")
        textureX = textureX * width
        textureY = textureY * height
        scrollChildX = scrollChildX * width
        scrollChildY = -scrollChildY * height
        if textureX > 0 and textureY > 0 then
            WorldMapHighlight:SetWidth(textureX)
            WorldMapHighlight:SetHeight(textureY)
            WorldMapHighlight:SetPoint("TOPLEFT", "WorldMapDetailFrame", "TOPLEFT", scrollChildX, scrollChildY)
            WorldMapHighlight:Show()
        end
    else
        WorldMapHighlight:Hide()
    end

    -- Position player
    UpdateWorldMapArrowFrames()
    local playerX, playerY = GetPlayerMapPosition("player")
    if playerX == 0 and playerY == 0 then
        ShowWorldMapArrowFrame(nil)
        WorldMapPing:Hide()
        WorldMapPlayer:Hide()
    else
        playerX = playerX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size
        playerY = -playerY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size
        PositionWorldMapArrowFrame("CENTER", "WorldMapDetailFrame", "TOPLEFT", playerX, playerY)
        ShowWorldMapArrowFrame(nil)

        WorldMapPlayer:SetAllPoints(PlayerArrowFrame)
        if WorldMapPlayer.Icon then
            WorldMapPlayer.Icon:SetRotation(PlayerArrowFrame:GetFacing())
            WorldMapPlayer.Icon:SetSize(36, 36)
        end
        WorldMapPlayer:Show()
    end

    -- Position groupmates
    local playerCount = 0
    local numRaidMembers = GetNumRaidMembers()
    if numRaidMembers > 0 then
        for i = 1, MAX_PARTY_MEMBERS do
            local partyMemberFrame = _G["WorldMapParty" .. i]
            if partyMemberFrame then partyMemberFrame:Hide() end
        end
        for i = 1, MAX_RAID_MEMBERS do
            local unit = "raid" .. i
            local partyX, partyY = GetPlayerMapPosition(unit)
            local partyMemberFrame = _G["WorldMapRaid" .. (playerCount + 1)]
            if partyMemberFrame then
                if (partyX == 0 and partyY == 0) or UnitIsUnit(unit, "player") then
                    partyMemberFrame:Hide()
                else
                    partyX = partyX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale()
                    partyY = -partyY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()
                    partyMemberFrame:ClearAllPoints()
                    partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY)
                    partyMemberFrame.name = nil
                    partyMemberFrame.unit = unit
                    partyMemberFrame:Show()
                    playerCount = playerCount + 1
                end
            end
        end
    else
        for i = 1, MAX_PARTY_MEMBERS do
            local partyX, partyY = GetPlayerMapPosition("party" .. i)
            local partyMemberFrame = _G["WorldMapParty" .. i]
            if partyMemberFrame then
                if partyX == 0 and partyY == 0 then
                    partyMemberFrame:Hide()
                else
                    partyX = partyX * WorldMapButton:GetWidth() * WorldMapDetailFrame:GetScale()
                    partyY = -partyY * WorldMapButton:GetHeight() * WorldMapDetailFrame:GetScale()
                    partyMemberFrame:ClearAllPoints()
                    partyMemberFrame:SetPoint("CENTER", "WorldMapButton", "TOPLEFT", partyX, partyY)
                    partyMemberFrame.unit = "party" .. i
                    partyMemberFrame:Show()
                end
            end
        end
    end

    -- Position Team Members
    local numTeamMembers = GetNumBattlefieldPositions()
    for i = playerCount + 1, MAX_RAID_MEMBERS do
        local partyX, partyY, name = GetBattlefieldPosition(i - playerCount)
        local partyMemberFrame = _G["WorldMapRaid" .. i]
        if partyMemberFrame then
            if partyX == 0 and partyY == 0 then
                partyMemberFrame:Hide()
            else
                partyX = partyX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale()
                partyY = -partyY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()
                partyMemberFrame:ClearAllPoints()
                partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY)
                partyMemberFrame.name = name
                partyMemberFrame.unit = nil
                partyMemberFrame:Show()
            end
        end
    end
    -- Hide extra raid frames
    for i = playerCount + numTeamMembers + 1, MAX_RAID_MEMBERS do
        local partyMemberFrame = _G["WorldMapRaid" .. i]
        if partyMemberFrame then partyMemberFrame:Hide() end
    end

    -- Position flags
    local numFlags = GetNumBattlefieldFlagPositions()
    for i = 1, numFlags do
        local flagX, flagY, flagToken = GetBattlefieldFlagPosition(i)
        local flagFrameName = "WorldMapFlag" .. i
        local flagFrame = _G[flagFrameName]
        if flagFrame then
            if flagX == 0 and flagY == 0 then
                flagFrame:Hide()
            else
                flagX = flagX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale()
                flagY = -flagY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()
                flagFrame:ClearAllPoints()
                flagFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", flagX, flagY)
                local flagTexture = _G[flagFrameName .. "Texture"]
                if flagTexture then
                    flagTexture:SetTexture("Interface\\WorldStateFrame\\" .. flagToken)
                end
                flagFrame:Show()
            end
        end
    end
    for i = numFlags + 1, NUM_WORLDMAP_FLAGS or 3 do
        local flagFrame = _G["WorldMapFlag" .. i]
        if flagFrame then flagFrame:Hide() end
    end

    -- Position corpse
    local corpseX, corpseY = GetCorpseMapPosition()
    if corpseX == 0 and corpseY == 0 then
        WorldMapCorpse:Hide()
    else
        corpseX = corpseX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale()
        corpseY = -corpseY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()
        WorldMapCorpse:ClearAllPoints()
        WorldMapCorpse:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", corpseX, corpseY)
        WorldMapCorpse:Show()
    end

    -- Position Death Release marker
    local deathReleaseX, deathReleaseY = GetDeathReleasePosition()
    if (deathReleaseX == 0 and deathReleaseY == 0) or UnitIsGhost("player") then
        WorldMapDeathRelease:Hide()
    else
        deathReleaseX = deathReleaseX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale()
        deathReleaseY = -deathReleaseY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()
        WorldMapDeathRelease:ClearAllPoints()
        WorldMapDeathRelease:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", deathReleaseX, deathReleaseY)
        WorldMapDeathRelease:Show()
    end

    -- Position vehicles
    local numVehicles
    if GetCurrentMapContinent() == WORLDMAP_WORLD_ID or (GetCurrentMapContinent() ~= -1 and GetCurrentMapZone() == 0) then
        numVehicles = 0
    else
        numVehicles = GetNumBattlefieldVehicles()
    end
    local totalVehicles = MAP_VEHICLES and #MAP_VEHICLES or 0
    for i = 1, numVehicles do
        if MAP_VEHICLES then
            if i > totalVehicles then
                local vehicleName = "WorldMapVehicles" .. i
                MAP_VEHICLES[i] = CreateFrame("FRAME", vehicleName, WorldMapButton, "WorldMapVehicleTemplate")
                MAP_VEHICLES[i].texture = _G[vehicleName .. "Texture"]
            end
            local vehicleX, vehicleY, unitName, isPossessed, vehicleType, orientation, isPlayer, isAlive = GetBattlefieldVehicleInfo(i)
            if vehicleX and isAlive and not isPlayer and VEHICLE_TEXTURES and VEHICLE_TEXTURES[vehicleType] then
                local mapVehicleFrame = MAP_VEHICLES[i]
                vehicleX = vehicleX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale()
                vehicleY = -vehicleY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()
                if mapVehicleFrame.texture then
                    mapVehicleFrame.texture:SetRotation(orientation)
                    mapVehicleFrame.texture:SetTexture(WorldMap_GetVehicleTexture(vehicleType, isPossessed))
                end
                mapVehicleFrame:ClearAllPoints()
                mapVehicleFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", vehicleX, vehicleY)
                mapVehicleFrame:SetWidth(VEHICLE_TEXTURES[vehicleType].width)
                mapVehicleFrame:SetHeight(VEHICLE_TEXTURES[vehicleType].height)
                mapVehicleFrame.name = unitName
                mapVehicleFrame:Show()
            else
                if MAP_VEHICLES[i] then MAP_VEHICLES[i]:Hide() end
            end
        end
    end
    if MAP_VEHICLES then
        for i = numVehicles + 1, #MAP_VEHICLES do
            if MAP_VEHICLES[i] then MAP_VEHICLES[i]:Hide() end
        end
    end
end

function Zoom.Enable()
    -- Create the scroll frame dynamically if it doesn't exist yet
    if not WorldMapScrollFrame then
        WorldMapScrollFrame = CreateFrame("ScrollFrame", "WorldMapScrollFrame", WorldMapFrame, "FauxScrollFrameTemplate")
        WorldMapScrollFrame:SetSize(1002, 668)
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT")
    end

    -- Set nesting structures
    WorldMapScrollFrame:SetScrollChild(WorldMapDetailFrame)
    WorldMapScrollFrame:SetScript("OnMouseWheel", WorldMapScrollFrame_OnMouseWheel)
    WorldMapButton:SetScript("OnMouseDown", WorldMapButton_OnMouseDown)
    WorldMapButton:SetScript("OnMouseUp", WorldMapButton_OnMouseUp)
    WorldMapDetailFrame:SetParent(WorldMapScrollFrame)

    -- Reparent the area label so it doesn't move or scale with the detail frame zoom
    if WorldMapFrameAreaFrame then
        WorldMapFrameAreaFrame:SetParent(WorldMapFrame)
        WorldMapFrameAreaFrame:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL or 3)
        WorldMapFrameAreaFrame:ClearAllPoints()
        WorldMapFrameAreaFrame:SetPoint("TOP", WorldMapScrollFrame, "TOP", 0, -10)
    end

    -- Disable built-in map ping model scale issues
    if WorldMapPing then
        WorldMapPing.Show = function() return end
        WorldMapPing:SetModelScale(0)
    end

    -- Add 2D player arrow that will get masked/clipped correctly on pan
    if not WorldMapPlayer.Icon then
        WorldMapPlayer.Icon = WorldMapPlayer:CreateTexture(nil, "ARTWORK")
        WorldMapPlayer.Icon:SetSize(36, 36)
        WorldMapPlayer.Icon:SetPoint("CENTER", 0, 0)
        WorldMapPlayer.Icon:SetTexture("Interface\\AddOns\\CartoMapper\\assets\\WorldMapArrow")
    end

    -- Hook layout update routines
    hooksecurefunc("WorldMapFrame_SetFullMapView", SetupWorldMapFrame)
    hooksecurefunc("WorldMapFrame_SetQuestMapView", SetupWorldMapFrame)
    hooksecurefunc("WorldMap_ToggleSizeDown", SetupWorldMapFrame)
    hooksecurefunc("WorldMap_ToggleSizeUp", SetupWorldMapFrame)
    hooksecurefunc("WorldMapFrame_UpdateQuests", ResizeQuestPOIs)
    hooksecurefunc("WorldMapFrame_SetPOIMaxBounds", SetPOIMaxBounds)

    -- Correct positioning of the quest objectives checkbox in minimized view
    hooksecurefunc("WorldMapQuestShowObjectives_AdjustPosition", function()
        if not WorldMapQuestShowObjectives then return end
        if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
            WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOMRIGHT",
                -30 - (WorldMapQuestShowObjectivesText and WorldMapQuestShowObjectivesText:GetWidth() or 0), -9)
        else
            WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOMRIGHT",
                -15 - (WorldMapQuestShowObjectivesText and WorldMapQuestShowObjectivesText:GetWidth() or 0), 4)
        end
    end)

    -- Windowed map drag-to-move bindings
    WorldMapTitleButton:SetScript("OnDragStart", function()
        if WorldMapScreenAnchor then
            WorldMapScreenAnchor:ClearAllPoints()
        end
        WorldMapFrame:ClearAllPoints()
        WorldMapFrame:StartMoving()
    end)
    WorldMapTitleButton:SetScript("OnDragStop", function()
        WorldMapFrame:StopMovingOrSizing()
        if WorldMapScreenAnchor then
            WorldMapScreenAnchor:StartMoving()
            WorldMapScreenAnchor:SetPoint("TOPLEFT", WorldMapFrame)
            WorldMapScreenAnchor:StopMovingOrSizing()
        end
    end)

    -- Setup custom OnUpdate for map mouse positioning and pin scaling
    WorldMapButton:SetScript("OnUpdate", WorldMapButton_OnUpdate)

    -- Setup on show
    local original_WorldMapFrame_OnShow = WorldMapFrame:GetScript("OnShow")
    WorldMapFrame:SetScript("OnShow", function(self)
        if original_WorldMapFrame_OnShow then
            original_WorldMapFrame_OnShow(self)
        end
        SetupWorldMapFrame()
    end)
end
