--[[--------------------------------------------------------------------------------------------
Coords.lua
Coordinate display for the World Map.
--------------------------------------------------------------------------------------------]]--

local Coords = {}
CartoMapper.modules["coords"] = Coords

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

    return cx, cy
end

local function OnUpdate(self, elapsed)
    local cx, cy = MouseXY()
    local px, py = GetPlayerMapPosition("player")

    if cx then
        cursortext:SetFormattedText(texttemplate, "Cursor", cx * 100, cy * 100)
    else
        cursortext:SetText("")
    end

    if px and px > 0 and py and py > 0 then
        playertext:SetFormattedText(texttemplate, "Player", px * 100, py * 100)
    else
        playertext:SetText("")
    end
end

local function UpdatePosition()
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
    local display = CreateFrame("Frame", "CartoMapper_CoordsFrame", WorldMapFrame)
    cursortext = display:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    playertext = display:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    
    UpdatePosition()
    display:SetScript("OnUpdate", OnUpdate)

    -- Update position when map changes sizes
    hooksecurefunc("WorldMapFrame_SetFullMapView", UpdatePosition)
    hooksecurefunc("WorldMapFrame_SetQuestMapView", UpdatePosition)
    hooksecurefunc("WorldMap_ToggleSizeDown", UpdatePosition)
    hooksecurefunc("WorldMap_ToggleSizeUp", UpdatePosition)
end
