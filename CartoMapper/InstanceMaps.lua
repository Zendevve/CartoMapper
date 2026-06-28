--[[--------------------------------------------------------------------------------------------
InstanceMaps.lua
Allows viewing Instance and Battleground Maps offline from Continent/Zone dropdowns.
--------------------------------------------------------------------------------------------]]--

local InstanceMaps = CreateFrame("Frame")
CartoMapper.modules["instanceMaps"] = InstanceMaps

local data = {
	iclassic = {
		["Ragefire Chasm"] = 680,
		["Zul'Farrak"] = 686,
		["The Temple of Atal'Hakkar"] = 687,
		["Blackfathom Deeps"] = 688,
		["The Stockade"] = 690,
		["Gnomeregan"] = 691,
		["Uldaman"] = 692,
		["Dire Maul"] = 699,
		["Blackrock Depths"] = 704,
		["Blackrock Spire"] = 721,
		["Wailing Caverns"] = 749,
		["Maraudon"] = 750,
		["The Deadmines"] = 756,
		["Razorfen Downs"] = 760,
		["Razorfen Kraul"] = 761,
		["Scarlet Monastery"] = 762,
		["Scholomance"] = 763,
		["Shadowfang Keep"] = 764,
		["Stratholme"] = 765,
	},
	rclassic = {
		["Molten Core"] = 696,
		["Blackwing Lair"] = 755,
		["Ruins of Ahn'Qiraj"] = 717,
		["Ahn'Qiraj"] = 766,
		["Zul'Gurub"] = 697,
	},
	ibc = {
		["The Shattered Halls"] = 710,
		["Auchenai Crypts"] = 722,
		["Sethekk Halls"] = 723,
		["Shadow Labyrinth"] = 724,
		["The Blood Furnace"] = 725,
		["The Underbog"] = 726,
		["The Steamvault"] = 727,
		["The Slave Pens"] = 728,
		["The Botanica"] = 729,
		["The Mechanar"] = 730,
		["The Arcatraz"] = 731,
		["Mana-Tombs"] = 732,
		["The Black Morass"] = 733,
		["Old Hillsbrad Foothills"] = 734,
		["Hellfire Ramparts"] = 797,
		["Magisters' Terrace"] = 798,
	},
	rbc = {
		["Hyjal Summit"] = 775,
		["Gruul's Lair"] = 776,
		["Magtheridon's Lair"] = 779,
		["Serpentshrine Cavern"] = 780,
		["The Eye"] = 782,
		["Sunwell Plateau"] = 789,
		["Black Temple"] = 796,
		["Karazhan"] = 799,
	},
	iwrath = {
		["The Nexus"] = 520,
		["The Culling of Stratholme"] = 521,
		["Ahn'kahet: The Old Kingdom"] = 522,
		["Utgarde Keep"] = 523,
		["Utgarde Pinnacle"] = 524,
		["Halls of Lightning"] = 525,
		["Halls of Stone"] = 526,
		["The Oculus"] = 528,
		["Gundrak"] = 530,
		["Azjol-Nerub"] = 533,
		["Drak'Tharon Keep"] = 534,
		["The Violet Hold"] = 536,
		["Trial of the Champion"] = 542,
		["The Forge of Souls"] = 601,
		["Pit of Saron"] = 602,
		["Halls of Reflection"] = 603,
	},
	rwrath = {
		["The Eye of Eternity"] = 527,
		["Ulduar"] = 529,
		["The Obsidian Sanctum"] = 531,
		["Vault of Archavon"] = 532,
		["Naxxramas"] = 535,
		["Trial of the Crusader"] = 543,
		["Icecrown Citadel"] = 604,
		["The Ruby Sanctum"] = 609,
		["Onyxia's Lair"] = 718,
	},
	bgs = {
		["Alterac Valley"] = 401,
		["Warsong Gulch"] = 443,
		["Arathi Basin"] = 461,
		["Eye of the Storm"] = 482,
		["Strand of the Ancients"] = 512,
		["Isle of Conquest"] = 540,
	},
}

InstanceMaps.zone_names = {}
InstanceMaps.zone_data = {}

-- Initialize translation lookup/fallback
local BZ = setmetatable({}, {__index = function(t, k) return k end})
if LibStub then
    local LBZ = LibStub("LibBabble-Zone-3.0", true)
    if LBZ then
        BZ = LBZ:GetLookupTable()
    end
end

-- Process data tables sorted by localized name
for key, idata in pairs(data) do
    local names = {}
    local name_data = {}
    for name, zdata in pairs(idata) do
        local locName = BZ[name]
        table.insert(names, locName)
        name_data[locName] = zdata
    end
    table.sort(names)
    InstanceMaps.zone_names[key] = names

    local zone_data = {}
    for k, v in ipairs(names) do
        zone_data[k] = name_data[v]
    end
    InstanceMaps.zone_data[key] = zone_data
end
data = nil

local zoomOverride = false

local function MapsterContinentButton_OnClick(button)
    UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown, button:GetID())
    InstanceMaps.mapCont = button.arg1
    InstanceMaps.mapContId = button:GetID()
    zoomOverride = true
    SetMapZoom(-1)
    zoomOverride = nil
end

local function MapsterZoneButton_OnClick(button)
    UIDropDownMenu_SetSelectedID(WorldMapZoneDropDown, button:GetID())
    InstanceMaps.mapZone = button:GetID()
    local mapID = InstanceMaps.zone_data[InstanceMaps.mapCont][InstanceMaps.mapZone]
    if mapID then
        SetMapByID(mapID)
    end
end

local function Mapster_LoadZones(zoneList)
    local info = UIDropDownMenu_CreateInfo()
    for i, name in ipairs(zoneList) do
        info.text = name
        info.func = MapsterZoneButton_OnClick
        info.checked = nil
        UIDropDownMenu_AddButton(info)
    end
end

-- Hook WorldMapContinentsDropDown_Update to preserve selection
hooksecurefunc("WorldMapContinentsDropDown_Update", function()
    if InstanceMaps.enabled and InstanceMaps.mapCont then
        UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown, InstanceMaps.mapContId)
    end
end)

-- Hook WorldMapFrame_LoadContinents to append custom options
hooksecurefunc("WorldMapFrame_LoadContinents", function()
    if not InstanceMaps.enabled then return end

    local info = UIDropDownMenu_CreateInfo()
    
    info.text = "Classic Dungeons"
    info.func = MapsterContinentButton_OnClick
    info.checked = nil
    info.arg1 = "iclassic"
    UIDropDownMenu_AddButton(info)

    info.text = "Classic Raids"
    info.func = MapsterContinentButton_OnClick
    info.checked = nil
    info.arg1 = "rclassic"
    UIDropDownMenu_AddButton(info)

    info.text = "Outland Dungeons"
    info.func = MapsterContinentButton_OnClick
    info.checked = nil
    info.arg1 = "ibc"
    UIDropDownMenu_AddButton(info)

    info.text = "Outland Raids"
    info.func = MapsterContinentButton_OnClick
    info.checked = nil
    info.arg1 = "rbc"
    UIDropDownMenu_AddButton(info)
    
    info.text = "Northrend Dungeons"
    info.func = MapsterContinentButton_OnClick
    info.checked = nil
    info.arg1 = "iwrath"
    UIDropDownMenu_AddButton(info)

    info.text = "Northrend Raids"
    info.func = MapsterContinentButton_OnClick
    info.checked = nil
    info.arg1 = "rwrath"
    UIDropDownMenu_AddButton(info)

    info.text = "Battlegrounds"
    info.func = MapsterContinentButton_OnClick
    info.checked = nil
    info.arg1 = "bgs"
    UIDropDownMenu_AddButton(info)
end)

-- Hook WorldMapZoneDropDown_Update to preserve selection
hooksecurefunc("WorldMapZoneDropDown_Update", function()
    if InstanceMaps.enabled and InstanceMaps.mapZone then
        UIDropDownMenu_SetSelectedID(WorldMapZoneDropDown, InstanceMaps.mapZone)
    end
end)

-- Raw hook for WorldMapZoneDropDown_Initialize
local orig_WorldMapZoneDropDown_Initialize = WorldMapZoneDropDown_Initialize
WorldMapZoneDropDown_Initialize = function(...)
    if InstanceMaps.enabled and InstanceMaps.mapCont then
        local zoneList = InstanceMaps.zone_names[InstanceMaps.mapCont]
        if zoneList then
            Mapster_LoadZones(zoneList)
        end
    else
        orig_WorldMapZoneDropDown_Initialize(...)
    end
end

-- Hook SetMapZoom and SetMapToCurrentZone to clear instance selection when zooming out/swapping continent normally
hooksecurefunc("SetMapZoom", function()
    if not zoomOverride then
        InstanceMaps.mapCont = nil
        InstanceMaps.mapContId = nil
        InstanceMaps.mapZone = nil
    end
end)

hooksecurefunc("SetMapToCurrentZone", function()
    InstanceMaps.mapCont = nil
    InstanceMaps.mapContId = nil
    InstanceMaps.mapZone = nil
end)

function InstanceMaps.Enable()
    InstanceMaps.enabled = true
end

function InstanceMaps.Disable()
    InstanceMaps.enabled = false
    InstanceMaps.mapCont = nil
    InstanceMaps.mapContId = nil
    InstanceMaps.mapZone = nil
end
