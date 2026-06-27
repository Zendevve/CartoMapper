--[[--------------------------------------------------------------------------------------------
ZoneInfo.lua
Database and formatting for Zone level ranges and minimum Fishing skill levels.
Handles hiding of town and city landmark icons.
--------------------------------------------------------------------------------------------]]--

local ZoneInfo = {}
CartoMapper.modules["zoneInfo"] = ZoneInfo
ZoneInfo.liveToggle = true
-- This module has no single matching boolean DB option (it gates two independent
-- features, "zoneLevels" and "hideTownCityIcons", internally) so it must always be
-- enabled at startup for its hook to be installed; see CartoMapper.lua's module loop.
ZoneInfo.alwaysEnable = true

local zoneData = {
    -- Eastern Kingdoms
    ["Alterac Mountains"] = { min = 30, max = 40, fish = "150" },
    ["Arathi Highlands"] = { min = 30, max = 40, fish = "150" },
    ["Badlands"] = { min = 35, max = 45, fish = "none" },
    ["Blasted Lands"] = { min = 45, max = 55, fish = "none" },
    ["Burning Steppes"] = { min = 50, max = 58, fish = "none" },
    ["Deadwind Pass"] = { min = 55, max = 60, fish = "none" },
    ["Dun Morogh"] = { min = 1, max = 10, fish = "1" },
    ["Duskwood"] = { min = 18, max = 30, fish = "75" },
    ["Eastern Plaguelands"] = { min = 55, max = 60, fish = "265" },
    ["Elwynn Forest"] = { min = 1, max = 10, fish = "1" },
    ["Eversong Woods"] = { min = 1, max = 10, fish = "1" },
    ["Ghostlands"] = { min = 10, max = 20, fish = "75" },
    ["Hillsbrad Foothills"] = { min = 20, max = 30, fish = "75" },
    ["Ironforge"] = { min = 1, max = 100, fish = "1" },
    ["Loch Modan"] = { min = 10, max = 20, fish = "75" },
    ["Redridge Mountains"] = { min = 15, max = 25, fish = "75" },
    ["Searing Gorge"] = { min = 43, max = 50, fish = "none" },
    ["Silvermoon City"] = { min = 1, max = 100, fish = "none" },
    ["Silverpine Forest"] = { min = 10, max = 20, fish = "75" },
    ["Stormwind City"] = { min = 1, max = 100, fish = "1" },
    ["Stranglethorn Vale"] = { min = 30, max = 45, fish = "150" },
    ["Swamp of Sorrows"] = { min = 35, max = 45, fish = "150" },
    ["The Hinterlands"] = { min = 40, max = 50, fish = "205" },
    ["Tirisfal Glades"] = { min = 1, max = 10, fish = "1" },
    ["Undercity"] = { min = 1, max = 100, fish = "1" },
    ["Westfall"] = { min = 10, max = 20, fish = "75" },
    ["Wetlands"] = { min = 20, max = 30, fish = "150" },
    ["Isle of Quel'Danas"] = { min = 70, max = 70, fish = "330" },

    -- Kalimdor
    ["Ashenvale"] = { min = 18, max = 30, fish = "75" },
    ["Azshara"] = { min = 45, max = 55, fish = "205" },
    ["Azuremyst Isle"] = { min = 1, max = 10, fish = "1" },
    ["Bloodmyst Isle"] = { min = 10, max = 20, fish = "75" },
    ["Darkshore"] = { min = 10, max = 20, fish = "75" },
    ["Darnassus"] = { min = 1, max = 100, fish = "1" },
    ["Desolace"] = { min = 30, max = 40, fish = "150" },
    ["Durotar"] = { min = 1, max = 10, fish = "1" },
    ["Dustwallow Marsh"] = { min = 35, max = 45, fish = "150" },
    ["Felwood"] = { min = 48, max = 55, fish = "205" },
    ["Feralas"] = { min = 40, max = 50, fish = "205" },
    ["Moonglade"] = { min = 1, max = 100, fish = "205" },
    ["Mulgore"] = { min = 1, max = 10, fish = "1" },
    ["Orgrimmar"] = { min = 1, max = 100, fish = "1" },
    ["Silithus"] = { min = 55, max = 60, fish = "none" },
    ["Stonetalon Mountains"] = { min = 15, max = 25, fish = "75" },
    ["Tanaris"] = { min = 40, max = 50, fish = "225" },
    ["Teldrassil"] = { min = 1, max = 10, fish = "1" },
    ["The Barrens"] = { min = 10, max = 25, fish = "75" },
    ["Thousand Needles"] = { min = 25, max = 35, fish = "75" },
    ["Thunder Bluff"] = { min = 1, max = 100, fish = "1" },
    ["The Exodar"] = { min = 1, max = 100, fish = "none" },
    ["Un'Goro Crater"] = { min = 48, max = 55, fish = "225" },
    ["Winterspring"] = { min = 55, max = 60, fish = "265" },

    -- Outland
    ["Blade's Edge Mountains"] = { min = 65, max = 68, fish = "350" },
    ["Hellfire Peninsula"] = { min = 58, max = 63, fish = "none" },
    ["Nagrand"] = { min = 64, max = 67, fish = "280" },
    ["Netherstorm"] = { min = 67, max = 70, fish = "380" },
    ["Shadowmoon Valley"] = { min = 67, max = 70, fish = "280" },
    ["Shattrath City"] = { min = 1, max = 100, fish = "none" },
    ["Terokkar Forest"] = { min = 62, max = 65, fish = "355" },
    ["Zangarmarsh"] = { min = 60, max = 64, fish = "305" },

    -- Northrend
    ["Borean Tundra"] = { min = 68, max = 72, fish = "380" },
    ["Howling Fjord"] = { min = 68, max = 72, fish = "380" },
    ["Dragonblight"] = { min = 71, max = 74, fish = "380" },
    ["Grizzly Hills"] = { min = 73, max = 77, fish = "380" },
    ["Zul'Drak"] = { min = 74, max = 77, fish = "none" },
    ["Sholazar Basin"] = { min = 75, max = 78, fish = "380" },
    ["The Storm Peaks"] = { min = 77, max = 80, fish = "380" },
    ["Icecrown"] = { min = 77, max = 80, fish = "380" },
    ["Crystalsong Forest"] = { min = 77, max = 80, fish = "380" },
    ["Hrothgar's Landing"] = { min = 77, max = 80, fish = "380" },
    ["Dalaran"] = { min = 74, max = 80, fish = "430" },
    ["Wintergrasp"] = { min = 75, max = 80, fish = "430" },
}

function CartoMapper.GetFormattedZoneLevelText(zoneName)
    if not CartoMapper.DB.GetOpt("zoneLevels") then return zoneName end
    local data = zoneData[zoneName]
    if not data then return zoneName end
    
    local playerLevel = UnitLevel("player")
    local colorStr
    
    if playerLevel < data.min then
        -- Red / hard
        colorStr = "ffff1a1a"
    elseif playerLevel > data.max then
        -- Grey / easy
        colorStr = "ff808080"
    else
        -- Green / perfect
        colorStr = "ff1aefff"
    end
    
    local formatted = string.format("%s |c%s(%d-%d)|r", zoneName, colorStr, data.min, data.max)
    if data.fish and data.fish ~= "none" then
        formatted = formatted .. " |cffffb000[Fish: " .. data.fish .. "]|r"
    end
    return formatted
end

local function HideTownCityPOIs()
    if not ZoneInfo.enabled or not CartoMapper.DB.GetOpt("hideTownCityIcons") then return end
    -- Check if we are viewing a continent map (Continent > 0, Zone == 0)
    if GetCurrentMapContinent() > 0 and GetCurrentMapZone() == 0 then
        local numLandmarks = GetNumMapLandmarks()
        for i = 1, numLandmarks do
            local name, description, textureIndex, x, y, mapLinkID, showInBattleMinimap = GetMapLandmarkInfo(i)
            local button = _G["WorldMapFramePOI" .. i]
            if button and (textureIndex == 1 or textureIndex == 2) then
                button:Hide()
            end
        end
    end
end

function ZoneInfo.Enable()
    ZoneInfo.enabled = true
    
    if not ZoneInfo.hookedPOI then
        hooksecurefunc("WorldMapFrame_UpdateLandmarks", HideTownCityPOIs)
        ZoneInfo.hookedPOI = true
    end

    if WorldMapFrame and WorldMapFrame:IsShown() then
        WorldMapFrame_UpdateLandmarks()
    end
end

function ZoneInfo.Disable()
    ZoneInfo.enabled = false
    -- Refresh POI frame to show town/city landmarks again
    if WorldMapFrame and WorldMapFrame:IsShown() then
        WorldMapFrame_UpdateLandmarks()
    end
end
