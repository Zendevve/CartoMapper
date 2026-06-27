--[[--------------------------------------------------------------------------------------------
CartoMapper.lua
Core initialization, loader, and minimap button.
--------------------------------------------------------------------------------------------]]--

CartoMapper = CartoMapper or CreateFrame("Frame")
CartoMapper:RegisterEvent("ADDON_LOADED")

-- Global tables for sub-modules to register their logic
CartoMapper.modules = {}

local coreDefaults = {
    zoom = true,
    coords = true,
    battleMap = true,
    groupIcons = true,
    fogClear = true,
    pois = true,
    borderless = false,
    clickThrough = false,
    followPlayer = true,
    minimapButton = true,
    minimapPos = 225,
    zoneLevels = true,
    rememberZoom = true,
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
    NoFadeCursor = false,
    hideTownCityIcons = false,
    playerArrowSize = 16,
    groupIconSize = 16,
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffb0[CartoMapper]|r: " .. msg)
end
CartoMapper.Print = Print

-- Forward declarations
local CreateMinimapButton, UpdateMinimapButtonPosition

StaticPopupDialogs["CARTOMAPPER_DONATE"] = {
    text = "Like CartoMapper? Press Ctrl+C to copy the donation link and support development!",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 260,
    OnShow = function(self)
        local editBox = _G[self:GetName().."EditBox"]
        editBox:SetText("https://www.buymeacoffee.com/zendevve")
        editBox:SetFocus()
        editBox:HighlightText()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function CartoMapper:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == "CartoMapper" then
        -- Register defaults for core
        CartoMapper.DB.RegisterDefaults(coreDefaults)

        -- Register defaults for all modules that loaded before this
        for name, module in pairs(CartoMapper.modules) do
            if module.defaults then
                CartoMapper.DB.RegisterDefaults(module.defaults)
            end
        end

        -- Initialize Database (migration + default filling)
        CartoMapper.DB.Initialize()

        -- Enable all modules that are set to true.
        -- Some modules (Zoom, ZoneInfo) install hooks/scaffolding that must always be
        -- present even when their *user-facing* toggle is off, because the individual
        -- features they expose are gated internally via DB.GetOpt at point of use rather
        -- than by the module being enabled/disabled wholesale. Those modules opt in via
        -- module.alwaysEnable instead of relying on a same-named DB option (which may not
        -- exist, as was the case for ZoneInfo).
        for name, module in pairs(CartoMapper.modules) do
            if module.alwaysEnable or CartoMapper.DB.GetOpt(name) == true then
                if module.Enable then
                    module.Enable()
                end
            end
        end

        -- Create settings frame & minimap button
        if CartoMapper.CreateConfigFrame then
            CartoMapper.CreateConfigFrame()
        end
        CreateMinimapButton()

        Print("Loaded! Click the minimap button or type /cm to open options.")
        Print("Like this addon? Support development at |cffffd700buymeacoffee.com/zendevve|r")
    end
end

CartoMapper:SetScript("OnEvent", CartoMapper.OnEvent)

-- Toggle module dynamically based on options click
function CartoMapper.SetModuleState(name, enable)
    local module = CartoMapper.modules[name]
    if not module then return end
    
    if enable then
        if module.Enable then module.Enable() end
    else
        if module.Disable then module.Disable() end
    end
end

-- Minimap Button creation
local minimapBtn
function CreateMinimapButton()
    if minimapBtn then return end

    minimapBtn = CreateFrame("Button", "CartoMapperMinimapButton", Minimap)
    minimapBtn:SetSize(32, 32)
    minimapBtn:SetFrameStrata("MEDIUM")
    minimapBtn:SetFrameLevel(8)
    minimapBtn:SetClampedToScreen(true)

    local bg = minimapBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = minimapBtn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map02")

    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    minimapBtn:RegisterForDrag("LeftButton")
    minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    minimapBtn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local pos = math.deg(math.atan2(py - my, px - mx)) % 360
            CartoMapper.DB.SetOpt("minimapPos", pos)
            UpdateMinimapButtonPosition()
        end)
    end)

    minimapBtn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)

    minimapBtn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            StaticPopup_Show("CARTOMAPPER_DONATE")
        else
            if CartoMapperConfigFrame then
                if CartoMapperConfigFrame:IsShown() then
                    CartoMapperConfigFrame:Hide()
                else
                    CartoMapperConfigFrame:Show()
                    CartoMapperConfigFrame:UpdateAllValues()
                end
            end
        end
    end)

    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("CartoMapper", 0, 1, 0.8)
        GameTooltip:AddLine("Left-Click to open options panel.", 1, 1, 1)
        GameTooltip:AddLine("Right-Click to copy support link. ☕", 1, 0.8, 0)
        GameTooltip:AddLine("Drag to move button around minimap.", 1, 1, 1)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdateMinimapButtonPosition()
    if CartoMapper.DB.GetOpt("minimapButton") then
        minimapBtn:Show()
    else
        minimapBtn:Hide()
    end
end

function UpdateMinimapButtonPosition()
    if not CartoMapperMinimapButton then return end
    local angle = math.rad(CartoMapper.DB.GetOpt("minimapPos") or 225)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    CartoMapperMinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function CartoMapper.UpdateMinimapButtonVisibility()
    if not CartoMapperMinimapButton then return end
    if CartoMapper.DB.GetOpt("minimapButton") then
        CartoMapperMinimapButton:Show()
    else
        CartoMapperMinimapButton:Hide()
    end
end

-- Slash Command Handler
local function SlashHandler(msg)
    local cmd, arg = string.split(" ", string.lower(msg or ""))
    cmd = cmd or ""
    
    if cmd == "toggle" and arg then
        local targetKey = nil
        for k in pairs(coreDefaults) do
            if string.lower(k) == arg then
                targetKey = k
                break
            end
        end
        -- check modules defaults too
        if not targetKey then
            for name, m in pairs(CartoMapper.modules) do
                if m.defaults then
                    for k in pairs(m.defaults) do
                        if string.lower(k) == arg then
                            targetKey = k
                            break
                        end
                    end
                end
                if targetKey then break end
            end
        end
        
        if targetKey then
            local currentVal = CartoMapper.DB.GetOpt(targetKey)
            CartoMapper.DB.SetOpt(targetKey, not currentVal)
            
            if CartoMapperConfigFrame and CartoMapperConfigFrame:IsShown() then
                CartoMapperConfigFrame:UpdateAllValues()
            end
            
            -- Apply toggle live if stateless/liveToggle
            local modName = targetKey
            if CartoMapper.modules[modName] then
                CartoMapper.SetModuleState(modName, not currentVal)
            elseif modName == "minimapButton" then
                CartoMapper.UpdateMinimapButtonVisibility()
            end
            
            Print(targetKey .. " is now " .. (CartoMapper.DB.GetOpt(targetKey) and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r") .. ".")
        else
            Print("Unknown toggle option: " .. arg)
        end
    elseif cmd == "status" then
        Print("Current Settings:")
        for k, v in pairs(coreDefaults) do
            if type(v) == "boolean" then
                DEFAULT_CHAT_FRAME:AddMessage("  " .. k .. ": " .. (CartoMapper.DB.GetOpt(k) and "|cff00ff00On|r" or "|cffff0000Off|r"))
            end
        end
    else
        if CartoMapperConfigFrame then
            if CartoMapperConfigFrame:IsShown() then
                CartoMapperConfigFrame:Hide()
            else
                CartoMapperConfigFrame:Show()
                CartoMapperConfigFrame:UpdateAllValues()
            end
        end
    end
end

SLASH_CARTOMAPPER1 = "/cartomapper"
SLASH_CARTOMAPPER2 = "/cm"
SlashCmdList["CARTOMAPPER"] = SlashHandler
