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
    fogColorStyle = 1,     -- 0: Blue/Emerald, 1: Normal, 2: Custom
    fogTransparency = 0.7, -- Unexplored area opacity
    fogR = 0.2,
    fogG = 0.6,
    fogB = 1.0,
    -- Map settings
    mapScale = 1.0,
    movingOpacity = 1.0,
    stationaryOpacity = 1.0,
    hideBorder = false,
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

        -- Migrate old defaults (Blue/Emerald tint) to new standard Normal style
        if CartoMapperDB.fogColorStyle == 0 and CartoMapperDB.fogR == 0.2 and CartoMapperDB.fogG == 0.6 and CartoMapperDB.fogB == 1.0 then
            CartoMapperDB.fogColorStyle = 1
            CartoMapperDB.fogTransparency = 0.7
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
        local dbKey = arg
        if arg == "border" then
            dbKey = "hideBorder"
        end
        if defaults[dbKey] ~= nil then
            CartoMapperDB[dbKey] = not CartoMapperDB[dbKey]
            if dbKey == "hideBorder" and CartoMapper.modules["zoom"] and CartoMapper.modules["zoom"].UpdateBorderVisibility then
                CartoMapper.modules["zoom"].UpdateBorderVisibility()
            end
            if dbKey == "hideBorder" then
                Print("border is now " .. (CartoMapperDB.hideBorder and "|cff00ff00Hidden|r" or "|cffff0000Shown|r") .. ".")
            else
                Print(arg .. " is now " .. (CartoMapperDB[dbKey] and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r") .. ". Please /reload to apply changes.")
            end
        else
            Print("Unknown toggle option: " .. arg)
        end
    elseif cmd == "status" then
        Print("Current Settings:")
        for k, v in pairs(defaults) do
            if type(v) == "boolean" then
                local displayKey = k
                local displayVal = CartoMapperDB[k]
                if k == "hideBorder" then
                    displayKey = "border (hidden)"
                end
                DEFAULT_CHAT_FRAME:AddMessage("  " .. displayKey .. ": " .. (displayVal and "|cff00ff00On|r" or "|cffff0000Off|r"))
            end
        end
    else
        Print("Available Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /cm status - Show current settings status")
        DEFAULT_CHAT_FRAME:AddMessage("  /cm toggle <option> - Toggle a module. Options: zoom, coords, battlemap, groupicons, fogclear, pois, border")
        DEFAULT_CHAT_FRAME:AddMessage("  /reload - Reload interface to apply changes")
    end
end

SLASH_CARTOMAPPER1 = "/cartomapper"
SLASH_CARTOMAPPER2 = "/cm"
SlashCmdList["CARTOMAPPER"] = SlashHandler
