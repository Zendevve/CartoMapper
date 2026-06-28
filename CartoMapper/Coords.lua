--[[--------------------------------------------------------------------------------------------
Coords.lua
Coordinate display for the World Map.
--------------------------------------------------------------------------------------------]]--

local Coords = {}
CartoMapper.modules["coords"] = Coords
Coords.liveToggle = true

local coordstext

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

    if pStr and cStr then
        coordstext:SetText(pStr .. "   " .. cStr)
    elseif pStr then
        coordstext:SetText(pStr)
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
