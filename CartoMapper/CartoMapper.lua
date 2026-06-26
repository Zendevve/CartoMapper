--[[--------------------------------------------------------------------------------------------
CartoMapper.lua
Core initialization, options, and slash commands.
--------------------------------------------------------------------------------------------]]--

CartoMapper = CreateFrame("Frame")
CartoMapper:RegisterEvent("ADDON_LOADED")

-- Global tables for sub-modules to register their logic
CartoMapper.modules = {}

local defaults = {
    zoom = true,
    coords = true,
    battleMap = true,
    groupIcons = true,
    fogClear = true,
    pois = true,
    -- Fog clear settings
    fogColorStyle = 0,     -- 0: Blue/Emerald, 1: Normal, 2: Custom
    fogTransparency = 0.5, -- Unexplored area opacity
    fogR = 0.2,
    fogG = 0.6,
    fogB = 1.0,
    -- Map settings
    mapScale = 1.0,
    movingOpacity = 1.0,
    stationaryOpacity = 1.0,
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffb0[CartoMapper]|r: " .. msg)
end

function CartoMapper:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == "CartoMapper" then
        -- Initialize SavedVariables
        if not CartoMapperDB then
            CartoMapperDB = {}
        end
        for k, v in pairs(defaults) do
            if CartoMapperDB[k] == nil then
                CartoMapperDB[k] = v
            end
        end

        -- Initialize all loaded modules
        for name, module in pairs(CartoMapper.modules) do
            if CartoMapperDB[name] then
                if module.Enable then
                    module.Enable()
                end
            end
        end

        Print("Loaded! Type /cm or /cartomapper for commands.")
    end
end

CartoMapper:SetScript("OnEvent", CartoMapper.OnEvent)

-- Slash Command Handler
local function SlashHandler(msg)
    local cmd, arg = string.split(" ", string.lower(msg or ""))
    cmd = cmd or ""
    
    if cmd == "toggle" and arg then
        if defaults[arg] ~= nil then
            CartoMapperDB[arg] = not CartoMapperDB[arg]
            Print(arg .. " is now " .. (CartoMapperDB[arg] and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r") .. ". Please /reload to apply changes.")
        else
            Print("Unknown toggle option: " .. arg)
        end
    elseif cmd == "status" then
        Print("Current Settings:")
        for k, v in pairs(defaults) do
            if type(v) == "boolean" then
                DEFAULT_CHAT_FRAME:AddMessage("  " .. k .. ": " .. (CartoMapperDB[k] and "|cff00ff00On|r" or "|cffff0000Off|r"))
            end
        end
    else
        Print("Available Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /cm status - Show current settings status")
        DEFAULT_CHAT_FRAME:AddMessage("  /cm toggle <option> - Toggle a module. Options: zoom, coords, battlemap, groupicons, fogclear, pois")
        DEFAULT_CHAT_FRAME:AddMessage("  /reload - Reload interface to apply changes")
    end
end

SLASH_CARTOMAPPER1 = "/cartomapper"
SLASH_CARTOMAPPER2 = "/cm"
SlashCmdList["CARTOMAPPER"] = SlashHandler
