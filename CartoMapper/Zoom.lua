--[[--------------------------------------------------------------------------------------------
Zoom.lua
World Map Scroll-to-Zoom and Drag-to-Pan functionality.
Also handles Ctrl + Scroll windowed map scaling and inverse scale correction for map pins.
--------------------------------------------------------------------------------------------]]--

local Zoom = {}
CartoMapper.modules["zoom"] = Zoom
-- The scroll/zoom scaffolding (scroll frame, OnUpdate override, hooks) has to be
-- installed once at startup regardless of the "zoom" DB option, because the option
-- itself is checked live at each point of use (wheel, drag, remembered-zoom restore).
Zoom.alwaysEnable = true
-- liveToggle = true lets profile switches / Reset Defaults call Zoom.Enable()/Disable()
-- immediately instead of just flagging "reload needed". Enable() is idempotent (guarded
-- by Zoom.enabled) and Disable() resets any active zoom/pan state - see below.
Zoom.liveToggle = true

function CartoMapper.UpdateClickThrough()
    local clickThrough = CartoMapper.DB.GetOpt("clickThrough")
    local state = true
    if clickThrough then
        if IsAltKeyDown() then
            state = true
        else
            state = false
        end
    end
    WorldMapFrame:EnableMouse(state)
    WorldMapScrollFrame:EnableMouse(state)
    WorldMapButton:EnableMouse(state)
end

local currentAlpha = 1.0
function CartoMapper.UpdateMapOpacity()
    if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        local speed = GetUnitSpeed("player")
        local moving = (speed > 0)
        if moving and CartoMapper.DB.GetOpt("NoFadeCursor") and WorldMapFrame:IsMouseOver() then
            moving = false
        end
        local targetAlpha = moving and (CartoMapper.DB.GetOpt("movingOpacity") or 0.5) or (CartoMapper.DB.GetOpt("stationaryOpacity") or 1.0)
        WorldMapFrame:SetAlpha(targetAlpha)
        currentAlpha = targetAlpha
    else
        WorldMapFrame:SetAlpha(1.0)
    end
end

local faderFrame = CreateFrame("Frame")
faderFrame:SetScript("OnUpdate", function(self, elapsed)
    if WORLDMAP_SETTINGS.size ~= WORLDMAP_WINDOWED_SIZE then
        WorldMapFrame:SetAlpha(1.0)
        return
    end
    
    local speed = GetUnitSpeed("player")
    local moving = (speed > 0)
    if moving and CartoMapper.DB.GetOpt("NoFadeCursor") and WorldMapFrame:IsMouseOver() then
        moving = false
    end
    local targetAlpha = moving and (CartoMapper.DB.GetOpt("movingOpacity") or 0.5) or (CartoMapper.DB.GetOpt("stationaryOpacity") or 1.0)
    
    if currentAlpha ~= targetAlpha then
        local step = elapsed * 3
        if currentAlpha < targetAlpha then
            currentAlpha = math.min(targetAlpha, currentAlpha + step)
        else
            currentAlpha = math.max(targetAlpha, currentAlpha - step)
        end
        WorldMapFrame:SetAlpha(currentAlpha)
    end
end)

local MAX_ZOOM = 10.0
local MIN_ZOOM = 1.0

local MINIMODE_MIN_ZOOM = 0.5
local MINIMODE_MAX_ZOOM = 4.0
local MINIMODE_ZOOM_STEP = 0.05

local PreviousState = {
    panX = 0,
    panY = 0,
    scale = 1.0,
    zone = 0
}

local deferFrame = CreateFrame("Frame")

local function SetPOIMaxBounds()
    WorldMapScrollFrame.maxY = WorldMapDetailFrame:GetHeight() * -WORLDMAP_SETTINGS.size + 12
    WorldMapScrollFrame.maxX = WorldMapDetailFrame:GetWidth() * WORLDMAP_SETTINGS.size + 12
end

local function UpdateDetailTilesVisibility()
    local numTiles = NUM_WORLDMAP_DETAIL_TILES or 12
    local hasOverlays = false
    if CartoMapper.modules["fogClear"] and CartoMapper.modules["fogClear"].enabled and CartoMapper.modules["fogClear"].HasOverlays then
        hasOverlays = CartoMapper.modules["fogClear"].HasOverlays()
    else
        hasOverlays = GetNumMapOverlays() > 0
    end

    if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE and CartoMapper.DB.GetOpt("borderless") and GetCurrentMapZone() > 0 and hasOverlays then
        for i = 1, numTiles do
            local tile = _G["WorldMapDetailTile" .. i]
            if tile then tile:Hide() end
        end
    else
        for i = 1, numTiles do
            local tile = _G["WorldMapDetailTile" .. i]
            if tile then tile:Show() end
        end
    end
end

-- Resize quest POI buttons so they do not drift or scale awkwardly.
-- Defined BEFORE SetDetailFrameScale (which references it) because Lua captures
-- upvalues at function-definition time. A `local function name()` declared later
-- would shadow any earlier `local name` and would NOT rebind the forward-declared
-- local; the call site would resolve to nil. Keeping the def above the caller
-- guarantees the upvalue binds to the real function.
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

local function SetDetailFrameScale(scale)
    WorldMapDetailFrame:SetScale(scale)
    if WorldMapScrollFrame then
        WorldMapScrollFrame:UpdateScrollChildRect()
    end
    if WorldMapFrame_SetPOIMaxBounds then
        WorldMapFrame_SetPOIMaxBounds()
    else
        SetPOIMaxBounds()
    end

    -- Correct scaling on map sub-elements so they do not bloat when zoomed in
    local invScale = 1 / scale
    WorldMapPOIFrame:SetScale(1 / WORLDMAP_SETTINGS.size)
    WorldMapBlobFrame:SetScale(scale)

    local pSize = CartoMapper.DB.GetOpt("playerArrowSize") or 16
    local arrowScale = pSize / 16
    local elementScale = (invScale / WORLDMAP_SETTINGS.size) * arrowScale
    WorldMapPlayer:SetScale(elementScale)
    WorldMapDeathRelease:SetScale(elementScale)
    WorldMapCorpse:SetScale(elementScale)

    -- Party Members
    local gSize = CartoMapper.DB.GetOpt("groupIconSize") or 16
    local groupScale = gSize / 16
    for i = 1, MAX_PARTY_MEMBERS do
        local f = _G["WorldMapParty" .. i]
        if f then f:SetScale(invScale * groupScale) end
    end

    -- Raid Members
    for i = 1, MAX_RAID_MEMBERS do
        local f = _G["WorldMapRaid" .. i]
        if f then f:SetScale(invScale * groupScale) end
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

    -- Refresh Blizzard quest POIs so the buttons are recreated with canonical
    -- offsets, then our hooksecurefunc on WorldMapFrame_UpdateQuests re-applies
    -- the scale-aware POI resize. We call Blizzard's WorldMapFrame_UpdateQuests
    -- directly -- but wrapped in pcall, since WotLK QuestPOI_HideButtons has no
    -- nil-guard and crashes when a quest POI of a given buttonType hasn't been
    -- created for the current zone. Previously this fired "DISPLAY_SIZE_CHANGED"
    -- on WorldMapFrame_OnEvent, which forced the same call chain but ALSO re-ran
    -- WorldMapFrame_UpdateMapHighlight -- CartoMapper already refreshes the
    -- highlight every frame in its own WorldMapButton_OnUpdate, so we can skip
    -- the heavyweight event dispatch.
    --
    -- On the success path, our hooksecurefunc("WorldMapFrame_UpdateQuests",
    -- ResizeQuestPOIs) already fires and re-anchors the POI buttons -- do NOT
    -- call ResizeQuestPOIs again here, that would compound the 1/s rescale and
    -- drift the markers further on every zoom tick.
    --
    -- On the failure path, the hooksecurefunc chain never fires (the original
    -- never returned normally), so we explicitly run ResizeQuestPOIs ourselves.
    -- In the typical WotLK crash scenario only QuestPOI_HideButtons(4) errors
    -- because buttonType=4 has zero buttons to hide; types 1..3 already
    -- completed, so the surviving POI buttons are still in canonical positions
    -- and ResizeQuestPOIs can safely re-anchor them for the new scale.
    local ok = pcall(WorldMapFrame_UpdateQuests)
    if not ok then
        ResizeQuestPOIs()
    end
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

local function updatePointRelativeTo(frame, newRelativeFrame)
    if not frame then return end
    local currentPoint, currentRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY = frame:GetPoint()
    if currentPoint and currentRelativePoint then
        if currentRelativeFrame == newRelativeFrame then return end
        frame:ClearAllPoints()
        frame:SetPoint(currentPoint, newRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY)
    end
end

function CartoMapper.UpdateElementScales()
    local scale = WorldMapFrame:GetScale() or 1.0
    local invScale = 1 / scale

    if CartoMapper_CoordsFrame then
        CartoMapper_CoordsFrame:SetScale(invScale)
    end
    
    local fogToggle = _G["CartoMapperFogToggle"]
    if fogToggle then
        fogToggle:SetScale(1.0)
    end
    
    if WorldMapTrackQuest then
        WorldMapTrackQuest:SetScale(1.0)
    end
    
    if WorldMapQuestShowObjectives then
        WorldMapQuestShowObjectives:SetScale(1.0)
    end
    
    if WorldMapTooltip then
        WorldMapTooltip:SetScale(invScale)
    end
end

function CartoMapper.ClampMapScale(scale)
    local screenW = GetScreenWidth()
    local screenH = GetScreenHeight()
    -- Convert raw window pixel dimensions into the logical (UI) coordinate space
    -- the map frame is sized in. GetScreenWidth/Height return physical pixels and
    -- do not account for the player's UI scale, but the map frame's pixel size
    -- *is* multiplied by UIParent's effective scale at render time. Without this
    -- conversion, allowing scale <= screenW/mapW at high UI scale still lets the
    -- map overflow off the screen edge ("map doesn't fit the window properly").
    local uiScale = UIParent:GetEffectiveScale() or 1.0
    local logicalW = screenW / uiScale
    local logicalH = screenH / uiScale
    local mapW = WorldMapFrame:GetWidth() or 1026
    local mapH = WorldMapFrame:GetHeight() or 732
    -- Small margin so the framed map isn't pressed against the screen edges; at
    -- high UI scales rounding eats a few logical pixels and the WoW frame has
    -- ~6px of title/border chrome around the scroll content.
    local padding = 16
    local maxScaleX = (logicalW - padding) / mapW
    local maxScaleY = (logicalH - padding) / mapH
    local maxFitScale = math.min(maxScaleX, maxScaleY)
    return math.max(0.5, math.min(scale, maxFitScale))
end

local function ClampMapScale(scale)
    return CartoMapper.ClampMapScale(scale)
end

local function SetupWorldMapFrame()
    if not WorldMapScrollFrame then return end
    if BlackoutWorld then
        BlackoutWorld:Hide()
    end
    WorldMapScrollFrameScrollBar:Hide()
    CartoMapper.UpdateClickThrough()
    WorldMapScrollFrame.panning = false
    WorldMapScrollFrame.moved = false
    WorldMapScrollFrame.manuallyPanned = false

    -- Immediately set zoom state to prevent click-to-pan race conditions on deferred updates
    if CartoMapper.DB.GetOpt("zoom") and CartoMapper.DB.GetOpt("rememberZoom") and GetCurrentMapZone() == PreviousState.zone then
        WorldMapScrollFrame.zoomedIn = PreviousState.scale > MIN_ZOOM
    else
        WorldMapScrollFrame.zoomedIn = false
    end

    -- Adapt coordinates of quest tracker and frame positions based on WotLK sizes
    WorldMapScrollFrame:ClearAllPoints()
    if WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE and (WorldMapQuestScrollFrame and WorldMapQuestScrollFrame:IsShown()) then
        WorldMapFrame:SetFrameStrata("FULLSCREEN")
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -726, -99)
        if WorldMapTrackQuest then
            WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 8, 4)
        end
    elseif WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE or WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE then
        WorldMapFrame:SetFrameStrata("HIGH")
        if WorldMapTrackQuest then
            WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9)
        end

        WorldMapFrame:SetClampedToScreen(true)
        WorldMapFrame:SetPoint("TOPLEFT", WorldMapScreenAnchor or UIParent, 0, 0)
        WorldMapFrame:SetScale(ClampMapScale(CartoMapper.DB.GetOpt("mapScale") or 1.0))
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
        WorldMapFrame:SetFrameStrata("FULLSCREEN")
        WorldMapFrame:SetScale(1.0)
        WorldMapFrame:SetMovable(false)
        WorldMapFrame:RegisterForDrag()
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT", 11, -70.5)
        if WorldMapTrackQuest then
            WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9)
        end
    end

    WorldMapScrollFrame:SetScale(WORLDMAP_SETTINGS.size)
    
    -- Correct scroll child dimensions and remove parent constraints to prevent layout conflicts
    if WorldMapScrollFrame:GetScrollChild() ~= WorldMapDetailFrame then
        WorldMapDetailFrame:ClearAllPoints()
        WorldMapScrollFrame:SetScrollChild(WorldMapDetailFrame)
        WorldMapDetailFrame:SetSize(1002, 668)
    end

    -- Defer scale and scroll updates to the next frame to allow the engine layout to process.
    -- This resolves the "blank/invisible map" issue on reopening the map frame.
    deferFrame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        if WorldMapFrame:IsShown() then
            local targetScale = 1.0
            if CartoMapper.DB.GetOpt("zoom") and CartoMapper.DB.GetOpt("rememberZoom") and GetCurrentMapZone() == PreviousState.zone then
                targetScale = ClampMapScale(PreviousState.scale)
                SetDetailFrameScale(targetScale)
                WorldMapScrollFrame:SetHorizontalScroll(PreviousState.panX)
                WorldMapScrollFrame:SetVerticalScroll(PreviousState.panY)
                WorldMapScrollFrame.zoomedIn = targetScale > MIN_ZOOM
            else
                SetDetailFrameScale(1.0)
                WorldMapScrollFrame:SetHorizontalScroll(0)
                WorldMapScrollFrame:SetVerticalScroll(0)
                WorldMapScrollFrame.zoomedIn = false
            end
            
            WorldMapScrollFrame.maxX = ((WorldMapDetailFrame:GetWidth() * targetScale) - WorldMapScrollFrame:GetWidth()) / targetScale
            WorldMapScrollFrame.maxY = ((WorldMapDetailFrame:GetHeight() * targetScale) - WorldMapScrollFrame:GetHeight()) / targetScale

            AfterScrollOrPan()
            if WorldMapFrame_Update then
                WorldMapFrame_Update()
            end
        end
    end)

    if WorldMapButton:GetParent() ~= WorldMapDetailFrame then
        WorldMapButton:SetParent(WorldMapDetailFrame)
        WorldMapButton:SetScale(1.0)
        WorldMapButton:ClearAllPoints()
        WorldMapButton:SetAllPoints(WorldMapDetailFrame)
    end
    if WorldMapPOIFrame:GetParent() ~= WorldMapDetailFrame then
        WorldMapPOIFrame:SetParent(WorldMapDetailFrame)
    end
    if not InCombatLockdown() and WorldMapBlobFrame:GetParent() ~= WorldMapDetailFrame then
        WorldMapBlobFrame:SetParent(WorldMapDetailFrame)
        WorldMapBlobFrame:ClearAllPoints()
        WorldMapBlobFrame:SetAllPoints(WorldMapDetailFrame)
    end
    if WorldMapPlayer:GetParent() ~= WorldMapDetailFrame then
        WorldMapPlayer:SetParent(WorldMapDetailFrame)
    end

    -- Anchor Quest Log sub-elements to the scroll frame instead of the scaled detail frame
    updatePointRelativeTo(WorldMapQuestScrollFrame, WorldMapScrollFrame)
    updatePointRelativeTo(WorldMapQuestDetailScrollFrame, WorldMapScrollFrame)

    -- Handle borderless windowed map elements initial visibility
    if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE and CartoMapper.DB.GetOpt("borderless") then
        WorldMapFrameMiniBorderLeft:Hide()
        WorldMapFrameMiniBorderRight:Hide()
        WorldMapFrameTitle:Hide()
        WorldMapTitleButton:Hide()
        WorldMapFrameCloseButton:Hide()
        WorldMapFrameSizeUpButton:Hide()
        WorldMapFrameSizeDownButton:Hide()
    elseif WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        WorldMapFrameMiniBorderLeft:Show()
        WorldMapFrameMiniBorderRight:Show()
        WorldMapFrameTitle:Show()
        WorldMapTitleButton:Show()
        WorldMapFrameCloseButton:Show()
        WorldMapFrameSizeUpButton:Show()
        WorldMapFrameSizeDownButton:Hide()
    end

    local resizeHandle = _G["CartoMapperResizeHandle"]
    if resizeHandle then
        if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
            resizeHandle:Show()
        else
            resizeHandle:Hide()
        end
    end

    -- Update detail tiles visibility for landmass borderless mask
    UpdateDetailTilesVisibility()

    -- Correct element scales for text/tooltips
    CartoMapper.UpdateElementScales()
end

function CartoMapper.UpdateBorderless()
    if not WorldMapScrollFrame then return end
    SetupWorldMapFrame()
end

-- Mouse Scroll Zoom Handler
local function WorldMapScrollFrame_OnMouseWheel(self, delta)
    if not CartoMapper.DB.GetOpt("zoom") then return end
    WorldMapScrollFrame.manuallyPanned = false
    -- Ctrl + Scroll scales the windowed world map frame itself
    if IsControlKeyDown() and WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        local oldScale = WorldMapFrame:GetScale()
        local newScale = oldScale + delta * MINIMODE_ZOOM_STEP
        newScale = math.max(MINIMODE_MIN_ZOOM, newScale)
        newScale = math.min(MINIMODE_MAX_ZOOM, newScale)

        WorldMapFrame:SetScale(ClampMapScale(newScale))
        CartoMapper.DB.SetOpt("mapScale", newScale)
        if CartoMapperConfigFrame and CartoMapperConfigFrame:IsShown() then
            CartoMapperConfigFrame:UpdateAllValues()
        end
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
    local zoomStep = CartoMapper.DB.GetOpt("zoomStep") or 0.1
    local newScale = oldScale * (1.0 + delta * zoomStep)
    newScale = math.max(MIN_ZOOM, newScale)
    
    local maxZoomLimit = CartoMapper.DB.GetOpt("maxZoom") or 10.0
    newScale = math.min(maxZoomLimit, newScale)

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
    if IsControlKeyDown() then return end
    if not CartoMapper.DB.GetOpt("zoom") then return end
    
    -- Sync zoomedIn state with actual detail frame scale to prevent any event order/timing issues
    if WorldMapDetailFrame:GetScale() > 1.001 then
        WorldMapScrollFrame.zoomedIn = true
    end

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
    if IsControlKeyDown() and button == "LeftButton" then
        WorldMapScrollFrame.panning = false
        local cursorX, cursorY = GetCursorPosition()
        local scale = WorldMapDetailFrame:GetEffectiveScale()
        local left = WorldMapDetailFrame:GetLeft()
        local top = WorldMapDetailFrame:GetTop()
        local width = WorldMapDetailFrame:GetWidth()
        local height = WorldMapDetailFrame:GetHeight()
        if scale and left and top and width and height then
            local x = (cursorX / scale - left) / width
            local y = (top - cursorY / scale) / height
            if x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                if CartoMapper.AddWaypointAt then
                    CartoMapper.AddWaypointAt(x * 100, y * 100)
                end
            end
        end
        return
    end

    if not CartoMapper.DB.GetOpt("zoom") then
        WorldMapButton_OnClick(WorldMapButton, button)
        return
    end
    WorldMapScrollFrame.panning = false
    if not WorldMapScrollFrame.moved then
        if button == "RightButton" and WorldMapScrollFrame.zoomedIn then
            -- Reset zoom on the current zone instead of zooming out of the zone
            SetDetailFrameScale(MIN_ZOOM)
            WorldMapScrollFrame:SetHorizontalScroll(0)
            WorldMapScrollFrame:SetVerticalScroll(0)
            AfterScrollOrPan()
            WorldMapScrollFrame.zoomedIn = false
            WorldMapScrollFrame.manuallyPanned = false
        else
            -- Default zoom click (subzone/continent click or standard right click zoom out)
            WorldMapButton_OnClick(WorldMapButton, button)
            -- Reset scale when changing zones
            SetDetailFrameScale(MIN_ZOOM)
            WorldMapScrollFrame:SetHorizontalScroll(0)
            WorldMapScrollFrame:SetVerticalScroll(0)
            AfterScrollOrPan()
            WorldMapScrollFrame.zoomedIn = false
        end
    else
        WorldMapScrollFrame.manuallyPanned = true
    end
    WorldMapScrollFrame.moved = false
end

local function WorldMapScrollFrame_OnPan(cursorX, cursorY)
    local dX = WorldMapScrollFrame.cursorX - cursorX
    local dY = cursorY - WorldMapScrollFrame.cursorY
    local scale = WorldMapScrollFrame:GetEffectiveScale()
    local detailScale = WorldMapDetailFrame:GetScale() or 1.0
    dX = (dX / scale) / detailScale
    dY = (dY / scale) / detailScale
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
    -- Handle borderless windowed map elements visibility on mouse hover
    if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        if CartoMapper.DB.GetOpt("borderless") then
            if WorldMapFrame:IsMouseOver() then
                WorldMapFrameMiniBorderLeft:Show()
                WorldMapFrameMiniBorderRight:Show()
                WorldMapFrameTitle:Show()
                WorldMapTitleButton:Show()
                WorldMapFrameCloseButton:Show()
                WorldMapFrameSizeUpButton:Show()
            else
                WorldMapFrameMiniBorderLeft:Hide()
                WorldMapFrameMiniBorderRight:Hide()
                WorldMapFrameTitle:Hide()
                WorldMapTitleButton:Hide()
                WorldMapFrameCloseButton:Hide()
                WorldMapFrameSizeUpButton:Hide()
                WorldMapFrameSizeDownButton:Hide()
            end
        end
    end

    -- Handle map panning
    if WorldMapScrollFrame.panning then
        local x, y = GetCursorPosition()
        WorldMapScrollFrame_OnPan(x, y)
    end

    -- Auto-center on player if followPlayer is enabled, map is zoomed in, we haven't manually panned, and Shift is not held down
    if CartoMapper.DB.GetOpt("followPlayer") and WorldMapScrollFrame.zoomedIn and not WorldMapScrollFrame.manuallyPanned and not WorldMapScrollFrame.panning and not IsShiftKeyDown() then
        local playerX, playerY = GetPlayerMapPosition("player")
        if playerX > 0 and playerY > 0 then
            local scale = WorldMapDetailFrame:GetScale()
            local scrollH = playerX * WorldMapDetailFrame:GetWidth() - (WorldMapScrollFrame:GetWidth() / 2) / scale
            local scrollV = playerY * WorldMapDetailFrame:GetHeight() - (WorldMapScrollFrame:GetHeight() / 2) / scale

            scrollH = math.max(0, math.min(scrollH, WorldMapScrollFrame.maxX or 0))
            scrollV = math.max(0, math.min(scrollV, WorldMapScrollFrame.maxY or 0))

            WorldMapScrollFrame:SetHorizontalScroll(scrollH)
            WorldMapScrollFrame:SetVerticalScroll(scrollV)
            AfterScrollOrPan()
        end
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
    if self:IsMouseOver() and (not WorldMapScrollFrame or WorldMapScrollFrame:IsMouseOver()) then
        name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = UpdateMapHighlight(adjustedX, adjustedY)
    end

    WorldMapFrame.areaName = name
    if not WorldMapFrame.poiHighlight then
        if name and CartoMapper.GetFormattedZoneLevelText then
            WorldMapFrameAreaLabel:SetText(CartoMapper.GetFormattedZoneLevelText(name))
        else
            WorldMapFrameAreaLabel:SetText(name)
        end
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
    if Zoom.enabled then return end
    Zoom.enabled = true

    -- Create the scroll frame dynamically if it doesn't exist yet
    if not WorldMapScrollFrame then
        WorldMapScrollFrame = CreateFrame("ScrollFrame", "WorldMapScrollFrame", WorldMapFrame, "FauxScrollFrameTemplate")
        WorldMapScrollFrame:SetSize(1002, 668)
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT")
    end

    -- Create resize handle
    if not _G["CartoMapperResizeHandle"] then
        local resizeHandle = CreateFrame("Button", "CartoMapperResizeHandle", WorldMapFrame)
        resizeHandle:SetSize(16, 16)
        resizeHandle:SetPoint("BOTTOMRIGHT", WorldMapScrollFrame, "BOTTOMRIGHT", 1, -1)
        resizeHandle:SetFrameLevel(WorldMapScrollFrame:GetFrameLevel() + 5)

        local normalTex = resizeHandle:CreateTexture(nil, "OVERLAY")
        normalTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        normalTex:SetAllPoints(resizeHandle)
        resizeHandle:SetNormalTexture(normalTex)

        local highlightTex = resizeHandle:CreateTexture(nil, "OVERLAY")
        highlightTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        highlightTex:SetAllPoints(resizeHandle)
        resizeHandle:SetHighlightTexture(highlightTex)

        local dragStartScale, dragStartDist
        resizeHandle:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                local left = WorldMapFrame:GetLeft()
                if not left then return end
                
                local cx = GetCursorPosition()
                local uiScale = UIParent:GetEffectiveScale()
                cx = cx / uiScale
                
                dragStartScale = WorldMapFrame:GetScale() or 1.0
                dragStartDist = cx - left
                
                if dragStartDist > 50 then
                    self:SetScript("OnUpdate", function()
                        local curCx = GetCursorPosition()
                        curCx = curCx / uiScale
                        local curDist = curCx - left
                        local newScale = (curDist / dragStartDist) * dragStartScale
                        
                        -- Clamp scale
                        newScale = ClampMapScale(newScale)
                        
                        WorldMapFrame:SetScale(newScale)
                        CartoMapper.DB.SetOpt("mapScale", newScale)
                        
                        if CartoMapper.UpdateElementScales then
                            CartoMapper.UpdateElementScales()
                        end
                        
                        if CartoMapperConfigFrame and CartoMapperConfigFrame:IsShown() then
                            CartoMapperConfigFrame:UpdateAllValues()
                        end
                    end)
                end
            end
        end)

        resizeHandle:SetScript("OnMouseUp", function(self)
            self:SetScript("OnUpdate", nil)
        end)

        resizeHandle:SetScript("OnHide", function(self)
            self:SetScript("OnUpdate", nil)
        end)
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
    hooksecurefunc("WorldMapFrame_Update", UpdateDetailTilesVisibility)

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
        if CartoMapper.DB.GetOpt("lockMap") then return end
        if WorldMapScreenAnchor then
            WorldMapScreenAnchor:ClearAllPoints()
        end
        WorldMapFrame:ClearAllPoints()
        WorldMapFrame:StartMoving()
    end)
    WorldMapTitleButton:SetScript("OnDragStop", function()
        if CartoMapper.DB.GetOpt("lockMap") then return end
        WorldMapFrame:StopMovingOrSizing()
        if WorldMapScreenAnchor then
            WorldMapScreenAnchor:StartMoving()
            WorldMapScreenAnchor:SetPoint("TOPLEFT", WorldMapFrame)
            WorldMapScreenAnchor:StopMovingOrSizing()
        end
    end)

    -- Setup custom OnUpdate for map mouse positioning and pin scaling.
    -- Wrapped in pcall: this function runs every single frame the map is open, and since
    -- it fully replaces Blizzard's own OnUpdate script (rather than hooking it), an
    -- uncaught error here would silently disable map positioning/zoom for the rest of
    -- the session instead of just printing a Lua error once. Error reports are throttled
    -- to avoid spamming chat if the same error recurs every frame.
    local lastOnUpdateErrorTime = 0
    WorldMapButton:SetScript("OnUpdate", function(self, elapsed)
        local ok, err = pcall(WorldMapButton_OnUpdate, self, elapsed)
        if not ok then
            local now = GetTime()
            if now - lastOnUpdateErrorTime > 5 then
                lastOnUpdateErrorTime = now
                if CartoMapper.Print then
                    CartoMapper.Print("|cffff0000Map update error (suppressing repeats for 5s):|r " .. tostring(err))
                end
            end
        end
    end)

    -- Setup on show
    local original_WorldMapFrame_OnShow = WorldMapFrame:GetScript("OnShow")
    WorldMapFrame:SetScript("OnShow", function(self)
        if original_WorldMapFrame_OnShow then
            original_WorldMapFrame_OnShow(self)
        end
        SetupWorldMapFrame()
    end)

    -- Setup modifier listener for temporary click-through bypass (Alt key)
    local modifierFrame = _G["CartoMapperModifierFrame"] or CreateFrame("Frame", "CartoMapperModifierFrame")
    modifierFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    modifierFrame:SetScript("OnEvent", function(self, event, key, state)
        if key == "LALT" or key == "RALT" then
            CartoMapper.UpdateClickThrough()
        end
    end)

    -- Re-clamp the windowed map whenever the player's UI scale changes at runtime
    -- (Interface Options -> Advanced -> UI Scale). The stored mapScale value was
    -- chosen under the old UI scale and may no longer fit the screen after a change,
    -- leaving the map sticking off the side of the window.
    local uiScaleFrame = _G["CartoMapperUIScaleFrame"] or CreateFrame("Frame", "CartoMapperUIScaleFrame")
    uiScaleFrame:RegisterEvent("UI_SCALE_CHANGED")
    uiScaleFrame:SetScript("OnEvent", function(self, event)
        if event == "UI_SCALE_CHANGED" then
            local currentScale = CartoMapper.DB and CartoMapper.DB.GetOpt and CartoMapper.DB.GetOpt("mapScale") or 1.0
            local newScale = CartoMapper.ClampMapScale(currentScale)
            if WorldMapFrame and WorldMapFrame:IsShown() then
                WorldMapFrame:SetScale(newScale)
                if newScale ~= currentScale then
                    CartoMapper.DB.SetOpt("mapScale", newScale)
                    if CartoMapperConfigFrame and CartoMapperConfigFrame:IsShown() then
                        CartoMapperConfigFrame:UpdateAllValues()
                    end
                end
                if CartoMapper.UpdateElementScales then
                    CartoMapper.UpdateElementScales()
                end
            end
        end
    end)

    -- Hook tooltip OnShow to scale it inversely to map scale and force it on top
    if WorldMapTooltip and not Zoom.hookedTooltip then
        WorldMapTooltip:HookScript("OnShow", function(self)
            local scale = WorldMapFrame:GetScale() or 1.0
            self:SetScale(1 / scale)
            self:SetFrameStrata("TOOLTIP")
        end)
        Zoom.hookedTooltip = true
    end

    -- Combat safe quest blob handler to prevent action-blocked taints in combat
    local combatFrame = _G["CartoMapperCombatFrame"] or CreateFrame("Frame", "CartoMapperCombatFrame")
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    local blobWasVisible, blobNewScale
    local blobHideFunc = function() blobWasVisible = nil end
    local blobShowFunc = function() blobWasVisible = true end
    local blobScaleFunc = function(self, scale) blobNewScale = scale end
    
    local updateFrame = CreateFrame("Frame")
    local function restoreBlobs()
        if WorldMapBlobFrame_CalculateHitTranslations then
            WorldMapBlobFrame_CalculateHitTranslations()
        end
        if WorldMapQuestScrollChildFrame and WorldMapQuestScrollChildFrame.selected and not WorldMapQuestScrollChildFrame.selected.completed then
            WorldMapBlobFrame:DrawQuestBlob(WorldMapQuestScrollChildFrame.selected.questId, true)
        end
        updateFrame:SetScript("OnUpdate", nil)
    end
    
    combatFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if WorldMapBlobFrame then
                blobWasVisible = WorldMapBlobFrame:IsShown()
                blobNewScale = nil
                WorldMapBlobFrame:SetParent(nil)
                WorldMapBlobFrame:ClearAllPoints()
                WorldMapBlobFrame:SetPoint("TOP", UIParent, "BOTTOM")
                WorldMapBlobFrame:Hide()
                WorldMapBlobFrame.Hide = blobHideFunc
                WorldMapBlobFrame.Show = blobShowFunc
                WorldMapBlobFrame.SetScale = blobScaleFunc
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if WorldMapBlobFrame then
                WorldMapBlobFrame:SetParent(WorldMapDetailFrame)
                WorldMapBlobFrame:ClearAllPoints()
                WorldMapBlobFrame:SetAllPoints(WorldMapDetailFrame)
                WorldMapBlobFrame.Hide = nil
                WorldMapBlobFrame.Show = nil
                WorldMapBlobFrame.SetScale = nil
                if blobWasVisible then
                    WorldMapBlobFrame:Show()
                    updateFrame:SetScript("OnUpdate", restoreBlobs)
                end
                if blobNewScale then
                    WorldMapBlobFrame:SetScale(blobNewScale)
                    WorldMapBlobFrame.xRatio = nil
                    blobNewScale = nil
                end
                if WorldMapQuestScrollChildFrame and WorldMapQuestScrollChildFrame.selected then
                    WorldMapBlobFrame:DrawQuestBlob(WorldMapQuestScrollChildFrame.selected.questId, false)
                end
            end
        end
    end)

    if InCombatLockdown() then
        combatFrame:GetScript("OnEvent")(combatFrame, "PLAYER_REGEN_DISABLED")
    end

    local function IsDescendantOf(frame, parent)
        while frame do
            if frame == parent then return true end
            frame = frame:GetParent()
        end
        return false
    end

    if not Zoom.hookedDropDown then
        hooksecurefunc("ToggleDropDownMenu", function(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button)
            if WorldMapFrame and WorldMapFrame:IsShown() and WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
                if dropDownFrame and IsDescendantOf(dropDownFrame, WorldMapFrame) then
                    local scale = WorldMapFrame:GetScale() or 1.0
                    local list = _G["DropDownList" .. (level or 1)]
                    if list then
                        list:SetScale(scale)
                    end
                end
            end
        end)
        Zoom.hookedDropDown = true
    end
end

function Zoom.Disable()
    -- The hooks/scaffolding installed in Enable() can't be removed at runtime (WoW's
    -- API gives no way to undo hooksecurefunc or a replaced OnUpdate script). What we
    -- *can* do is immediately drop any active zoom/pan back to the unzoomed default, so
    -- turning this off doesn't leave the map stuck zoomed in with no way back via the UI.
    CartoMapper.UpdateZoom()
end

function CartoMapper.UpdateZoom()
    if not WorldMapScrollFrame then return end
    if not CartoMapper.DB.GetOpt("zoom") then
        -- Reset zoom state to default
        SetDetailFrameScale(1.0)
        WorldMapScrollFrame:SetHorizontalScroll(0)
        WorldMapScrollFrame:SetVerticalScroll(0)
        WorldMapScrollFrame.zoomedIn = false
        AfterScrollOrPan()
    end
    if WorldMapFrame and WorldMapFrame:IsShown() then
        SetupWorldMapFrame()
    end
end
