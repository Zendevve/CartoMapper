--[[--------------------------------------------------------------------------------------------
POIs.lua
Points of Interest module (Dungeons, Flight paths, Spirit healers, Zone crossings).
--------------------------------------------------------------------------------------------]]--

local POIs = {}
CartoMapper.modules["pois"] = POIs

local POIData = {
    ["Alterac"] = {
        {"Spirit", 42.9, 38.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 80.7, 34.2, "Western Plaguelands", nil, "Arrow", nil, nil, nil, nil, nil, 0, 1422},
			{"Arrow", 51.8, 68.8, "Hillsbrad Foothills", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1424},
			{"Arrow", 81.7, 77.5, "Hillsbrad Foothills", "Ravenholdt Manor", "Arrow", nil, nil, nil, nil, nil, 2.2, 1424},
    },
    ["Arathi"] = {
        {"FlightA", 45.8, 46.1, "Refuge Pointe" .. ", " .. "Arathi Highlands", nil, "FlightA", nil, nil},
			{"FlightH", 73.1, 32.7, "Hammerfall" .. ", " .. "Arathi Highlands", nil, "FlightH", nil, nil},
			{"Spirit", 48.8, 55.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 45.4, 88.9, "Wetlands", "Thandol Span", "Arrow", nil, nil, nil, nil, nil, 3.2, 1437},
			{"Arrow", 20.9, 30.6, "Hillsbrad Foothills", nil, "Arrow", nil, nil, nil, nil, nil, 1, 1424},
			{"Arrow", 29.6, 67.5, "Faldir's Cove", "Just follow the path west", "Arrow", nil, nil, nil, nil, nil, 1.9, 1417},
    },
    ["Badlands"] = {
        {"Dungeon", 44.6, 12.1, "Uldaman", "Dungeon", "Dungeon", 41, 51},
			{"FlightH", 4.0, 44.8, "Kargath" .. ", " .. "Badlands", nil, "FlightH", nil, nil},
			{"Spirit", 56.7, 23.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 8.4, 55.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 56.7, 73.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 51.1, 14.8, "Loch Modan", nil, "Arrow", nil, nil, nil, nil, nil, 0.8, 1432},
			{"Arrow", 5.3, 61.1, "Searing Gorge", nil, "Arrow", nil, nil, nil, nil, nil, 1.5, 1427},
    },
    ["BlastedLands"] = {
        {"FlightA", 65.5, 24.3, "Nethergarde Keep" .. ", " .. "Blasted Lands", nil, "FlightA", nil, nil},
			{"Spirit", 51.1, 12.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 52.2, 10.7, "Swamp of Sorrows", nil, "Arrow", nil, nil, nil, nil, nil, 0, 1435},
    },
    ["Tirisfal"] = {
        {"Dungeon", 82.6, 33.8, "Scarlet Monastery", "Dungeon", "Dungeon", 34, 45},
			{"TravelH", 60.7, 58.8, "Zeppelin to" .. " " .. "Orgrimmar" .. ", " .. "Durotar", nil, "TravelH", nil, nil, nil, nil, nil, 0, 1411},
			{"TravelH", 61.9, 59.1, "Zeppelin to" .. " " .. "Grom'gol Base Camp" .. ", " .. "Stranglethorn Vale", nil, "TravelH", nil, nil, nil, nil, nil, 0, 1434},
			{"Spirit", 30.8, 64.9, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 56.2, 49.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 79.0, 41.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 62.3, 67.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 82.0, 69.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 83.4, 70.6, "Western Plaguelands", "The Bulwark", "Arrow", nil, nil, nil, nil, nil, 4.7, 1422},
			{"Arrow", 61.9, 65.0, "Undercity", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1458},
			{"Arrow", 54.9, 72.7, "Silverpine Forest", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1421},
    },
    ["Silverpine"] = {
        {"Dungeon", 44.8, 67.8, "Shadowfang Keep", "Dungeon", "Dungeon", 22, 30},
			{"FlightH", 45.6, 42.6, "The Sepulcher" .. ", " .. "Silverpine Forest", nil, "FlightH", nil, nil},
			{"Spirit", 44.1, 42.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 55.6, 73.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 66.3, 79.8, "Hillsbrad Foothills", nil, "Arrow", nil, nil, nil, nil, nil, 4.3, 1424},
			{"Arrow", 67.7, 5.0, "Tirisfal Glades", nil, "Arrow", nil, nil, nil, nil, nil, 5.7, 1420},
    },
    ["WesternPlaguelands"] = {
        {"Dungeon", 69.7, 73.2, "Scholomance", "Dungeon", "Dungeon", 58, 60},
			{"FlightA", 42.9, 85.1, "Chillwind Camp" .. ", " .. "Western Plaguelands", nil, "FlightA", nil, nil},
			{"Spirit", 59.7, 53.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 65.8, 74.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 45.0, 86.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 44.1, 87.1, "Alterac Mountains", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1416},
			{"Arrow", 28.6, 57.5, "Tirisfal Glades", "The Bulwark", "Arrow", nil, nil, nil, nil, nil, 1.6, 1420},
			{"Arrow", 69.7, 50.3, "Eastern Plaguelands", nil, "Arrow", nil, nil, nil, nil, nil, 4.7, 1423},
			{"Arrow", 65.3, 86.4, "The Hinterlands", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1425},
    },
    ["EasternPlaguelands"] = {
        {"Dungeon", 31.3, 15.7, "Stratholme (Main Gate)", "Dungeon", "Dungeon", 58, 60}, {"Dungeon", 47.9, 23.9, "Stratholme (Service Gate)", "Dungeon", "Dungeon", 58, 60}, {"Dungeon", 39.9, 25.9, "Naxxramas", "Raid", "Raid", 60, 60},
			{"FlightA", 81.6, 59.3, "Light's Hope Chapel" .. ", " .. "Eastern Plaguelands", nil, "FlightA", nil, nil},
			{"FlightH", 80.2, 57.0, "Light's Hope Chapel" .. ", " .. "Eastern Plaguelands", nil, "FlightH", nil, nil},
			{"Spirit", 47.3, 44.9, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 37.8, 70.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 39.2, 93.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 80.4, 65.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 11.8, 72.7, "Western Plaguelands", nil, "Arrow", nil, nil, nil, nil, nil, 1.6, 1422},
			{"Arrow", 58.7, 17.5, "Ghostlands", nil, "Arrow", nil, nil, nil, nil, nil, 0.4, 1942},
    },
    ["Hillsbrad"] = {
        {"FlightA", 49.3, 52.3, "Southshore" .. ", " .. "Hillsbrad Foothills", nil, "FlightA", nil, nil},
			{"FlightH", 60.1, 18.6, "Tarren Mill" .. ", " .. "Hillsbrad Foothills", nil, "FlightH", nil, nil},
			{"Spirit", 64.5, 19.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 51.8, 52.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 84.6, 31.8, "The Hinterlands", nil, "Arrow", nil, nil, nil, nil, nil, 5.4, 1425},
			{"Arrow", 54.8, 11.3, "Alterac Mountains", nil, "Arrow", nil, nil, nil, nil, nil, 0, 1416},
			{"Arrow", 13.7, 46.2, "Silverpine Forest", nil, "Arrow", nil, nil, nil, nil, nil, 1.5, 1421},
			{"Arrow", 81.0, 56.1, "Arathi Highlands", nil, "Arrow", nil, nil, nil, nil, nil, 4.1, 1417},
			{"Arrow", 75.5, 24.6, "Alterac Mountains", "Ravenholdt Manor", "Arrow", nil, nil, nil, nil, nil, 0.0, 1416},
    },
    ["Hinterlands"] = {
        {"FlightA", 11.1, 46.2, "Aerie Peak" .. ", " .. "The Hinterlands", nil, "FlightA", nil, nil},
			{"FlightH", 81.7, 81.8, "Revantusk Village" .. ", " .. "The Hinterlands", nil, "FlightH", nil, nil},
			{"Spirit", 16.9, 44.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 73.1, 68.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 24.1, 30.4, "Western Plaguelands", nil, "Arrow", nil, nil, nil, nil, nil, 0, 1422},
			{"Arrow", 6.4, 61.5, "Hillsbrad Foothills", nil, "Arrow", nil, nil, nil, nil, nil, 2.3, 1424},
			{"Arrow", 70.6, 63.7, "The Overlook Cliffs", "Follow the westward path", "Arrow", nil, nil, nil, nil, nil, 4.1, 1425},
			{"Arrow", 76.9, 61.0, "The Hinterlands", "Follow the eastward path", "Arrow", nil, nil, nil, nil, nil, 1.8, 1425},
    },
    ["DunMorogh"] = {
        {"Dungeon", 24.3, 39.8, "Gnomeregan", "Dungeon", "Dungeon", 29, 38},
			{"Spirit", 30.0, 69.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 47.3, 54.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 54.4, 39.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 84.3, 31.1, "Loch Modan", "North Gate Pass", "Arrow", nil, nil, nil, nil, nil, 0, 1432},
			{"Arrow", 82.2, 53.5, "Loch Modan", "South Gate Pass", "Arrow", nil, nil, nil, nil, nil, 5, 1432},
			{"Arrow", 30.5, 34.5, "Wetlands", "You will die!", "Arrow", nil, nil, nil, nil, nil, 6.2, 1437},
			{"Arrow", 53.3, 35.1, "Ironforge", nil, "Arrow", nil, nil, nil, nil, nil, 5.4, 1455},
    },
    ["SearingGorge"] = {
        {"Dunraid", 34.8, 85.3, "Blackrock Mountain", "Blackrock Depths" .. ", " .. "Lower Blackrock Spire" .. ", " .. "Upper Blackrock Spire" .. ", |n" .. "Molten Core" .. ", " .. "Blackwing Lair", "Dungeon", 52, 60},
			{"FlightA", 37.9, 30.8, "Thorium Point" .. ", " .. "Searing Gorge", nil, "FlightA", nil, nil},
			{"FlightH", 34.8, 30.9, "Thorium Point" .. ", " .. "Searing Gorge", nil, "FlightH", nil, nil},
			{"Spirit", 35.5, 22.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 54.4, 51.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 78.5, 17.4, "Loch Modan", "Requires Key to Searing Gorge", "Arrow", nil, nil, nil, nil, nil, 5.4, 1432},
			{"Arrow", 33.6, 79.0, "Burning Steppes", "Blackrock Mountain", "Arrow", nil, nil, nil, nil, nil, 3, 1428},
			{"Arrow", 68.8, 53.9, "Badlands", nil, "Arrow", nil, nil, nil, nil, nil, 4.5, 1418},
    },
    ["BurningSteppes"] = {
        {"Dunraid", 29.4, 38.3, "Blackrock Mountain", "Blackrock Depths" .. ", " .. "Lower Blackrock Spire" .. ", " .. "Upper Blackrock Spire" .. ", |n" .. "Molten Core" .. ", " .. "Blackwing Lair", "Dungeon", 52, 60},
			{"FlightA", 84.3, 68.3, "Morgan's Vigil" .. ", " .. "Burning Steppes", nil, "FlightA", nil, nil},
			{"FlightH", 65.7, 24.2, "Flame Crest" .. ", " .. "Burning Steppes", nil, "FlightH", nil, nil},
			{"Spirit", 64.1, 24.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 78.3, 77.8, "Redridge Mountains", nil, "Arrow", nil, nil, nil, nil, nil, 3.3, 1433},
			{"Arrow", 31.9, 50.4, "Searing Gorge", "Blackrock Mountain", "Arrow", nil, nil, nil, nil, nil, 0.8, 1427},
    },
    ["Elwynn"] = {
        {"Spirit", 39.5, 60.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 49.7, 42.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 83.6, 69.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 21.0, 79.6, "Westfall", nil, "Arrow", nil, nil, nil, nil, nil, 2.2, 1436},
			{"Arrow", 93.2, 72.3, "Redridge Mountains", nil, "Arrow", nil, nil, nil, nil, nil, 4.7, 1433},
			{"Arrow", 32.2, 49.7, "Stormwind City", nil, "Arrow", nil, nil, nil, nil, nil, 0.6, 1453},
    },
    ["DeadwindPass"] = {
        {"Spirit", 40.0, 74.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Raid", 46.9, 74.7, "Karazhan", "Raid", "Raid", 70, 70},
			{"Arrow", 32.0, 35.3, "Duskwood", nil, "Arrow", nil, nil, nil, nil, nil, 1.5, 1431},
			{"Arrow", 58.8, 42.2, "Swamp of Sorrows", nil, "Arrow", nil, nil, nil, nil, nil, 5.2, 1435},
    },
    ["Duskwood"] = {
        {"FlightA", 77.5, 44.3, "Darkshire" .. ", " .. "Duskwood", nil, "FlightA", nil, nil},
			{"Spirit", 20.0, 49.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 75.1, 59.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 7.9, 63.8, "Westfall", nil, "Arrow", nil, nil, nil, nil, nil, 1.7, 1436},
			{"Arrow", 44.6, 87.9, "Stranglethorn Vale", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1434},
			{"Arrow", 94.2, 10.3, "Redridge Mountains", nil, "Arrow", nil, nil, nil, nil, nil, 5.8, 1433},
			{"Arrow", 88.4, 40.9, "Deadwind Pass", nil, "Arrow", nil, nil, nil, nil, nil, 4.6, 1430},
    },
    ["LochModan"] = {
        {"FlightA", 33.9, 50.9, "Thelsamar" .. ", " .. "Loch Modan", nil, "FlightA", nil, nil},
			{"Spirit", 32.6, 47.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 18.4, 83.0, "Searing Gorge", "Requires Key to Searing Gorge", "Arrow", nil, nil, nil, nil, nil, 2.6, 1427},
			{"Arrow", 20.4, 17.4, "Dun Morogh", "North Gate Pass", "Arrow", nil, nil, nil, nil, nil, 1.1, 1426},
			{"Arrow", 46.8, 76.9, "Badlands", nil, "Arrow", nil, nil, nil, nil, nil, 3.2, 1418},
			{"Arrow", 21.5, 66.2, "Dun Morogh", "South Gate Pass", "Arrow", nil, nil, nil, nil, nil, 0.5, 1426},
			{"Arrow", 25.4, 10.9, "Wetlands", "Dun Algaz", "Arrow", nil, nil, nil, nil, nil, 0.1, 1437},
    },
    ["Redridge"] = {
        {"FlightA", 30.6, 59.4, "Lake Everstill" .. ", " .. "Redridge Mountains", nil, "FlightA", nil, nil},
			{"Spirit", 20.8, 56.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 8.5, 88.1, "Duskwood", nil, "Arrow", nil, nil, nil, nil, nil, 2.2, 1431},
			{"Arrow", 3.3, 73.1, "Elwynn Forest", nil, "Arrow", nil, nil, nil, nil, nil, 2.1, 1429},
			{"Arrow", 47.3, 14.3, "Burning Steppes", nil, "Arrow", nil, nil, nil, nil, nil, 5.9, 1428},
    },
    ["Stranglethorn"] = {
        {"Raid", 53.9, 17.6, "Zul'Gurub", "Raid", "Raid", 60, 60},
			{"FlightA", 27.5, 77.8, "Booty Bay" .. ", " .. "Stranglethorn Vale", nil, "FlightA", nil, nil},
			{"FlightA", 38.2, 4.0, "Rebel Camp" .. ", " .. "Stranglethorn Vale", nil, "FlightA", nil, nil},
			{"FlightH", 26.9, 77.1, "Booty Bay" .. ", " .. "Stranglethorn Vale", nil, "FlightH", nil, nil},
			{"FlightH", 32.5, 29.4, "Grom'gol Base Camp" .. ", " .. "Stranglethorn Vale", nil, "FlightH", nil, nil},
			{"TravelN", 25.9, 73.1, "Boat to" .. " " .. "Ratchet" .. ", " .. "The Barrens", nil, "TravelN", nil, nil, nil, nil, nil, 0, 1413},
			{"TravelH", 31.4, 30.2, "Zeppelin to" .. " " .. "Orgrimmar" .. ", " .. "Durotar", nil, "TravelH", nil, nil, nil, nil, nil, 0, 1411},
			{"TravelH", 31.6, 29.1, "Zeppelin to" .. " " .. "Undercity" .. ", " .. "Tirisfal Glades", nil, "TravelH", nil, nil, nil, nil, nil, 0, 1420},
			{"Spirit", 38.4, 9.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 30.4, 73.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 39.2, 6.5, "Duskwood", nil, "Arrow", nil, nil, nil, nil, nil, 0, 1431},
    },
    ["SwampOfSorrows"] = {
        {"Dungeon", 69.9, 53.6, "Temple of Atal'Hakkar", "Dungeon", "Dungeon", 50, 60},
			{"FlightH", 46.1, 54.8, "Stonard" .. ", " .. "Swamp of Sorrows", nil, "FlightH", nil, nil},
			{"Spirit", 50.3, 62.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 3.7, 61.1, "Deadwind Pass", nil, "Arrow", nil, nil, nil, nil, nil, 1.5, 1430},
			{"Arrow", 33.4, 74.8, "Blasted Lands", nil, "Arrow", nil, nil, nil, nil, nil, 3.1, 1419},
    },
    ["Westfall"] = {
        {"Dungeon", 42.5, 71.7, "The Deadmines", "Dungeon", "Dungeon", 17, 26},
			{"FlightA", 56.6, 52.6, "Sentinel Hill" .. ", " .. "Westfall", nil, "FlightA", nil, nil},
			{"Spirit", 51.7, 49.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 62.0, 17.9, "Elwynn Forest", nil, "Arrow", nil, nil, nil, nil, nil, 5.4, 1429},
			{"Arrow", 67.9, 62.8, "Duskwood", nil, "Arrow", nil, nil, nil, nil, nil, 4.7, 1431},
    },
    ["Wetlands"] = {
        {"FlightA", 9.5, 59.7, "Menethil Harbor" .. ", " .. "Wetlands", nil, "FlightA", nil, nil},
			{"TravelA", 5.0, 63.5, "Boat to" .. " " .. "Theramore Isle" .. ", " .. "Dustwallow Marsh", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1445},
			{"TravelA", 4.6, 57.1, "Boat to" .. " " .. "Auberdine" .. ", " .. "Darkshore", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1439},
			{"Spirit", 11.0, 43.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 49.3, 41.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 51.3, 10.3, "Arathi Highlands", "Thandol Span", "Arrow", nil, nil, nil, nil, nil, 0, 1417},
			{"Arrow", 56.0, 70.3, "Loch Modan", "Dun Algaz", "Arrow", nil, nil, nil, nil, nil, 1.8, 1432},
    },
    ["Sunwell"] = {
        {"Spirit", 46.6, 32.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Dungeon", 61.2, 30.9, "Magisters' Terrace", "Dungeon", "Dungeon", 68, 70},
			{"Raid", 44.3, 45.6, "Sunwell Plateau", "Raid", "Raid", 70, 70}, -- The Sunwell
			{"FlightA", 48.5, 25.2, "Shattered Sun Staging Area" .. ", " .. "Isle of Quel Danas", nil, "FlightA", nil, nil},
			{"FlightH", 48.4, 25.1, "Shattered Sun Staging Area" .. ", " .. "Isle of Quel Danas", nil, "FlightH", nil, nil},
    },
    ["EversongWoods"] = {
        {"FlightH", 54.4, 50.7, "Silvermoon City" .. ", " .. "Eversong Woods", nil, "FlightH", nil, nil},
			{"Spirit", 38.2, 17.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 48.0, 49.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 44.3, 71.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 60.0, 64.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 48.7, 91.0, "Ghostlands", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1942},
			{"Arrow", 56.7, 49.7, "Silvermoon City", nil, "Arrow", nil, nil, nil, nil, nil, 0.0, 1954},
    },
    ["Ghostlands"] = {
        {"FlightH", 45.4, 30.5, "Tranquillien" .. ", " .. "Ghostlands", nil, "FlightH", nil, nil},
			{"FlightN", 74.7, 67.1, "Zul'Aman" .. ", " .. "Ghostlands", nil, "FlightN", nil, nil},
			{"Raid", 82.3, 64.3, "Zul'Aman", "Raid", "Raid", 70, 70},
			{"Spirit", 43.9, 25.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 61.5, 57.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 80.5, 69.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 47.5, 84.0, "Eastern Plaguelands", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1423},
			{"Arrow", 48.4, 13.2, "Eversong Woods", nil, "Arrow", nil, nil, nil, nil, nil, 0, 1941},
    },
    ["Teldrassil"] = {
        {"FlightA", 58.4, 94.0, "Rut'theran Village" .. ", " .. "Teldrassil", nil, "FlightA", nil, nil},
			{"TravelA", 54.9, 96.8, "Boat to" .. " " .. "Auberdine" .. ", " .. "Darkshore", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1439},
			{"Arrow", 55.9, 89.7, "Darnassus", "", "Arrow", nil, nil, nil, nil, nil, 0.3, 1457},
			{"Spirit", 58.7, 42.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 56.2, 63.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 36.2, 54.4, "Darnassus", nil, "Arrow", nil, nil, nil, nil, nil, 1.5, 1457},
    },
    ["Darkshore"] = {
        {"FlightA", 36.3, 45.6, "Auberdine" .. ", " .. "Darkshore", nil, "FlightA", nil, nil},
			{"TravelA", 32.4, 43.8, "Boat to" .. " " .. "Menethil Harbor" .. ", " .. "Wetlands", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1437},
			{"TravelA", 33.2, 40.1, "Boat to" .. " " .. "Rut'theran Village" .. ", " .. "Teldrassil", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1438},
			{"TravelA", 30.7, 41.0, "Boat to" .. " " .. "Valaar's Berth" .. ", " .. "Azuremyst Isle", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1943},
			{"Spirit", 41.8, 36.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 43.6, 92.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 43.3, 94.0, "Ashenvale", nil, "Arrow", nil, nil, nil, nil, nil, 4, 1440},
    },
    ["Ashenvale"] = {
        {"Dungeon", 14.5, 14.2, "Blackfathom Deeps", "Dungeon", "Dungeon", 24, 32},
			{"FlightA", 34.4, 48.0, "Astranaar" .. ", " .. "Ashenvale", nil, "FlightA", nil, nil},
			{"FlightA", 85.0, 43.4, "Forest Song" .. ", " .. "Ashenvale", nil, "FlightA", nil, nil},
			{"FlightH", 73.2, 61.6, "Splintertree Post" .. ", " .. "Ashenvale", nil, "FlightH", nil, nil},
			{"FlightH", 12.2, 33.8, "Zoram'gar Outpost" .. ", " .. "Ashenvale", nil, "FlightH", nil, nil},
			{"Spirit", 40.5, 52.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 80.7, 58.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 29.1, 14.8, "Darkshore", nil, "Arrow", nil, nil, nil, nil, nil, 0, 1439},
			{"Arrow", 42.3, 71.1, "Stonetalon Mountains", "The Talondeep Path", "Arrow", nil, nil, nil, nil, nil, 2.7, 1442},
			{"Arrow", 55.8, 30.2, "Felwood", nil, "Arrow", nil, nil, nil, nil, nil, 0, 1448},
			{"Arrow", 94.2, 47.3, "Azshara", nil, "Arrow", nil, nil, nil, nil, nil, 4.4, 1447},
			{"Arrow", 68.6, 86.8, "The Barrens", nil, "Arrow", nil, nil, nil, nil, nil, 3.2, 1413},
    },
    ["ThousandNeedles"] = {
        {"FlightH", 45.1, 49.1, "Freewind Post" .. ", " .. "Thousand Needles", nil, "FlightH", nil, nil},
			{"Spirit", 30.6, 23.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 68.7, 53.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 74.9, 93.3, "Tanaris", nil, "Arrow", nil, nil, nil, nil, nil, 3.2, 1446},
			{"Arrow", 8.3, 11.9, "Feralas", nil, "Arrow", nil, nil, nil, nil, nil, 0.7, 1444},
			{"Arrow", 32.2, 23.9, "The Barrens", "The Great Lift", "Arrow", nil, nil, nil, nil, nil, 5.4, 1413},
    },
    ["StonetalonMountains"] = {
        {"FlightA", 36.4, 7.2, "Stonetalon Peak" .. ", " .. "Stonetalon Mountains", nil, "FlightA", nil, nil},
			{"FlightH", 45.1, 59.8, "Sun Rock Retreat" .. ", " .. "Stonetalon Mountains", nil, "FlightH", nil, nil},
			{"Spirit", 40.3, 5.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 36.4, 75.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 57.5, 61.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 80.2, 92.4, "The Barrens", nil, "Arrow", nil, nil, nil, nil, nil, 3.4, 1413},
			{"Arrow", 30.4, 75.4, "Desolace", nil, "Arrow", nil, nil, nil, nil, nil, 2.7, 1443},
			{"Arrow", 78.2, 42.8, "Ashenvale", "The Talondeep Path", "Arrow", nil, nil, nil, nil, nil, 6.1, 1440},
			{"Arrow", 37.9, 67.8, "Sun Rock Retreat", "Mountain Pass (Horde Only)", "Arrow", nil, nil, nil, nil, nil, 4.1, 1442},
    },
    ["Desolace"] = {
        {"Dungeon", 29.1, 62.5, "Maraudon", "Dungeon", "Dungeon", 46, 55},
			{"FlightA", 64.7, 10.5, "Nijel's Point" .. ", " .. "Desolace", nil, "FlightA", nil, nil},
			{"FlightH", 21.6, 74.1, "Shadowprey Village" .. ", " .. "Desolace", nil, "FlightH", nil, nil},
			{"Spirit", 50.4, 62.9, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 53.4, 5.9, "Stonetalon Mountains", nil, "Arrow", nil, nil, nil, nil, nil, 5.9, 1442},
			{"Arrow", 41.6, 94.4, "Feralas", nil, "Arrow", nil, nil, nil, nil, nil, 3.3, 1444},
    },
    ["Feralas"] = {
        {"FlightA", 30.2, 43.2, "Feathermoon Stronghold" .. ", " .. "Feralas", nil, "FlightA", nil, nil},
			{"FlightH", 75.4, 44.4, "Camp Mojache" .. ", " .. "Feralas", nil, "FlightH", nil, nil},
			{"FlightA", 89.5, 45.9, "Thalanaar" .. ", " .. "Feralas", nil, "FlightA", nil, nil},
			{"Dungeon", 62.5, 24.9, "Dire Maul (North)", "Dungeon", "Dungeon", 56, 60},
			{"Dungeon", 60.3, 30.2, "Dire Maul (West)", "Dungeon", "Dungeon", 56, 60},
			{"Dungeon", 64.8, 30.2, "Dire Maul (East)", "Dungeon", "Dungeon", 56, 60},
			{"TravelA", 43.3, 42.8, "Boat to" .. " " .. "Feathermoon Stronghold" .. ", " .. "Feralas", nil, "TravelA", nil, nil},
			{"TravelA", 31.0, 39.8, "Boat to" .. " " .. "The Forgotten Coast" .. ", " .. "Feralas", nil, "TravelA", nil, nil},
			{"Spirit", 31.8, 48.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 54.8, 48.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 73.0, 44.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 44.9, 7.7, "Desolace", nil, "Arrow", nil, nil, nil, nil, nil, 6, 1443},
			{"Arrow", 88.7, 41.1, "Thousand Needles", nil, "Arrow", nil, nil, nil, nil, nil, 4.5, 1441},
			-- {"Dungeon", 77.1, 36.9, "Dire Maul (East)", "The Hidden Reach (requires Crescent Key)", "Dungeon", 56, 60},
    },
    ["Dustwallow"] = {
        {"Raid", 52.6, 76.8, "Onyxia's Lair", "Raid", "Raid", 60, 60},
			{"FlightA", 67.5, 51.3, "Theramore Isle" .. ", " .. "Dustwallow Marsh", nil, "FlightA", nil, nil},
			{"FlightH", 35.6, 31.9, "Brackenwall Village" .. ", " .. "Dustwallow Marsh", nil, "FlightH", nil, nil},
			{"FlightN", 42.8, 72.5, "Mudsprocket" .. ", " .. "Dustwallow Marsh", nil, "FlightN", nil, nil},
			{"TravelA", 71.6, 56.4, "Boat to" .. " " .. "Menethil Harbor" .. ", " .. "Wetlands", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1437},
			{"Spirit", 39.5, 31.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 46.6, 57.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 41.2, 74.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 63.6, 42.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 30.0, 47.1, "The Barrens", nil, "Arrow", nil, nil, nil, nil, nil, 1.6, 1413},
    },
    ["Tanaris"] = {
        {"Dungeon", 38.7, 20.0, "Zul'Farrak", "Dungeon", "Dungeon", 44, 54},
			{"Dunraid", 65.7, 49.9, "Caverns of Time", "Black Morass"  .. " (" .. "req" .. ": 65)" .. ", " .. "Hyjal Summit"  .. " (" .. "req" .. ": 70)" .. ", " .. "Old Hillsbrad"  .. " (" .. "req" .. ": 66)", "Dungeon", 66, 68},
			{"FlightA", 51.0, 29.3, "Gadgetzan" .. ", " .. "Tanaris", nil, "FlightA", nil, nil},
			{"FlightH", 51.6, 25.4, "Gadgetzan" .. ", " .. "Tanaris", nil, "FlightH", nil, nil},
			{"Spirit", 53.9, 28.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 49.4, 59.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 69.0, 40.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 63.6, 49.4, "Spirit Healer", "(inside Caverns of Time)", "Spirit", nil, nil},
			{"Arrow", 50.6, 24.4, "Thousand Needles", nil, "Arrow", nil, nil, nil, nil, nil, 5.7, 1441},
			{"Arrow", 27.1, 57.7, "Un'Goro Crater", nil, "Arrow", nil, nil, nil, nil, nil, 0.5, 1449},
    },
    ["Azshara"] = {
        {"FlightA", 11.9, 77.6, "Talrendis Point" .. ", " .. "Azshara", nil, "FlightA", nil, nil},
			{"FlightH", 22.0, 49.6, "Valormok" .. ", " .. "Azshara", nil, "FlightH", nil, nil},
			{"Spirit", 70.4, 16.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 54.3, 71.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 14.0, 78.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 10.6, 75.3, "Ashenvale", nil, "Arrow", nil, nil, nil, nil, nil, 0.9, 1440},
    },
    ["Felwood"] = {
        {"FlightA", 62.5, 24.2, "Talonbranch Glade" .. ", " .. "Felwood", nil, "FlightA", nil, nil},
			{"FlightH", 34.4, 54.0, "Bloodvenom Post" .. ", " .. "Felwood", nil, "FlightH", nil, nil},
			{"FlightN", 51.4, 82.2, "Emerald Sanctuary" .. ", " .. "Felwood", nil, "FlightN", nil, nil},
			{"Spirit", 49.5, 31.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 56.8, 87.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 65.0, 8.3, "Winterspring", "Timbermaw Hold", "Arrow", nil, nil, nil, nil, nil, 5.9, 1452},
			{"Arrow", 54.5, 89.2, "Ashenvale", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1440},
    },
    ["UngoroCrater"] = {
        {"FlightN", 45.2, 5.8, "Marshal's Refuge" .. ", " .. "Un'Goro Crater", nil, "FlightN", nil, nil},
			{"Spirit", 45.3, 7.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 50.0, 56.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 80.3, 50.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 71.4, 77.3, "Tanaris", nil, "Arrow", nil, nil, nil, nil, nil, 4.3, 1446},
			{"Arrow", 29.4, 22.3, "Silithus", nil, "Arrow", nil, nil, nil, nil, nil, 0.9, 1451},
    },
    ["Moonglade"] = {
        {"FlightA", 48.1, 67.4, "Lake Elune'ara" .. ", " .. "Moonglade", nil, "FlightA", nil, nil},
			{"FlightH", 32.1, 66.6, "Moonglade", nil, "FlightH", nil, nil},
			{"Spirit", 62.2, 70.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 35.7, 72.4, "Felwood" .. ", " .. "Winterspring", "Timbermaw Hold", "Arrow", nil, nil, nil, nil, nil, 3, 1448},
    },
    ["Silithus"] = {
        {"Raid", 28.6, 92.4, "Ahn'Qiraj", "Ruins of Ahn'Qiraj" .. ", " .. "Temple of Ahn'Qiraj", "Raid", 60, 60},
			{"FlightA", 50.6, 34.5, "Cenarion Hold" .. ", " .. "Silithus", nil, "FlightA", nil, nil},
			{"FlightH", 48.7, 36.7, "Cenarion Hold" .. ", " .. "Silithus", nil, "FlightH", nil, nil},
			{"Spirit", 47.2, 37.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 28.2, 87.1, "Spirit Healer", "(" .. "Ahn'Qiraj" .. ")", "Spirit", nil, nil},
			{"Spirit", 81.2, 20.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 82.4, 16.0, "Un'Goro Crater", nil, "Arrow", nil, nil, nil, nil, nil, 5.4, 1449},
    },
    ["Winterspring"] = {
        {"FlightA", 62.3, 36.6, "Everlook" .. ", " .. "Winterspring", nil, "FlightA", nil, nil},
			{"FlightH", 60.5, 36.3, "Everlook" .. ", " .. "Winterspring", nil, "FlightH", nil, nil},
			{"Spirit", 29.0, 43.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 61.5, 35.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 62.7, 61.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 27.9, 34.5, "Felwood", "Timbermaw Hold", "Arrow", nil, nil, nil, nil, nil, 0.7, 1448},
    },
    ["AzuremystIsle"] = {
        {"FlightA", 31.9, 46.4, "The Exodar" .. ", " .. "Azuremyst Isle", nil, "FlightA", nil, nil},
			{"TravelA", 20.3, 54.2, "Boat to" .. " " .. "Rut'theran Village" .. ", " .. "Teldrassil", nil, "TravelA", nil, nil, nil, nil, nil, 0, 1439},
			{"Spirit", 39.2, 19.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 47.2, 55.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 77.7, 48.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 36.9, 47.0, "The Exodar", "Seat of the Naaru", "Arrow", nil, nil, nil, nil, nil, 1.5, 1947},
			{"Arrow", 24.7, 49.4, "The Exodar", "The Vault of Lights", "Arrow", nil, nil, nil, nil, nil, 5.8, 1947},
			{"Arrow", 42.5, 5.4, "Bloodmyst Isle", nil, "Arrow", nil, nil, nil, nil, nil, 0.2, 1950},
    },
    ["BloodmystIsle"] = {
        {"FlightA", 57.7, 53.9, "Blood Watch" .. ", " .. "Bloodmyst Isle", nil, "FlightA", nil, nil},
			{"Spirit", 30.1, 45.9, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 58.1, 57.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 65.4, 92.6, "Azuremyst Isle", nil, "Arrow", nil, nil, nil, nil, nil, 3, 1943},
    },
    ["BladesEdgeMountains"] = {
        {"Raid", 68.7, 24.3, "Gruul's Lair", "Raid", "Raid", 70, 70},
			{"FlightA", 37.8, 61.4, "Sylvanaar" .. ", " .. "Blade's Edge Mountains", nil, "FlightA", nil, nil},
			{"FlightA", 61.0, 70.4, "Toshley's Station" .. ", " .. "Blade's Edge Mountains", nil, "FlightA", nil, nil},
			{"FlightH", 52.0, 54.2, "Thunderlord Stronghold" .. ", " .. "Blade's Edge Mountains", nil, "FlightH", nil, nil},
			{"FlightH", 76.4, 65.8, "Mok'Nathal Village" .. ", " .. "Blade's Edge Mountains", nil, "FlightH", nil, nil},
			{"FlightN", 61.6, 39.6, "Evergrove" .. ", " .. "Blade's Edge Mountains", nil, "FlightN", nil, nil},
			{"Spirit", 37.2, 24.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 33.6, 58.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 38.3, 67.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 52.1, 60.5, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 60.4, 66.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 69.3, 58.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 74.6, 26.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 62.8, 37.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 61.8, 14.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 37.3, 80.5, "Zangarmarsh", "Blade Tooth Canyon", "Arrow", nil, nil, nil, nil, nil, 3, 1946},
			{"Arrow", 51.7, 74.7, "Zangarmarsh", "Blades' Run", "Arrow", nil, nil, nil, nil, nil, 3, 1946},
			{"Arrow", 82.4, 28.7, "Netherstorm", nil, "Arrow", nil, nil, nil, nil, nil, 4.7, 1953},
    },
    ["Hellfire"] = {
        {"Dungeon", 47.7, 53.6, "Hellfire Ramparts", "Dungeon", "Dungeon", 58, 67},
			{"Dungeon", 47.7, 52.0, "The Shattered Halls", "Dungeon", "Dungeon", 69, 70},
			{"Dungeon", 46.0, 51.8, "The Blood Furnace", "Dungeon", "Dungeon", 61, 68},
			{"Raid", 46.6, 52.8, "Magtheridon's Lair", "Raid", "Raid", 70, 70},
			{"FlightA", 25.2, 37.2, "Temple of Telhamat" .. ", " .. "Hellfire Peninsula", nil, "FlightA", nil, nil},
			{"FlightA", 54.6, 62.4, "Honor Hold" .. ", " .. "Hellfire Peninsula", nil, "FlightA", nil, nil},
			{"FlightA", 87.4, 52.4, "The Dark Portal" .. ", " .. "Hellfire Peninsula", nil, "FlightA", nil, nil},
			{"FlightA", 78.4, 34.9, "Shatter Point" .. ", " .. "Hellfire Peninsula", nil, "FlightA", nil, nil},
			{"FlightH", 56.2, 36.2, "Thrallmar" .. ", " .. "Hellfire Peninsula", nil, "FlightH", nil, nil},
			{"FlightH", 27.8, 60.0, "Falcon Watch" .. ", " .. "Hellfire Peninsula", nil, "FlightH", nil, nil},
			{"FlightH", 87.4, 48.2, "The Dark Portal" .. ", " .. "Hellfire Peninsula", nil, "FlightH", nil, nil},
			{"FlightH", 61.6, 81.2, "Spinebreaker Ridge" .. ", " .. "Hellfire Peninsula", nil, "FlightH", nil, nil},
			{"TravelA", 88.6, 52.8, "Stormwind City", "Portal", pATex, nil, nil, nil, nil, nil, 0, 1453},
			{"TravelH", 88.6, 47.7, "Orgrimmar", "Portal", pHTex, nil, nil, nil, nil, nil, 0, 1454},
			{"PortalH", 88.6, 47.7, "Orgrimmar", "Portal"},
			{"PortalA", 88.6, 52.8, "Stormwind", "Portal"},
			{"Spirit", 22.8, 38.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 27.7, 63.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 60.0, 79.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 54.5, 66.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 57.5, 38.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 64.3, 22.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 86.8, 51.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 68.7, 27.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 40.3, 85.9, "Terokkar Forest", "Razorthorn Trail", "Arrow", nil, nil, nil, nil, nil, 2.7, 1952},
			{"Arrow", 6.7, 50.4, "Zangarmarsh", nil, "Arrow", nil, nil, nil, nil, nil, 1.6, 1946},
    },
    ["Nagrand"] = {
        {"FlightA", 54.2, 75.0, "Telaar" .. ", " .. "Nagrand", nil, "FlightA", nil, nil},
			{"FlightH", 57.2, 35.2, "Garadar" .. ", " .. "Nagrand", nil, "FlightH", nil, nil},
			{"Spirit", 20.4, 36.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 32.8, 56.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 39.8, 30.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 42.5, 46.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 66.6, 24.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 63.1, 69.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 33.5, 17.8, "Zangararsh", nil, "Arrow", nil, nil, nil, nil, nil, 0, 1946},
			{"Arrow", 77.5, 77.0, "Terokkar Forest", nil, "Arrow", nil, nil, nil, nil, nil, 3.7, 1952},
			{"Arrow", 72.3, 36.6, "Zangarmarsh", nil, "Arrow", nil, nil, nil, nil, nil, 5.4, 1946},
			{"Arrow", 77.5, 55.7, "Shattrath City", "Aldor", "Arrow", nil, nil, nil, nil, nil, 5.4, 1955},
    },
    ["Netherstorm"] = {
        {"Dungeon", 71.7, 55.0, "The Botanica", "Dungeon", "Dungeon", 70, 70},
			{"Dungeon", 74.4, 57.7, "The Arcatraz", "Dungeon", "Dungeon", 70, 70},
			{"Dungeon", 70.6, 69.7, "The Mechanar", "Dungeon", "Dungeon", 70, 70},
			{"Raid", 73.7, 63.7, "The Eye", "Raid", "Raid", 70, 70, nil, 69, 70}, -- Tempest Keep
			{"FlightN", 33.8, 64.0, "Area 52" .. ", " .. "Netherstorm", nil, "FlightN", nil, nil},
			{"FlightN", 45.2, 34.8, "The Stormspire" .. ", " .. "Netherstorm", nil, "FlightN", nil, nil},
			{"FlightN", 65.2, 66.6, "Cosmowrench" .. ", " .. "Netherstorm", nil, "FlightN", nil, nil},
			{"Spirit", 42.9, 29.4, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 33.8, 65.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 64.8, 66.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 56.6, 83.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 22.7, 55.6, "Blade's Edge Mountains", nil, "Arrow", nil, nil, nil, nil, nil, 1.5, 1949},
    },
    ["ShadowmoonValley"] = {
        {"Raid", 71.0, 46.4, "Black Temple", "Raid", "Raid", 70, 70},
			{"FlightA", 37.6, 55.4, "Wildhammer Stronghold" .. ", " .. "Shadowmoon Valley", nil, "FlightA", nil, nil},
			{"FlightH", 30.2, 29.2, "Shadowmoon Village" .. ", " .. "Shadowmoon Valley", nil, "FlightH", nil, nil},
			{"FlightN", 63.4, 30.4, "Altar of Sha'tar" .. ", " .. "Shadowmoon Valley", nil, "FlightN", nil, nil},
			{"FlightN", 56.2, 57.8, "Sanctum of the Stars" .. ", " .. "Shadowmoon Valley", nil, "FlightN", nil, nil},
			{"Spirit", 32.2, 28.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 39.5, 56.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 57.5, 59.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 63.6, 32.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 65.5, 43.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 65.7, 45.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 22.7, 28.6, "Terokkar Forest", nil, "Arrow", nil, nil, nil, nil, nil, 0.8, 1952},
    },
    ["TerokkarForest"] = {
        {"Dungeon", 43.2, 65.6, "Sethekk Halls", "Dungeon", "Dungeon", 67, 70},
			{"Dungeon", 36.1, 65.6, "Auchenai Crypts", "Dungeon", "Dungeon", 65, 70},
			{"Dungeon", 39.6, 71.0, "Shadow Labyrinth", "Dungeon", "Dungeon", 69, 70},
			{"Dungeon", 39.7, 60.2, "Mana-Tombs", "Dungeon", "Dungeon", 64, 70},
			{"FlightA", 59.4, 55.4, "Allerian Stronghold" .. ", " .. "Terokkar Forest", nil, "FlightA", nil, nil},
			{"FlightH", 49.2, 43.4, "Stonebreaker Hold" .. ", " .. "Terokkar Forest", nil, "FlightH", nil, nil},
			{"FlightN", 33.1, 23.1, "Shattrath City" .. ", " .. "Terokkar Forest", nil, "FlightN", nil, nil},
			{"Spirit", 39.9, 21.8, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 44.8, 40.0, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 59.5, 42.6, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 44.6, 71.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 62.9, 81.2, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 70.6, 49.4, "Shadowmoon Valley", nil, "Arrow", nil, nil, nil, nil, nil, 3.9, 1948},
			{"Arrow", 58.3, 19.3, "Hellfire Peninsula", "Razorthorn Trail", "Arrow", nil, nil, nil, nil, nil, 5.0, 1944},
			{"Arrow", 20.3, 56.3, "Nagrand", nil, "Arrow", nil, nil, nil, nil, nil, 0.3, 1951},
			{"Arrow", 33.1, 6.2, "Zangarmarsh", nil, "Arrow", nil, nil, nil, nil, nil, 0.6, 1946},
			{"Arrow", 34.8, 13.4, "Shattrath City", nil, "Arrow", nil, nil, nil, nil, nil, 2.4, 1955},
			{"Arrow", 38.2, 26.6, "Shattrath City", nil, "Arrow", nil, nil, nil, nil, nil, 1.4, 1955},
    },
    ["Zangarmarsh"] = {
        {"Dunraid", 50.4, 40.9, "Coilfang Reservoir",
				"Slave Pens"  .. " (62-69)|n" ..
				"Underbog"  .. " (63-70)|n" ..
				"Steamvault"  .. " (69-70)|n" ..
				"Serpentshrine Cavern"  .. " (70)",
				"Dungeon", 62, 70, nil, 61, 70},
			{"FlightA", 41.2, 28.8, "Orebor Harborage" .. ", " .. "Zangarmarsh", nil, "FlightA", nil, nil},
			{"FlightA", 67.8, 51.4, "Telredor" .. ", " .. "Zangarmarsh", nil, "FlightA", nil, nil},
			{"FlightH", 33.0, 51.0, "Zabra'jin" .. ", " .. "Zangarmarsh", nil, "FlightH", nil, nil},
			{"FlightH", 84.8, 55.0, "Swamprat Post" .. ", " .. "Zangarmarsh", nil, "FlightH", nil, nil},
			{"Spirit", 17.0, 48.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 36.8, 47.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 43.6, 31.7, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 47.5, 50.3, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 65.1, 50.9, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Spirit", 77.2, 64.1, "Spirit Healer", nil, "Spirit", nil, nil},
			{"Arrow", 81.2, 64.4, "Hellfire Peninsula", nil, "Arrow", nil, nil, nil, nil, nil, 5.4, 1944},
			{"Arrow", 82.0, 90.8, "Terokkar Forest", nil, "Arrow", nil, nil, nil, nil, nil, 3.3, 1952},
			{"Arrow", 69.6, 35.3, "Blade's Edge Mountains", "Blades' Run", "Arrow", nil, nil, nil, nil, nil, 5.4, 1949},
			{"Arrow", 40.8, 31.0, "Blade's Edge Mountains", "Blade Tooth Canyon", "Arrow", nil, nil, nil, nil, nil, 5.4, 1949},
			{"Arrow", 21.1, 70.5, "Nagrand", nil, "Arrow", nil, nil, nil, nil, nil, 3.1, 1951},
			{"Arrow", 67.9, 86.9, "Nagrand", nil, "Arrow", nil, nil, nil, nil, nil, 2.6, 1951},
    },
}


local activePins = {}
local tooltipFrame

-- Texture mapping for WotLK-compatible textures
local Textures = {
    ["Dungeon"] = "Interface\\Minimap\\MiniMap-DungeonLocPort",
    ["Raid"] = "Interface\\Minimap\\MiniMap-RaidPort",
    ["FlightA"] = "Interface\\TaxiFrame\\UI-Taxi-Icon-Green",
    ["FlightH"] = "Interface\\TaxiFrame\\UI-Taxi-Icon-Green",
    ["FlightN"] = "Interface\\TaxiFrame\\UI-Taxi-Icon-Green",
    ["TravelA"] = "Interface\\TaxiFrame\\UI-Taxi-Icon-Green",
    ["TravelH"] = "Interface\\TaxiFrame\\UI-Taxi-Icon-Green",
    ["TravelN"] = "Interface\\TaxiFrame\\UI-Taxi-Icon-Green",
    ["Spirit"] = "Interface\\TargetingFrame\\PortraitQuestGiver",
    ["Arrow"] = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
}

local function ClearPins()
    for _, pin in ipairs(activePins) do
        pin:Hide()
        pin:SetParent(nil)
    end
    wipe(activePins)
end

local function Pin_OnEnter(self)
    if not tooltipFrame then
        tooltipFrame = CreateFrame("GameTooltip", "CartoMapper_POITooltip", UIParent, "GameTooltipTemplate")
    end
    tooltipFrame:SetOwner(self, "ANCHOR_RIGHT")
    tooltipFrame:ClearLines()
    tooltipFrame:AddLine(self.title, 1, 1, 1)
    if self.subtext and self.subtext ~= "" then
        tooltipFrame:AddLine(self.subtext, 0.8, 0.8, 0.8, true)
    end
    tooltipFrame:Show()
end

local function Pin_OnLeave(self)
    if tooltipFrame then
        tooltipFrame:Hide()
    end
end

local function Pin_OnClick(self)
    if self.targetMapID then
        -- Zoom/Transition to target map if it is a zone crossing arrow
        SetMapByID(self.targetMapID)
    end
end

local function DrawPins()
    ClearPins()
    
    local mapFileName = GetMapInfo()
    if not mapFileName or not POIData[mapFileName] then return end

    local w = WorldMapDetailFrame:GetWidth()
    local h = WorldMapDetailFrame:GetHeight()
    local scale = WorldMapDetailFrame:GetScale()

    for _, pinInfo in ipairs(POIData[mapFileName]) do
        local pinType, px, py, title, subtext, texName, minLevel, maxLevel, _, _, _, arrowAngle, targetMapID = unpack(pinInfo)

        local pin = CreateFrame("Button", nil, WorldMapDetailFrame)
        pin:SetSize(16, 16)
        
        -- Inverse scale with map zoom so pins stay readable
        pin:SetScale(1 / scale)
        
        -- Set position relative to WorldMapDetailFrame
        local x = (px / 100) * w
        local y = -(py / 100) * h
        pin:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", x, y)

        -- Texture
        local tex = pin:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(Textures[pinType] or "Interface\\Minimap\\MiniMap-QuestGiver")
        
        -- Rotate arrow texture if needed
        if pinType == "Arrow" and arrowAngle then
            -- Simple rotation approximation if desired, or let it face default
        end

        pin.title = title
        
        -- Append dungeon level range to title if present
        if minLevel and maxLevel then
            pin.title = title .. " (" .. minLevel .. "-" .. maxLevel .. ")"
        end
        
        pin.subtext = subtext
        pin.targetMapID = targetMapID

        pin:SetScript("OnEnter", Pin_OnEnter)
        pin:SetScript("OnLeave", Pin_OnLeave)
        if targetMapID then
            pin:SetScript("OnClick", Pin_OnClick)
        end

        pin:Show()
        tinsert(activePins, pin)
    end
end

-- Refresh pin scaling on zoom updates
local function UpdatePinScaling()
    local scale = WorldMapDetailFrame:GetScale()
    for _, pin in ipairs(activePins) do
        pin:SetScale(1 / scale)
    end
end

function POIs.Enable()
    hooksecurefunc("WorldMapFrame_Update", DrawPins)
    hooksecurefunc("WorldMapFrame_SetPOIMaxBounds", UpdatePinScaling)
end
