--[[--------------------------------------------------------------------------------------------
Coords.lua
Coordinate display for the World Map.
--------------------------------------------------------------------------------------------]]--

local Coords = {}
CartoMapper.modules["coords"] = Coords
Coords.liveToggle = true

local cursortext, playertext
local texttemplate = "%s: %.1f, %.1f"

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
    local template = "%s: %." .. acc .. "f, %." .. acc .. "f"

    if cx then
        cursortext:SetFormattedText(template, "Cursor", cx * 100, cy * 100)
    else
        cursortext:SetText("")
    end

    if px and px > 0 and py and py > 0 then
        playertext:SetFormattedText(template, "Player", px * 100, py * 100)
    else
        playertext:SetText("")
    end
end

local function UpdatePosition()
    if not cursortext or not playertext then return end
    if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        cursortext:ClearAllPoints()
        cursortext:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOM", 15, -2)
        playertext:ClearAllPoints()
        playertext:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOM", -30, -2)
    else
        cursortext:ClearAllPoints()
        cursortext:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOM", 50, 10)
        playertext:ClearAllPoints()
        playertext:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOM", -50, 10)
    end
end

function Coords.Enable()
    if Coords.enabled then 
        local frame = _G["CartoMapper_CoordsFrame"]
        if frame then frame:Show() end
        return 
    end
    Coords.enabled = true

    local display = _G["CartoMapper_CoordsFrame"] or CreateFrame("Frame", "CartoMapper_CoordsFrame", WorldMapFrame)
    if not cursortext then
        cursortext = display:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        playertext = display:CreateFontString(nil, "ARTWORK", "GameFontNormal")
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
