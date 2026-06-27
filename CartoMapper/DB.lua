--[[--------------------------------------------------------------------------------------------
DB.lua
Database profile and option storage system.
Handles global settings, character-specific overrides, and migration.
--------------------------------------------------------------------------------------------]]--

CartoMapper = CartoMapper or CreateFrame("Frame")
CartoMapperDB = CartoMapperDB or {}

local DB = {}
CartoMapper.DB = DB

-- Registry of option defaults
local defaultsRegistry = {}

-- Key for current character
local charKey
local function GetCharKey()
    if not charKey then
        local name = UnitName("player")
        local realm = GetRealmName()
        if name and name ~= "" and realm and realm ~= "" then
            charKey = name .. "-" .. realm
        end
    end
    return charKey or "Unknown-Default"
end

function DB.RegisterDefaults(tbl)
    for k, v in pairs(tbl) do
        defaultsRegistry[k] = v
    end
end

-- Initialize database and perform migration
function DB.Initialize()
    local charName = GetCharKey()

    -- Ensure tables exist
    if not CartoMapperDB.global then
        CartoMapperDB.global = {}
    end
    if not CartoMapperDB.char then
        CartoMapperDB.char = {}
    end
    if not CartoMapperDB.charActive then
        CartoMapperDB.charActive = {}
    end

    -- Legacy database migration (if CartoMapperDB contains old flat keys)
    local isLegacy = false
    for k, v in pairs(CartoMapperDB) do
        if k ~= "global" and k ~= "char" and k ~= "charActive" and k ~= "v" then
            isLegacy = true
            CartoMapperDB.global[k] = v
            CartoMapperDB[k] = nil
        end
    end

    -- Migrate old default Blue/Emerald tint to Normal style if present.
    -- Gated by version so this only ever runs once, on the upgrade that introduced it,
    -- rather than re-checking every login (which could also misfire if someone
    -- deliberately picked these exact custom color values later).
    local dbVersion = CartoMapperDB.v or 1
    if dbVersion < 2 then
        if CartoMapperDB.global.fogColorStyle == 0 and CartoMapperDB.global.fogR == 0.2 and CartoMapperDB.global.fogG == 0.6 and CartoMapperDB.global.fogB == 1.0 then
            CartoMapperDB.global.fogColorStyle = 1
            CartoMapperDB.global.fogTransparency = 0.7
        end
    end

    CartoMapperDB.v = 2

    -- Fill in missing global defaults
    for k, v in pairs(defaultsRegistry) do
        if CartoMapperDB.global[k] == nil then
            CartoMapperDB.global[k] = v
        end
    end
end

-- Check if character overrides are active
function DB.IsCharActive()
    local key = GetCharKey()
    return not not CartoMapperDB.charActive[key]
end

-- Toggle character overrides active status
function DB.SetCharActive(active)
    local key = GetCharKey()
    if active then
        CartoMapperDB.charActive[key] = true
        -- Copy current global values into character DB as a starting point if empty
        if not CartoMapperDB.char[key] then
            CartoMapperDB.char[key] = {}
        end
        for k, v in pairs(CartoMapperDB.global) do
            if CartoMapperDB.char[key][k] == nil then
                CartoMapperDB.char[key][k] = v
            end
        end
    else
        CartoMapperDB.charActive[key] = nil
        -- Optional: clean up character table
        CartoMapperDB.char[key] = nil
    end
end

-- Get option value (checks character active overrides first)
function DB.GetOpt(key)
    local cKey = GetCharKey()
    if CartoMapperDB.charActive and CartoMapperDB.charActive[cKey] and CartoMapperDB.char and CartoMapperDB.char[cKey] and CartoMapperDB.char[cKey][key] ~= nil then
        return CartoMapperDB.char[cKey][key]
    end
    if CartoMapperDB.global and CartoMapperDB.global[key] ~= nil then
        return CartoMapperDB.global[key]
    end
    return defaultsRegistry[key]
end

-- Set option value
function DB.SetOpt(key, value)
    local cKey = GetCharKey()
    if CartoMapperDB.charActive and CartoMapperDB.charActive[cKey] then
        CartoMapperDB.char[cKey] = CartoMapperDB.char[cKey] or {}
        CartoMapperDB.char[cKey][key] = value
    else
        CartoMapperDB.global = CartoMapperDB.global or {}
        CartoMapperDB.global[key] = value
    end
end

-- Reset current profile settings to defaults
function DB.Reset()
    local cKey = GetCharKey()
    if CartoMapperDB.charActive and CartoMapperDB.charActive[cKey] then
        CartoMapperDB.char[cKey] = {}
        for k, v in pairs(defaultsRegistry) do
            CartoMapperDB.char[cKey][k] = v
        end
    else
        CartoMapperDB.global = {}
        for k, v in pairs(defaultsRegistry) do
            CartoMapperDB.global[k] = v
        end
    end
end
