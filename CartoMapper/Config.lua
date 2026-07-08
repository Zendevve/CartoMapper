--[[--------------------------------------------------------------------------------------------
Config.lua
Unified options panel GUI. Drag-to-pan, zero-dependency tabs, and custom widgets.
--------------------------------------------------------------------------------------------]]--

local DB = CartoMapper.DB

local configFrame
local tabs = {}
local activeTab = 1
local reloadNeeded = false

-- Color presets
local COLOR_CYAN = {0, 1, 0.9}
local COLOR_GREY = {0.6, 0.6, 0.6}
local COLOR_WHITE = {1, 1, 1}

-- Helper to track changed options needing reload
local initialValues = {}

function CartoMapper.CreateConfigFrame()
    if configFrame then return end

    configFrame = CreateFrame("Frame", "CartoMapperConfigFrame", UIParent)
    configFrame:SetSize(520, 480)
    configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
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

    -- Backdrop styling (glassmorphism/sleek dark theme)
    configFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    configFrame:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
    configFrame:SetBackdropBorderColor(0, 0.8, 1, 0.8)

    -- Header Title
    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 18, -12)
    title:SetText("CartoMapper Configuration")
    title:SetTextColor(unpack(COLOR_CYAN))

    -- Close button
    local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -2, -2)

    -- Scoper (Per-Character Settings Checkbox at top)
    local perCharCB = CreateFrame("CheckButton", "CartoMapperConfig_PerChar", configFrame, "OptionsCheckButtonTemplate")
    perCharCB:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -40, -10)
    _G[perCharCB:GetName() .. "Text"]:SetText("Per-Character Settings")
    _G[perCharCB:GetName() .. "Text"]:SetTextColor(1, 0.8, 0)
    perCharCB:SetChecked(DB.IsCharActive())
    perCharCB:SetScript("OnClick", function(self)
        DB.SetCharActive(self:GetChecked())
        configFrame:UpdateAllValues()
        CartoMapper.Print("Settings profile swapped. Reloading modules...")
        -- Re-evaluate module enables
        for name, module in pairs(CartoMapper.modules) do
            if module.liveToggle then
                CartoMapper.SetModuleState(name, DB.GetOpt(name))
            else
                reloadNeeded = true
            end
        end
        if reloadNeeded and configFrame.reloadBtn then
            configFrame.reloadBtn:UnlockHighlight()
            local fs = configFrame.reloadBtn:GetFontString()
            if fs then fs:SetTextColor(1, 0.2, 0.2) end
        end
    end)

    -- Bottom controls (Support, Reset, Reload)
    local supportBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    supportBtn:SetSize(130, 24)
    supportBtn:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 10, 16)
    supportBtn:SetText("Support Addon ☕")
    local supportText = supportBtn:GetFontString()
    if supportText then
        supportText:SetTextColor(1, 0.82, 0)
    end
    supportBtn:SetScript("OnClick", function()
        StaticPopup_Show("CARTOMAPPER_DONATE")
    end)

    local resetBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(130, 24)
    resetBtn:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 150, 16)
    resetBtn:SetText("Reset Defaults")
    resetBtn:SetScript("OnClick", function()
        DB.Reset()
        configFrame:UpdateAllValues()
        -- Re-enable live modules
        for name, module in pairs(CartoMapper.modules) do
            if module.liveToggle then
                CartoMapper.SetModuleState(name, DB.GetOpt(name))
            end
        end
        CartoMapper.Print("All settings reset to defaults.")
    end)

    local reloadBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    reloadBtn:SetSize(130, 24)
    reloadBtn:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -20, 16)
    reloadBtn:SetText("Reload Interface")
    reloadBtn:SetScript("OnClick", ReloadUI)
    configFrame.reloadBtn = reloadBtn

    -- Sidebar background
    local sidebar = CreateFrame("Frame", nil, configFrame)
    sidebar:SetSize(130, 400)
    sidebar:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -45)
    sidebar:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    sidebar:SetBackdropColor(0, 0, 0, 0.5)
    sidebar:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)

    -- Main Content Area (ScrollFrame for overflow)
    local contentArea = CreateFrame("ScrollFrame", nil, configFrame)
    contentArea:SetSize(350, 360)
    contentArea:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 150, -45)

    local scrollChild = CreateFrame("Frame", nil, contentArea)
    scrollChild:SetSize(350, 800)
    contentArea:SetScrollChild(scrollChild)

    contentArea:EnableMouseWheel(true)
    contentArea:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(0, scrollChild:GetHeight() - self:GetHeight())
        local newScroll = math.max(0, math.min(self:GetVerticalScroll() - delta * 20, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

    -- List of tabs
    local tabNames = { "General", "Map Window", "Zoom / Pan", "Fog Clear", "POIs", "Battlefield", "Group Icons" }
    local tabPanels = {}

    -- Function to switch tabs
    local function SelectTab(index)
        activeTab = index
        contentArea:SetVerticalScroll(0)
        for i, panel in ipairs(tabPanels) do
            if i == index then
                panel:Show()
                tabs[i]:LockHighlight()
                tabs[i].t:SetTextColor(unpack(COLOR_CYAN))
            else
                panel:Hide()
                tabs[i]:UnlockHighlight()
                tabs[i].t:SetTextColor(unpack(COLOR_GREY))
            end
        end
    end

    -- Create tab buttons in Sidebar
    for i, name in ipairs(tabNames) do
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(120, 32)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 5, -5 - (i - 1) * 36)
        btn:SetNormalTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        btn:GetNormalTexture():SetAlpha(0.2)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        btn:GetHighlightTexture():SetAlpha(0.4)

        local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("LEFT", btn, "LEFT", 8, 0)
        t:SetText(name)
        t:SetTextColor(unpack(COLOR_GREY))
        btn.t = t

        btn:SetScript("OnClick", function()
            SelectTab(i)
        end)
        tabs[i] = btn

        -- Panel for this tab
        local panel = CreateFrame("Frame", nil, scrollChild)
        panel:SetAllPoints()
        panel:Hide()
        tabPanels[i] = panel
    end

    -- Track config values
    local checkButtons = {}
    local sliders = {}
    local editBoxes = {}

    -- Widget factories
    local function CreateCheckbox(panel, label, key, desc, x, y, reloadRequired)
        local cb = CreateFrame("CheckButton", "CartoMapperOpt_" .. key, panel, "OptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
        
        local labelText = label .. (reloadRequired and " *" or "")
        _G[cb:GetName() .. "Text"]:SetText(labelText)
        _G[cb:GetName() .. "Text"]:SetTextColor(unpack(COLOR_WHITE))
        _G[cb:GetName() .. "Text"]:SetFontObject("GameFontNormal")

        cb:SetScript("OnClick", function(self)
            local val = self:GetChecked() and true or false
            DB.SetOpt(key, val)
            
            -- Dynamic live toggles
            local module = CartoMapper.modules[key]
            if module and module.liveToggle then
                CartoMapper.SetModuleState(key, val)
            elseif key == "minimapButton" then
                CartoMapper.UpdateMinimapButtonVisibility()
            end

            -- Update reload required check
            if reloadRequired then
                if val ~= initialValues[key] then
                    reloadNeeded = true
                    reloadBtn:LockHighlight()
                    local fs = reloadBtn:GetFontString()
                    if fs then fs:SetTextColor(1, 0.2, 0.2) end
                end
            end
        end)

        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 0, 1, 0.8)
            GameTooltip:AddLine(desc, 1, 1, 1, true)
            if reloadRequired then
                GameTooltip:AddLine("\n* Requires Reload UI to apply.", 1, 0.3, 0.3, true)
            end
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)

        cb.UpdateValue = function()
            local current = DB.GetOpt(key)
            cb:SetChecked(current)
            if initialValues[key] == nil then
                initialValues[key] = current
            end
        end

        table.insert(checkButtons, cb)
        return cb
    end

    local function CreateSlider(panel, label, key, minVal, maxVal, stepVal, fmt, desc, x, y, reloadRequired)
        local s = CreateFrame("Slider", "CartoMapperSlider_" .. key, panel, "OptionsSliderTemplate")
        s:SetMinMaxValues(minVal, maxVal)
        s:SetValueStep(stepVal)
        s:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
        s:SetWidth(150)

        _G[s:GetName() .. "Text"]:SetText(label .. (reloadRequired and " *" or ""))
        _G[s:GetName() .. "Text"]:SetTextColor(unpack(COLOR_CYAN))
        _G[s:GetName() .. "Low"]:SetText(tostring(minVal))
        _G[s:GetName() .. "High"]:SetText(tostring(maxVal))

        local valText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valText:SetPoint("TOP", s, "BOTTOM", 0, -2)

        s:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value / stepVal + 0.5) * stepVal
            DB.SetOpt(key, value)
            valText:SetText(string.format(fmt, value))
            
            -- Live updates
            if key == "stationaryOpacity" or key == "movingOpacity" then
                if CartoMapper.UpdateMapOpacity then CartoMapper.UpdateMapOpacity() end
            elseif key == "fogTransparency" then
                if CartoMapper.UpdateFogClearSettings then CartoMapper.UpdateFogClearSettings() end
            elseif key == "mapScale" then
                if WorldMapFrame then
                    local clamped = value
                    if CartoMapper.ClampMapScale then
                        clamped = CartoMapper.ClampMapScale(value)
                    end
                    WorldMapFrame:SetScale(clamped)
                    if CartoMapper.UpdateElementScales then CartoMapper.UpdateElementScales() end
                end
            elseif key == "playerArrowSize" or key == "groupIconSize" then
                if CartoMapper.UpdateZoom then CartoMapper.UpdateZoom() end
            end
        end)

        s:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 0, 1, 0.8)
            GameTooltip:AddLine(desc, 1, 1, 1, true)
            if reloadRequired then
                GameTooltip:AddLine("\n* Requires Reload UI to apply.", 1, 0.3, 0.3, true)
            end
            GameTooltip:Show()
        end)
        s:SetScript("OnLeave", function() GameTooltip:Hide() end)

        s.UpdateValue = function()
            local current = DB.GetOpt(key)
            s:SetValue(current or minVal)
            valText:SetText(string.format(fmt, current or minVal))
            if initialValues[key] == nil then
                initialValues[key] = current
            end
        end

        table.insert(sliders, s)
        return s
    end

    local function CreateEditBox(panel, label, key, desc, x, y, width)
        local container = CreateFrame("Frame", nil, panel)
        container:SetSize(width or 200, 45)
        container:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)

        local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        title:SetText(label)
        title:SetTextColor(unpack(COLOR_CYAN))

        local eb = CreateFrame("EditBox", "CartoMapperOpt_" .. key, container, "InputBoxTemplate")
        eb:SetSize(width or 200, 20)
        eb:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -15)
        eb:SetAutoFocus(false)
        eb:SetFontObject("ChatFontNormal")
        eb:SetTextColor(1, 1, 1)

        -- Handle editing and saving
        eb:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            DB.SetOpt(key, self:GetText())
        end)
        eb:SetScript("OnEditFocusLost", function(self)
            DB.SetOpt(key, self:GetText())
        end)
        eb:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            self:SetText(DB.GetOpt(key) or "")
        end)

        eb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 0, 1, 0.8)
            GameTooltip:AddLine(desc, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        eb:SetScript("OnLeave", function() GameTooltip:Hide() end)

        eb.UpdateValue = function()
            local current = DB.GetOpt(key) or ""
            eb:SetText(current)
            if initialValues[key] == nil then
                initialValues[key] = current
            end
        end

        table.insert(editBoxes, eb)
        return container
    end

    -- Tab 1: General Options
    local panelGen = tabPanels[1]
    CreateCheckbox(panelGen, "Minimap Button", "minimapButton", "Show the circular minimap shortcut button.", 15, -15, false)
    CreateCheckbox(panelGen, "Remember Zoom Level", "rememberZoom", "Maintains zoom level and map offsets when closing/reopening the map.", 15, -45, false)
    CreateCheckbox(panelGen, "Show Zone & Fishing Levels", "zoneLevels", "Shows recommended levels and fishing skill required on map Continent tooltips.", 15, -75, false)
    CreateCheckbox(panelGen, "Auto-Change Zone on Move", "autoChangeZones", "Automatically updates the map to your current zone when moving.", 15, -105, false)
    CreateCheckbox(panelGen, "Browse Instance Maps", "instanceMaps", "Allows viewing instance and battleground maps from the world map continent/zone menus.", 15, -135, true)
    CreateCheckbox(panelGen, "Show Coordinates", "coords", "Show cursor and player coordinates at the bottom of the map.", 15, -165, false)
    CreateCheckbox(panelGen, "Show Player Speed & ETA", "coordsSpeed", "Append running speed (yd/s) to coordinates, plus ETA when a waypoint is active.", 15, -195, false)
    CreateSlider(panelGen, "Coordinates Accuracy", "coordsAccuracy", 0, 2, 1, "%.0f", "Sets the number of decimal places for map coordinates.", 15, -225, false)

    CreateCheckbox(panelGen, "Enable Waypoints System", "waypoints", "Enables Ctrl+Left Click to set waypoints and displays an on-screen navigation arrow.", 15, -285, false)
    CreateCheckbox(panelGen, "Show Time-to-Arrival (ETA)", "waypointsShowETA", "Shows the estimated travel time next to the distance display on the navigation arrow.", 15, -315, false)
    CreateCheckbox(panelGen, "Auto-Track Corpse on Death", "corpseTracker", "Automatically drops a waypoint on your corpse upon death.", 15, -345, false)
    CreateCheckbox(panelGen, "Play Sound on Arrival", "arrivalSound", "Plays a chime sound when reaching a waypoint.", 15, -375, false)

    CreateEditBox(panelGen, "Arrival Sound Path (Final Destination)", "finalArrivalSoundPath", "Sound file path to play when reaching your final destination.", 15, -405, 320)
    CreateEditBox(panelGen, "Arrival Sound Path (Intermediate Gate)", "gateArrivalSoundPath", "Sound file path to play when reaching an intermediate portal or gate.", 15, -455, 320)

    CreateSlider(panelGen, "Arrival Distance (yards)", "waypointsArrivalDist", 5, 150, 1, "%.0f", "Distance in yards at which a waypoint is considered reached and auto-cleared. Ignored while on a taxi.", 15, -515, false)
    CreateSlider(panelGen, "Arrow Scale", "waypointsArrowScale", 0.3, 3.0, 0.1, "%.1f", "Scale of the on-screen navigation arrow HUD.", 15, -575, false)
    CreateSlider(panelGen, "Arrow Opacity", "waypointsArrowAlpha", 0.1, 1.0, 0.05, "%.2f", "Opacity of the on-screen navigation arrow HUD.", 15, -635, false)

    local clearWpBtn = CreateFrame("Button", "CartoMapperClearWaypointsButton", panelGen, "UIPanelButtonTemplate")
    clearWpBtn:SetSize(160, 22)
    clearWpBtn:SetPoint("TOPLEFT", panelGen, "TOPLEFT", 15, -695)
    clearWpBtn:SetText("Clear All Waypoints")
    clearWpBtn:SetScript("OnClick", function()
        if CartoMapper.modules["waypoints"] and CartoMapper.modules["waypoints"].ClearAll then
            CartoMapper.modules["waypoints"].ClearAll()
        end
    end)

    -- Tab 2: Map Window
    local panelWin = tabPanels[2]
    CreateCheckbox(panelWin, "Borderless Windowed Map", "borderless", "Hides borders and bulky backdrop frames from the windowed map.", 15, -15, true)
    CreateCheckbox(panelWin, "Click-Through Map", "clickThrough", "Makes the map click-through so you can move and steer your character. Hold Alt key to temporarily interact with the map.", 15, -45, false)
    CreateCheckbox(panelWin, "No Fade On Cursor Hover", "NoFadeCursor", "Suspends movement fading when hovering your cursor over the map.", 15, -75, false)
    CreateCheckbox(panelWin, "Hide Town & City Icons", "hideTownCityIcons", "Hides default Blizzard city/town icons on the continent maps.", 15, -105, true)
    CreateCheckbox(panelWin, "Lock Map Position", "lockMap", "Prevents dragging and moving the windowed map frame.", 15, -135, false)
    
    CreateSlider(panelWin, "Map Window Scale", "mapScale", 0.5, 4.0, 0.05, "%.2f", "Adjusts the overall scale/size of the windowed map frame. Also adjustable via Ctrl + Scroll on the map itself.", 15, -165, false)
    CreateSlider(panelWin, "Stationary Opacity", "stationaryOpacity", 0.1, 1.0, 0.05, "%.2f", "Opacity of the map when standing still.", 15, -225, false)
    CreateSlider(panelWin, "Moving Opacity", "movingOpacity", 0.1, 1.0, 0.05, "%.2f", "Opacity of the map when character is running.", 180, -225, false)

    -- Tab 3: Zoom / Pan
    local panelZoom = tabPanels[3]
    CreateCheckbox(panelZoom, "Scroll-to-Zoom", "zoom", "Enables zooming map in/out with the mouse wheel.", 15, -15, false)
    CreateCheckbox(panelZoom, "Center Map on Player", "followPlayer", "Automatically pans map to keep player arrow in view.", 15, -45, false)
    CreateSlider(panelZoom, "Maximum Zoom Scale", "maxZoom", 1.0, 10.0, 0.5, "%.1fx", "Sets the maximum zoom factor allowed on Scroll Zoom.", 15, -105, false)
    CreateSlider(panelZoom, "Zoom Speed", "zoomStep", 0.01, 0.5, 0.01, "%.2f", "Sets the speed/step size of scroll zooming on the world map.", 180, -105, false)
    CreateSlider(panelZoom, "Player Arrow Scale", "playerArrowSize", 12, 36, 2, "%.0f px", "Sets the size of the player arrow on the main map.", 15, -165, false)
    CreateSlider(panelZoom, "Group Icons Scale", "groupIconSize", 12, 36, 2, "%.0f px", "Sets the size of the party/raid member icons on the main map.", 180, -165, false)

    -- Tab 4: Fog Clear
    local panelFog = tabPanels[4]
    CreateCheckbox(panelFog, "Clear Fog of War", "fogClear", "Reveals unexplored zones as transparent overlays on the map.", 15, -15, true)
    
    local styleLabel = panelFog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    styleLabel:SetPoint("TOPLEFT", panelFog, "TOPLEFT", 15, -55)
    styleLabel:SetText("Fog Tint Style:")
    styleLabel:SetTextColor(unpack(COLOR_CYAN))

    local styleNormal = CreateFrame("CheckButton", "CartoMapperFogStyle_Normal", panelFog, "UIRadioButtonTemplate")
    styleNormal:SetPoint("TOPLEFT", panelFog, "TOPLEFT", 15, -75)
    _G[styleNormal:GetName() .. "Text"]:SetText("Normal (Overlay Grid)")
    _G[styleNormal:GetName() .. "Text"]:SetTextColor(unpack(COLOR_WHITE))
    
    local styleCustom = CreateFrame("CheckButton", "CartoMapperFogStyle_Custom", panelFog, "UIRadioButtonTemplate")
    styleCustom:SetPoint("TOPLEFT", panelFog, "TOPLEFT", 15, -100)
    _G[styleCustom:GetName() .. "Text"]:SetText("Custom Colored Tint")
    _G[styleCustom:GetName() .. "Text"]:SetTextColor(unpack(COLOR_WHITE))

    local function UpdateRadioStyles()
        local style = DB.GetOpt("fogColorStyle")
        styleNormal:SetChecked(style == 1)
        styleCustom:SetChecked(style == 2)
    end

    styleNormal:SetScript("OnClick", function()
        DB.SetOpt("fogColorStyle", 1)
        UpdateRadioStyles()
        if CartoMapper.UpdateFogClearSettings then CartoMapper.UpdateFogClearSettings() end
    end)

    styleCustom:SetScript("OnClick", function()
        DB.SetOpt("fogColorStyle", 2)
        UpdateRadioStyles()
        if CartoMapper.UpdateFogClearSettings then CartoMapper.UpdateFogClearSettings() end
    end)

    CreateSlider(panelFog, "Fog Transparency", "fogTransparency", 0.1, 1.0, 0.05, "%.2f", "Transparency of uncovered/unexplored overlays.", 15, -165, false)

    -- Custom Fog Color Button
    local colorBtn = CreateFrame("Button", "CartoMapperFogColorButton", panelFog, "UIPanelButtonTemplate")
    colorBtn:SetSize(160, 22)
    colorBtn:SetPoint("TOPLEFT", panelFog, "TOPLEFT", 15, -215)
    colorBtn:SetText("Choose Custom Color")
    colorBtn:SetScript("OnClick", function()
        if CartoMapper.OpenFogColorPicker then
            CartoMapper.OpenFogColorPicker()
        end
    end)

    -- Tab 5: Points of Interest
    local panelPOIs = tabPanels[5]
    CreateCheckbox(panelPOIs, "Enable Points of Interest", "pois", "Draws flight paths, dungeons, spirit healers, and zone crossings.", 15, -15, false)
    CreateCheckbox(panelPOIs, "Extended Flight Masters", "flightMasters", "Adds flight master pins for Northrend and other zones not pre-seeded.", 15, -45, true)
    CreateCheckbox(panelPOIs, "Extended Transport Routes", "transportRoutes", "Adds Northrend boat, zeppelin, and portal pickup-point pins.", 15, -75, true)

    local subLabel = panelPOIs:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subLabel:SetPoint("TOPLEFT", panelPOIs, "TOPLEFT", 15, -115)
    subLabel:SetText("Granular Filters:")
    subLabel:SetTextColor(unpack(COLOR_CYAN))

    -- Add granular sub-options registry
    -- (defaults now registered by POIs.lua itself via POIs.defaults - see that file)

    CreateCheckbox(panelPOIs, "Dungeons & Raids", "ShowDungeonIcons", "Draw dungeon and raid instance portal icons.", 25, -135, false)
    CreateCheckbox(panelPOIs, "Same-Faction Flight Paths", "ShowTravelPoints", "Show flight masters, boats, and zeppelins of your faction.", 25, -165, false)
    CreateCheckbox(panelPOIs, "Opposing-Faction Flight Paths", "ShowTravelOpposing", "Show flight masters of the enemy faction.", 25, -195, false)
    CreateCheckbox(panelPOIs, "Spirit Healers", "ShowSpiritHealers", "Draw spirit healers on the map.", 25, -225, false)
    CreateCheckbox(panelPOIs, "Zone Crossings", "ShowZoneCrossings", "Draw clickable arrows at zone transitions to jump map.", 25, -255, false)

    -- Tab 6: Battlefield Minimap
    local panelBattle = tabPanels[6]
    CreateCheckbox(panelBattle, "Enable battlefield map", "battleMap", "Enhance Shift+M map frame options and visibility.", 15, -15, false)
    
    -- Sub settings
    -- (defaults now registered by BattleMap.lua itself via BattleMap.defaults - see that file)

    CreateCheckbox(panelBattle, "Unlock Battlefield Map", "unlockBattlefield", "Allows dragging and resizing the battlefield map frame.", 15, -55, false)
    CreateCheckbox(panelBattle, "Center Map on Player", "battleCenterOnPlayer", "Keeps battlefield map focused on player arrow.", 15, -85, false)

    CreateSlider(panelBattle, "Group Icons Scale", "battleGroupIconSize", 6, 24, 1, "%.0f", "Size in pixels of group member icons on battlefield map.", 15, -135, false)
    CreateSlider(panelBattle, "Player Arrow Scale", "battlePlayerArrowSize", 6, 24, 1, "%.0f", "Size in pixels of player arrow on battlefield map.", 180, -135, false)

    CreateSlider(panelBattle, "Battlefield Size", "battleMapSize", 150, 1200, 25, "%.0f px", "Width in pixels of the battlefield map.", 15, -195, false)
    CreateSlider(panelBattle, "Battlefield Opacity", "battleMapOpacity", 0.1, 1.0, 0.05, "%.2f", "Alpha opacity of the battlefield map.", 180, -195, false)

    CreateSlider(panelBattle, "Max Zoom Limit", "battleMaxZoom", 1.0, 6.0, 0.5, "%.1fx", "Scale of maximum zoom factor on battlefield scroll.", 15, -255, false)

    -- Tab 7: Group Icons
    local panelGroups = tabPanels[7]
    CreateCheckbox(panelGroups, "Class Colored Group Icons", "groupIcons", "Displays party/raid member icons colored by class, AFK, dead, or combat state.", 15, -15, false)

    -- Global Update function
    configFrame.UpdateAllValues = function()
        perCharCB:SetChecked(DB.IsCharActive())
        UpdateRadioStyles()
        for _, cb in ipairs(checkButtons) do cb:UpdateValue() end
        for _, s in ipairs(sliders) do s:UpdateValue() end
        for _, eb in ipairs(editBoxes) do eb:UpdateValue() end
    end

    -- Initial Select Tab
    SelectTab(1)
    configFrame:Hide()
end
