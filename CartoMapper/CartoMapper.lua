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
}

local callbacks = {
    zoom = function(val)
        if CartoMapper.UpdateZoom then CartoMapper.UpdateZoom() end
    end,
    coords = function(val)
        if CartoMapper.UpdateCoordsVisibility then CartoMapper.UpdateCoordsVisibility() end
    end,
    battleMap = function(val)
        if CartoMapper.UpdateBattleMap then CartoMapper.UpdateBattleMap() end
    end,
    groupIcons = function(val)
        if CartoMapper.UpdateGroupIcons then CartoMapper.UpdateGroupIcons() end
    end,
    fogClear = function(val)
        if CartoMapper.UpdateFogClearSettings then CartoMapper.UpdateFogClearSettings() end
    end,
    pois = function(val)
        if CartoMapper.UpdatePOIs then CartoMapper.UpdatePOIs() end
    end,
    borderless = function(val)
        if CartoMapper.UpdateBorderless then CartoMapper.UpdateBorderless() end
    end,
    clickThrough = function(val)
        if CartoMapper.UpdateClickThrough then CartoMapper.UpdateClickThrough() end
    end,
    minimapButton = function(val)
        if CartoMapperMinimapButton then
            if val then CartoMapperMinimapButton:Show() else CartoMapperMinimapButton:Hide() end
        end
    end,
    zoneLevels = function(val)
        if WorldMapFrame and WorldMapFrame:IsShown() then
            WorldMapFrame_Update()
        end
    end,
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffb0[CartoMapper]|r: " .. msg)
end

-- Forward declarations
local CreateConfigFrame, CreateMinimapButton, UpdateMinimapButtonPosition

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
            if CartoMapperDB[name] or name == "zoom" then
                if module.Enable then
                    module.Enable()
                end
            end
        end

        CreateConfigFrame()
        CreateMinimapButton()

        Print("Loaded! Click the minimap button or type /cm to open options.")
    end
end

CartoMapper:SetScript("OnEvent", CartoMapper.OnEvent)

-- Config Frame creation logic
local configFrame
function CreateConfigFrame()
    if configFrame then return end

    configFrame = CreateFrame("Frame", "CartoMapperConfigFrame", UIParent)
    configFrame:SetSize(460, 420)
    configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    configFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    configFrame:SetFrameLevel(20)
    configFrame:SetClampedToScreen(true)
    configFrame:EnableMouse(true)
    configFrame:SetMovable(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    
    -- Setup close on Escape
    _G["CartoMapperConfigFrame"] = configFrame
    table.insert(UISpecialFrames, "CartoMapperConfigFrame")

    -- Backdrop styling (glassmorphism feel)
    configFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    configFrame:SetBackdropColor(0.05, 0.05, 0.07, 0.9)
    configFrame:SetBackdropBorderColor(0, 0.8, 1, 0.8)

    -- Header Title
    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", configFrame, "TOP", 0, -12)
    title:SetText("CartoMapper Configuration")
    title:SetTextColor(0, 1, 0.9)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -2, -2)

    -- Helper to create sub-group containers
    local function CreateBox(parent, boxTitle, x, y, w, h)
        local box = CreateFrame("Frame", nil, parent)
        box:SetSize(w, h)
        box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        box:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        box:SetBackdropColor(0, 0, 0, 0.4)
        box:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
        
        local titleText = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("TOPLEFT", 10, 8)
        titleText:SetText(" " .. boxTitle .. " ")
        titleText:SetTextColor(0, 1, 0.8)
        
        local titleBg = box:CreateTexture(nil, "BACKGROUND")
        titleBg:SetPoint("TOPLEFT", titleText, "TOPLEFT", -4, 2)
        titleBg:SetPoint("BOTTOMRIGHT", titleText, "BOTTOMRIGHT", 4, -2)
        titleBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        titleBg:SetVertexColor(0.05, 0.05, 0.07, 1)
        
        return box
    end

    -- Group boxes
    local modulesBox = CreateBox(configFrame, "Modules & Features", 15, -40, 430, 180)
    local settingsBox = CreateBox(configFrame, "Settings & Sliders", 15, -235, 430, 120)

    -- Checkboxes container
    local cbs = {}
    local function AddCheckbox(parent, label, key, description, col, row, callback)
        local cb = CreateFrame("CheckButton", "CartoMapperCB_" .. key, parent, "OptionsCheckButtonTemplate")
        cb:SetChecked(CartoMapperDB[key])
        
        local startX = (col == 1) and 15 or 220
        local startY = -15 - (row - 1) * 26
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", startX, startY)
        
        local text = _G[cb:GetName() .. "Text"]
        text:SetText(label)
        text:SetTextColor(1, 1, 1)
        text:SetFontObject("GameFontNormal")
        
        cb:SetScript("OnClick", function(self)
            local val = self:GetChecked() and true or false
            CartoMapperDB[key] = val
            if callback then callback(val) end
        end)
        
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 0, 1, 0.8)
            GameTooltip:AddLine(description, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        cb.UpdateValue = function()
            cb:SetChecked(CartoMapperDB[key])
        end
        table.insert(cbs, cb)
        return cb
    end

    -- Add checkboxes to modulesBox
    AddCheckbox(modulesBox, "Zoom & Pan", "zoom", "Enables scroll-to-zoom and drag-to-pan on World Map.", 1, 1, callbacks.zoom)
    AddCheckbox(modulesBox, "Coordinates", "coords", "Displays cursor and player coordinates on map bottom.", 1, 2, callbacks.coords)
    AddCheckbox(modulesBox, "Battlefield Minimap", "battleMap", "Enhances Battlefield Minimap (Shift+M) to look clean.", 1, 3, callbacks.battleMap)
    AddCheckbox(modulesBox, "Group & Raid Icons", "groupIcons", "Enables class-colored group and raid icons on map.", 1, 4, callbacks.groupIcons)
    AddCheckbox(modulesBox, "Clear Fog of War", "fogClear", "Reveals unexplored map overlays with custom opacity/tints.", 1, 5, callbacks.fogClear)
    AddCheckbox(modulesBox, "Points of Interest", "pois", "Shows dungeons and flight paths on World Map.", 1, 6, callbacks.pois)

    AddCheckbox(modulesBox, "Borderless Mode", "borderless", "Hides windowed map borders and art frames.", 2, 1, callbacks.borderless)
    AddCheckbox(modulesBox, "Click-Through Map", "clickThrough", "Allows clicking through windowed map when it's open.", 2, 2, callbacks.clickThrough)
    AddCheckbox(modulesBox, "Follow Player", "followPlayer", "Auto-centers map on player when zoomed in.", 2, 3)
    AddCheckbox(modulesBox, "Minimap Button", "minimapButton", "Shows/hides the circular minimap button.", 2, 4, callbacks.minimapButton)
    AddCheckbox(modulesBox, "Remember Zoom", "rememberZoom", "Remembers zoom scale and scroll offset when map is toggled.", 2, 5)
    AddCheckbox(modulesBox, "Zone & Fishing Levels", "zoneLevels", "Shows zone level range and fishing skill on continent hovers.", 2, 6, callbacks.zoneLevels)

    -- Add sliders container
    local sliders = {}
    local function AddSlider(parent, label, key, minVal, maxVal, stepVal, x, y, callback)
        local s = CreateFrame("Slider", "CartoMapperSlider_" .. key, parent, "OptionsSliderTemplate")
        s:SetMinMaxValues(minVal, maxVal)
        s:SetValueStep(stepVal)
        s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        s:SetWidth(180)
        
        local titleText = _G[s:GetName() .. "Text"]
        titleText:SetText(label)
        titleText:SetTextColor(0, 1, 0.8)
        
        local valText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valText:SetPoint("TOP", s, "BOTTOM", 0, -2)
        
        _G[s:GetName() .. "Low"]:SetText(tostring(minVal))
        _G[s:GetName() .. "High"]:SetText(tostring(maxVal))
        
        s:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value / stepVal + 0.5) * stepVal
            CartoMapperDB[key] = value
            valText:SetText(string.format("%.2f", value):gsub("%.?0+$", ""))
            if callback then callback(value) end
        end)
        
        s.UpdateValue = function()
            s:SetValue(CartoMapperDB[key] or minVal)
            valText:SetText(string.format("%.2f", CartoMapperDB[key] or minVal):gsub("%.?0+$", ""))
        end
        table.insert(sliders, s)
        return s
    end

    -- Add sliders inside settingsBox
    AddSlider(settingsBox, "Stationary Opacity", "stationaryOpacity", 0.1, 1.0, 0.05, 20, -30, function(val)
        if CartoMapper.UpdateMapOpacity then CartoMapper.UpdateMapOpacity() end
    end)
    AddSlider(settingsBox, "Moving Opacity", "movingOpacity", 0.1, 1.0, 0.05, 220, -30, function(val)
        if CartoMapper.UpdateMapOpacity then CartoMapper.UpdateMapOpacity() end
    end)
    AddSlider(settingsBox, "Fog Transparency", "fogTransparency", 0.1, 1.0, 0.05, 20, -85, function(val)
        if CartoMapper.UpdateFogClearSettings then CartoMapper.UpdateFogClearSettings() end
    end)

    -- Custom Fog Color Button
    local colorBtn = CreateFrame("Button", nil, settingsBox, "UIPanelButtonTemplate")
    colorBtn:SetSize(180, 24)
    colorBtn:SetPoint("TOPLEFT", settingsBox, "TOPLEFT", 220, -80)
    colorBtn:SetText("Choose Fog Color")
    colorBtn:SetScript("OnClick", function()
        if CartoMapper.OpenFogColorPicker then
            CartoMapper.OpenFogColorPicker()
        else
            Print("Color picker option not loaded yet.")
        end
    end)

    -- Reset layout button
    local resetBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(160, 28)
    resetBtn:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 25, 20)
    resetBtn:SetText("Reset Layout")
    resetBtn:SetScript("OnClick", function()
        CartoMapperDB.mapScale = 1.0
        CartoMapperDB.stationaryOpacity = 1.0
        CartoMapperDB.movingOpacity = 1.0
        CartoMapperDB.minimapPos = 225
        CartoMapperDB.fogR = 0.2
        CartoMapperDB.fogG = 0.6
        CartoMapperDB.fogB = 1.0
        CartoMapperDB.fogColorStyle = 1
        CartoMapperDB.fogTransparency = 0.7
        UpdateMinimapButtonPosition()
        
        -- Reset options UI values
        for _, cb in ipairs(cbs) do cb:UpdateValue() end
        for _, s in ipairs(sliders) do s:UpdateValue() end
        
        -- Reset actual frame positions if map is open
        if WorldMapFrame and WorldMapFrame:IsShown() then
            WorldMapFrame:SetScale(1.0)
            if WorldMapScreenAnchor then
                WorldMapScreenAnchor:ClearAllPoints()
                WorldMapScreenAnchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -104)
            end
        end
        if CartoMapper.UpdateMapOpacity then CartoMapper.UpdateMapOpacity() end
        if CartoMapper.UpdateFogClearSettings then CartoMapper.UpdateFogClearSettings() end
        Print("Layout settings and positions reset.")
    end)

    -- Reload UI button
    local reloadBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    reloadBtn:SetSize(160, 28)
    reloadBtn:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -25, 20)
    reloadBtn:SetText("Reload Interface")
    reloadBtn:SetScript("OnClick", ReloadUI)

    configFrame.UpdateAllValues = function()
        for _, cb in ipairs(cbs) do cb:UpdateValue() end
        for _, s in ipairs(sliders) do s:UpdateValue() end
    end
    
    configFrame:Hide()
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
    minimapBtn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local pos = math.deg(math.atan2(py - my, px - mx)) % 360
            CartoMapperDB.minimapPos = pos
            UpdateMinimapButtonPosition()
        end)
    end)

    minimapBtn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)

    minimapBtn:SetScript("OnClick", function()
        if CartoMapperConfigFrame then
            if CartoMapperConfigFrame:IsShown() then
                CartoMapperConfigFrame:Hide()
            else
                CartoMapperConfigFrame:Show()
                CartoMapperConfigFrame:UpdateAllValues()
            end
        end
    end)

    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("CartoMapper", 0, 1, 0.8)
        GameTooltip:AddLine("Left-Click to open options panel.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move button around minimap.", 1, 1, 1)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdateMinimapButtonPosition()
    if CartoMapperDB.minimapButton then
        minimapBtn:Show()
    else
        minimapBtn:Hide()
    end
end

function UpdateMinimapButtonPosition()
    if not CartoMapperMinimapButton then return end
    local angle = math.rad(CartoMapperDB.minimapPos or 225)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    CartoMapperMinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Slash Command Handler
local function SlashHandler(msg)
    local cmd, arg = string.split(" ", string.lower(msg or ""))
    cmd = cmd or ""
    
    if cmd == "toggle" and arg then
        local targetKey = nil
        for k in pairs(defaults) do
            if string.lower(k) == arg then
                targetKey = k
                break
            end
        end
        
        if targetKey then
            CartoMapperDB[targetKey] = not CartoMapperDB[targetKey]
            
            if CartoMapperConfigFrame and CartoMapperConfigFrame:IsShown() then
                CartoMapperConfigFrame:UpdateAllValues()
            end
            
            if callbacks[targetKey] then
                callbacks[targetKey](CartoMapperDB[targetKey])
                Print(targetKey .. " is now " .. (CartoMapperDB[targetKey] and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r") .. ".")
            else
                Print(targetKey .. " is now " .. (CartoMapperDB[targetKey] and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r") .. ". Please /reload to apply changes.")
            end
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
