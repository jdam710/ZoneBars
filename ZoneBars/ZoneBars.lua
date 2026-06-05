local ADDON_NAME = ...

local UNKNOWN_EXPANSION = "Unknown"
local RAID_TYPE = "raid"
local DUNGEON_TYPE = "party"

local DEFAULT_BARS = {
    [1] = false,
    [2] = false,
    [3] = false,
    [4] = false,
    [5] = false,
    [6] = false,
    [7] = false,
    [8] = false,
    [9] = false,
    [10] = false,
    [11] = false,
    [12] = false,
    [13] = false,
    [14] = false,
    [15] = false,
    pet = false,
    stance = false,
    vehicle = false,
}

local HIDE_MODE = "hide"
local SHOW_MODE = "show"

local MODE_LABELS = {
    [HIDE_MODE] = "Hide",
    [SHOW_MODE] = "Show",
}

local DEFAULT_DIFFICULTIES = {
    [16] = true,
}

local DEFAULTS = {
    nextRuleID = 1,
    rules = {},
    discovered = {},
}

local DIFFICULTIES = {
    { id = 0, label = "Any" },
    { id = 1, label = "Dungeon Normal" },
    { id = 2, label = "Dungeon Heroic" },
    { id = 23, label = "Dungeon Mythic" },
    { id = 8, label = "Mythic Keystone" },
    { id = 24, label = "Timewalking" },
    { id = 3, label = "10 Player" },
    { id = 4, label = "25 Player" },
    { id = 5, label = "10 Player Heroic" },
    { id = 6, label = "25 Player Heroic" },
    { id = 7, label = "Raid Finder 25" },
    { id = 14, label = "Raid Normal" },
    { id = 15, label = "Raid Heroic" },
    { id = 16, label = "Raid Mythic" },
    { id = 17, label = "Raid Finder" },
    { id = 33, label = "Timewalking Raid" },
}

local FALLBACK_DIFFICULTY_IDS = {}

for _, difficulty in ipairs(DIFFICULTIES) do
    FALLBACK_DIFFICULTY_IDS[difficulty.id] = true
end

local TYPE_LABELS = {
    [RAID_TYPE] = "Raids",
    [DUNGEON_TYPE] = "Dungeons",
}

local BAR_FRAME_NAMES = {
    [1] = { "MainActionBar", "MainMenuBar", "BT4Bar1", "ElvUI_Bar1", "DominosFrame1" },
    [2] = { "MultiBarBottomLeft", "BT4Bar2", "ElvUI_Bar2", "DominosFrame2" },
    [3] = { "MultiBarBottomRight", "BT4Bar3", "ElvUI_Bar3", "DominosFrame3" },
    [4] = { "MultiBarRight", "BT4Bar4", "ElvUI_Bar4", "DominosFrame4" },
    [5] = { "MultiBarLeft", "BT4Bar5", "ElvUI_Bar5", "DominosFrame5" },
    [6] = { "MultiBar5", "BT4Bar6", "ElvUI_Bar6", "DominosFrame6" },
    [7] = { "MultiBar6", "BT4Bar7", "ElvUI_Bar7", "DominosFrame7" },
    [8] = { "MultiBar7", "BT4Bar8", "ElvUI_Bar8", "DominosFrame8" },
    [9] = { "BT4Bar9", "ElvUI_Bar9", "DominosFrame9" },
    [10] = { "BT4Bar10", "ElvUI_Bar10", "DominosFrame10" },
    [11] = { "DominosFrame11" },
    [12] = { "DominosFrame12" },
    [13] = { "BT4Bar13", "ElvUI_Bar13", "DominosFrame13" },
    [14] = { "BT4Bar14", "ElvUI_Bar14", "DominosFrame14" },
    [15] = { "BT4Bar15" },
    pet = { "PetActionBar", "PetActionBarFrame", "BT4BarPetBar", "ElvUI_BarPet", "DominosFramepet" },
    stance = { "StanceBar", "StanceBarFrame", "BT4BarStanceBar", "ElvUI_StanceBar", "DominosFrameclass" },
    vehicle = { "MainMenuBarVehicleLeaveButton", "VehicleLeaveButtonHolder", "OverrideActionBar", "BT4BarVehicle", "DominosFramepossess" },
}

local BAR_BUTTON_NAMES = {
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {},
    [8] = {},
    pet = {},
    stance = {},
    vehicle = { "MainMenuBarVehicleLeaveButton" },
}

local function AddButtonNames(barID, prefix, count)
    for index = 1, count do
        BAR_BUTTON_NAMES[barID][#BAR_BUTTON_NAMES[barID] + 1] = prefix .. index
    end
end

AddButtonNames(1, "ActionButton", 12)
AddButtonNames(2, "MultiBarBottomLeftButton", 12)
AddButtonNames(3, "MultiBarBottomRightButton", 12)
AddButtonNames(4, "MultiBarRightButton", 12)
AddButtonNames(5, "MultiBarLeftButton", 12)
AddButtonNames(6, "MultiBar5Button", 12)
AddButtonNames(7, "MultiBar6Button", 12)
AddButtonNames(8, "MultiBar7Button", 12)
AddButtonNames("pet", "PetActionButton", 10)
AddButtonNames("stance", "StanceButton", 10)
AddButtonNames("vehicle", "OverrideActionBarButton", 6)

local BAR_OPTIONS = {}

for barNumber = 1, 15 do
    BAR_OPTIONS[#BAR_OPTIONS + 1] = { id = barNumber, label = "Bar " .. barNumber }
end

BAR_OPTIONS[#BAR_OPTIONS + 1] = { id = "pet", label = "Pet bar" }
BAR_OPTIONS[#BAR_OPTIONS + 1] = { id = "stance", label = "Stance/Class bar" }
BAR_OPTIONS[#BAR_OPTIONS + 1] = { id = "vehicle", label = "Vehicle bar" }

local frame = CreateFrame("Frame")
local hiddenFrames = {}
local pendingUpdate = false
local optionsFrame
local catalog
local editor
local RULE_ROW_WIDTH = 620
local RULE_SCROLL_WIDTH = 620

local function CopyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            CopyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function CopyTable(source)
    local copy = {}

    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            copy[key] = CopyTable(value)
        else
            copy[key] = value
        end
    end

    return copy
end

local function Trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function Normalize(value)
    return Trim(value):lower()
end

local function SortByName(left, right)
    return (left.name or "") < (right.name or "")
end

local function LoadEncounterJournalData()
    if EJ_GetNumTiers and EJ_GetInstanceByIndex then
        return
    end

    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_EncounterJournal")
    elseif LoadAddOn then
        pcall(LoadAddOn, "Blizzard_EncounterJournal")
    end
end

local function GetDifficultyLabel(id)
    for _, difficulty in ipairs(DIFFICULTIES) do
        if difficulty.id == id then
            return difficulty.label
        end
    end

    if GetDifficultyInfo then
        local name = GetDifficultyInfo(id)

        if name and name ~= "" then
            return name
        end
    end

    return "Unknown (" .. tostring(id) .. ")"
end

local function AddDifficulty(difficulties, seen, difficultyID, label)
    if not difficultyID or seen[difficultyID] then
        return
    end

    seen[difficultyID] = true
    difficulties[#difficulties + 1] = {
        id = difficultyID,
        label = label or GetDifficultyLabel(difficultyID),
    }
end

local function GetDefaultDifficultiesForType(instanceType)
    local difficulties = {
        { id = 0, label = "Any" },
    }
    local seen = {
        [0] = true,
    }

    for _, difficulty in ipairs(DIFFICULTIES) do
        if difficulty.id ~= 0 then
            local difficultyType

            if GetDifficultyInfo then
                local difficultyName
                difficultyName, difficultyType = GetDifficultyInfo(difficulty.id)
            end

            if not difficultyType or difficultyType == instanceType then
                AddDifficulty(difficulties, seen, difficulty.id, difficulty.label)
            end
        end
    end

    return difficulties
end

local function IsValidEncounterDifficulty(difficultyID)
    local ok, isValid = pcall(EJ_IsValidInstanceDifficulty, difficultyID)

    return ok and isValid
end

local function GetEncounterJournalDifficulties(journalInstanceID, instanceType)
    if not journalInstanceID or not (EJ_SelectInstance and EJ_IsValidInstanceDifficulty) then
        return nil
    end

    local previousDifficulty = EJ_GetDifficulty and EJ_GetDifficulty() or nil
    local previousInstanceID

    if EJ_GetInstanceInfo then
        local ok, _, _, _, _, _, _, _, selectedInstanceID = pcall(EJ_GetInstanceInfo)

        if ok then
            previousInstanceID = selectedInstanceID
        end
    end

    local ok = pcall(EJ_SelectInstance, journalInstanceID)

    if not ok then
        return nil
    end

    local difficulties = {
        { id = 0, label = "Any" },
    }
    local seen = {
        [0] = true,
    }

    for _, difficulty in ipairs(DIFFICULTIES) do
        if difficulty.id ~= 0 and IsValidEncounterDifficulty(difficulty.id) then
            AddDifficulty(difficulties, seen, difficulty.id, difficulty.label)
        end
    end

    if GetDifficultyInfo then
        for difficultyID = 1, 255 do
            if not FALLBACK_DIFFICULTY_IDS[difficultyID] and IsValidEncounterDifficulty(difficultyID) then
                local name, difficultyType = GetDifficultyInfo(difficultyID)

                if name and name ~= "" and (not difficultyType or difficultyType == instanceType) then
                    AddDifficulty(difficulties, seen, difficultyID, name)
                end
            end
        end
    end

    if previousInstanceID then
        pcall(EJ_SelectInstance, previousInstanceID)
    end

    if previousDifficulty and EJ_SetDifficulty then
        pcall(EJ_SetDifficulty, previousDifficulty)
    end

    if #difficulties > 1 then
        return difficulties
    end

    return nil
end

local function GetCurrentExpansionName()
    LoadEncounterJournalData()

    if not (EJ_GetCurrentTier and EJ_GetTierInfo) then
        return nil
    end

    local currentTier = EJ_GetCurrentTier()

    if not currentTier then
        return nil
    end

    return EJ_GetTierInfo(currentTier)
end

local function GetClientExpansionName()
    if not GetExpansionDisplayInfo then
        return nil
    end

    local expansionLevel

    if GetClientDisplayExpansionLevel then
        expansionLevel = GetClientDisplayExpansionLevel()
    elseif GetExpansionLevel then
        expansionLevel = GetExpansionLevel()
    end

    if not expansionLevel then
        return nil
    end

    local info = GetExpansionDisplayInfo(expansionLevel)

    if type(info) == "table" then
        return info.expansionName or info.name or info.title
    end

    return info
end

local function IsPseudoInstance(expansionName, instanceName, pseudoInstanceNames)
    if Normalize(instanceName) == Normalize(expansionName) then
        return true
    end

    if pseudoInstanceNames and pseudoInstanceNames[Normalize(instanceName)] then
        return true
    end

    local clientExpansionName = GetClientExpansionName()

    return clientExpansionName and Normalize(instanceName) == Normalize(clientExpansionName)
end

local function GetDifficultiesLabel(difficulties)
    if difficulties and difficulties[0] then
        return "Any"
    end

    local labels = {}
    local seen = {}

    for _, difficulty in ipairs(DIFFICULTIES) do
        if difficulties and difficulties[difficulty.id] then
            labels[#labels + 1] = difficulty.label
            seen[difficulty.id] = true
        end
    end

    for difficultyID, enabled in pairs(difficulties or {}) do
        if enabled and not seen[difficultyID] then
            labels[#labels + 1] = GetDifficultyLabel(difficultyID)
        end
    end

    if #labels == 0 then
        return "None"
    end

    return table.concat(labels, ", ")
end

local function GetDifficultyPickerLabel(difficulties)
    if difficulties and difficulties[0] then
        return "Any"
    end

    local count = 0
    local firstLabel
    local seen = {}

    for _, difficulty in ipairs(DIFFICULTIES) do
        if difficulties and difficulties[difficulty.id] then
            count = count + 1
            firstLabel = firstLabel or difficulty.label
            seen[difficulty.id] = true
        end
    end

    for difficultyID, enabled in pairs(difficulties or {}) do
        if enabled and not seen[difficultyID] then
            count = count + 1
            firstLabel = firstLabel or GetDifficultyLabel(difficultyID)
        end
    end

    if count == 0 then
        return "None"
    elseif count == 1 then
        return firstLabel
    end

    return count .. " difficulties"
end

local function GetBarLabel(barID)
    for _, bar in ipairs(BAR_OPTIONS) do
        if bar.id == barID then
            return bar.label
        end
    end

    return "Bar " .. tostring(barID)
end

local function GetBarsLabel(bars)
    local labels = {}
    local seen = {}

    for _, bar in ipairs(BAR_OPTIONS) do
        if bars and bars[bar.id] then
            labels[#labels + 1] = bar.label
            seen[bar.id] = true
        end
    end

    for barID, enabled in pairs(bars or {}) do
        if enabled and not seen[barID] then
            labels[#labels + 1] = GetBarLabel(barID)
        end
    end

    if #labels == 0 then
        return "No bars"
    end

    return table.concat(labels, ", ")
end

local function GetBarPickerLabel(bars)
    local count = 0
    local firstLabel
    local seen = {}

    for _, bar in ipairs(BAR_OPTIONS) do
        if bars and bars[bar.id] then
            count = count + 1
            firstLabel = firstLabel or bar.label
            seen[bar.id] = true
        end
    end

    for barID, enabled in pairs(bars or {}) do
        if enabled and not seen[barID] then
            count = count + 1
            firstLabel = firstLabel or GetBarLabel(barID)
        end
    end

    if count == 0 then
        return "None"
    elseif count == 1 then
        return firstLabel
    end

    return count .. " Selected"
end

local function EnsureCatalog()
    if catalog then
        return catalog
    end

    catalog = {
        expansions = {},
        byExpansion = {},
        byMapID = {},
        byName = {},
    }
    local pseudoInstanceNames = {}

    local function addPseudoInstanceName(name)
        local normalizedName = Normalize(name)

        if normalizedName ~= "" and normalizedName ~= Normalize("Current Season") then
            pseudoInstanceNames[normalizedName] = true
        end
    end

    local function ensureExpansion(name)
        name = Trim(name)

        if name == "" then
            name = UNKNOWN_EXPANSION
        end

        if not catalog.byExpansion[name] then
            catalog.expansions[#catalog.expansions + 1] = name
            catalog.byExpansion[name] = {
                [RAID_TYPE] = {},
                [DUNGEON_TYPE] = {},
            }
        end

        return name
    end

    local function addInstance(expansionName, instanceType, name, mapID, journalInstanceID)
        if not name or name == "" then
            return
        end

        if IsPseudoInstance(expansionName, name, pseudoInstanceNames) then
            return
        end

        if mapID == 0 then
            mapID = nil
        end

        expansionName = ensureExpansion(expansionName)

        local entry = {
            name = name,
            instanceType = instanceType,
            expansion = expansionName,
            mapID = mapID,
            journalInstanceID = journalInstanceID,
            difficulties = GetEncounterJournalDifficulties(journalInstanceID, instanceType),
        }

        catalog.byExpansion[expansionName][instanceType][#catalog.byExpansion[expansionName][instanceType] + 1] = entry
        catalog.byName[Normalize(name)] = entry

        if mapID then
            catalog.byMapID[mapID] = entry
        end
    end

    LoadEncounterJournalData()

    if EJ_GetNumTiers and EJ_SelectTier and EJ_GetTierInfo and EJ_GetInstanceByIndex and EJ_GetInstanceInfo then
        local currentTier = EJ_GetCurrentTier and EJ_GetCurrentTier() or nil
        local tierCount = EJ_GetNumTiers() or 0

        addPseudoInstanceName(GetClientExpansionName())

        for tierIndex = 1, tierCount do
            addPseudoInstanceName(EJ_GetTierInfo(tierIndex))
        end

        for tierIndex = 1, tierCount do
            local tierName = EJ_GetTierInfo(tierIndex)
            EJ_SelectTier(tierIndex)

            for _, scan in ipairs({
                { isRaid = false, instanceType = DUNGEON_TYPE },
                { isRaid = true, instanceType = RAID_TYPE },
            }) do
                local index = 1

                while true do
                    local journalInstanceID, name = EJ_GetInstanceByIndex(index, scan.isRaid)

                    if not name then
                        break
                    end

                    local mapID
                    local _, _, _, _, _, _, _, _, _, infoMapID, _, infoIsRaid = EJ_GetInstanceInfo(journalInstanceID)

                    if infoIsRaid == scan.isRaid then
                        mapID = infoMapID
                    end

                    addInstance(tierName, scan.instanceType, name, mapID, journalInstanceID)
                    index = index + 1
                end
            end
        end

        if currentTier then
            EJ_SelectTier(currentTier)
        end
    end

    for _, entry in pairs(ZoneBarsDB.discovered or {}) do
        local typeKey = entry.instanceType == RAID_TYPE and RAID_TYPE or DUNGEON_TYPE
        local mapID = tonumber(entry.instanceMapID)

        if mapID == 0 then
            mapID = nil
        end

        if not (mapID and catalog.byMapID[mapID]) and not catalog.byName[Normalize(entry.name)] then
            addInstance(entry.expansion or UNKNOWN_EXPANSION, typeKey, entry.name, mapID, nil)
        end
    end

    for _, expansionName in ipairs(catalog.expansions) do
        table.sort(catalog.byExpansion[expansionName][RAID_TYPE], SortByName)
        table.sort(catalog.byExpansion[expansionName][DUNGEON_TYPE], SortByName)
    end

    return catalog
end

local function RebuildCatalog()
    catalog = nil
    return EnsureCatalog()
end

local function FindCurrentCatalogEntry(instanceName, instanceMapID)
    local data = EnsureCatalog()

    if instanceMapID and instanceMapID ~= 0 and data.byMapID[instanceMapID] then
        return data.byMapID[instanceMapID]
    end

    return data.byName[Normalize(instanceName)]
end

local function GetSelectedCatalogEntry()
    if not editor then
        return nil
    end

    return FindCurrentCatalogEntry(editor.instanceName, editor.instanceMapID)
end

local function GetAvailableDifficulties()
    local entry = GetSelectedCatalogEntry()

    if entry and entry.difficulties and #entry.difficulties > 0 then
        return entry.difficulties
    end

    return GetDefaultDifficultiesForType(editor and editor.instanceType or RAID_TYPE)
end

local function SyncEditorDifficultiesToInstance()
    if not editor or not editor.difficulties then
        return
    end

    if editor.difficulties[0] then
        wipe(editor.difficulties)
        editor.difficulties[0] = true
        return
    end

    local available = {}

    for _, difficulty in ipairs(GetAvailableDifficulties()) do
        available[difficulty.id] = true
    end

    local hasValidSelection = false

    for difficultyID, enabled in pairs(editor.difficulties) do
        if enabled and not available[difficultyID] then
            editor.difficulties[difficultyID] = nil
        elseif enabled then
            hasValidSelection = true
        end
    end

    if not hasValidSelection then
        editor.difficulties[0] = true
    end
end

local function RememberCurrentInstance()
    if not ZoneBarsDB then
        return
    end

    local instanceName, instanceType, difficultyID, difficultyName, _, _, _, instanceMapID = GetInstanceInfo()

    if instanceType ~= RAID_TYPE and instanceType ~= DUNGEON_TYPE then
        return
    end

    local knownEntry = FindCurrentCatalogEntry(instanceName, instanceMapID)
    local expansionName = knownEntry and knownEntry.expansion or UNKNOWN_EXPANSION
    local key = tostring((instanceMapID and instanceMapID ~= 0) and instanceMapID or Normalize(instanceName))

    ZoneBarsDB.discovered[key] = {
        name = instanceName,
        instanceType = instanceType,
        expansion = expansionName,
        instanceMapID = instanceMapID,
        difficultyID = difficultyID,
        difficultyName = difficultyName,
    }

    if not knownEntry then
        RebuildCatalog()
    end
end

local function GetAvailableInstances()
    local data = EnsureCatalog()
    local expansion = editor and editor.expansion or UNKNOWN_EXPANSION
    local instanceType = editor and editor.instanceType or RAID_TYPE

    if data.byExpansion[expansion] and data.byExpansion[expansion][instanceType] then
        return data.byExpansion[expansion][instanceType]
    end

    return {}
end

local function SelectFirstAvailableInstance()
    local instances = GetAvailableInstances()
    local first = instances[1]

    if first then
        editor.instanceName = first.name
        editor.instanceMapID = first.mapID
        editor.journalInstanceID = first.journalInstanceID
    else
        editor.instanceName = ""
        editor.instanceMapID = nil
        editor.journalInstanceID = nil
    end

    SyncEditorDifficultiesToInstance()
end

local function SelectFirstPopulatedExpansion()
    local data = EnsureCatalog()

    for _, expansionName in ipairs(data.expansions) do
        if #data.byExpansion[expansionName][editor.instanceType] > 0 then
            editor.expansion = expansionName
            SelectFirstAvailableInstance()
            return
        end
    end

    SelectFirstAvailableInstance()
end

local function SelectInstanceFromCatalog(instanceName, instanceType, instanceMapID)
    local entry = FindCurrentCatalogEntry(instanceName, instanceMapID)

    if not entry then
        return false
    end

    editor.expansion = entry.expansion or UNKNOWN_EXPANSION
    editor.instanceType = instanceType
    editor.instanceName = entry.name or instanceName
    editor.instanceMapID = entry.mapID
    editor.journalInstanceID = entry.journalInstanceID
    SyncEditorDifficultiesToInstance()

    return true
end

local function SelectCurrentInstanceIfPossible()
    local instanceName, instanceType, difficultyID, _, _, _, _, instanceMapID = GetInstanceInfo()

    if instanceType ~= RAID_TYPE and instanceType ~= DUNGEON_TYPE then
        return false
    end

    if not SelectInstanceFromCatalog(instanceName, instanceType, instanceMapID) then
        editor.expansion = UNKNOWN_EXPANSION
        editor.instanceType = instanceType
        editor.instanceName = instanceName or ""
        editor.instanceMapID = instanceMapID
        editor.journalInstanceID = nil
    end

    wipe(editor.difficulties)
    editor.difficulties[difficultyID or 0] = true
    SyncEditorDifficultiesToInstance()

    return true
end

local function SelectMostRecentRaid()
    local data = EnsureCatalog()

    for tierIndex = #data.expansions, 1, -1 do
        local expansionName = data.expansions[tierIndex]
        local raids = data.byExpansion[expansionName] and data.byExpansion[expansionName][RAID_TYPE]

        if raids and #raids > 0 then
            local raid = raids[#raids]
            editor.expansion = expansionName
            editor.instanceType = RAID_TYPE
            editor.instanceName = raid.name
            editor.instanceMapID = raid.mapID
            editor.journalInstanceID = raid.journalInstanceID
            SyncEditorDifficultiesToInstance()
            return true
        end
    end

    return false
end

local function ResetEditor()
    local currentExpansion = GetCurrentExpansionName() or UNKNOWN_EXPANSION

    editor = {
        editingID = nil,
        expansion = currentExpansion,
        instanceType = RAID_TYPE,
        instanceName = "",
        instanceMapID = nil,
        journalInstanceID = nil,
        mode = HIDE_MODE,
        difficulties = CopyTable(DEFAULT_DIFFICULTIES),
        bars = CopyTable(DEFAULT_BARS),
    }

    if not SelectCurrentInstanceIfPossible() and not SelectMostRecentRaid() then
        SelectFirstAvailableInstance()

        if editor.instanceName == "" then
            SelectFirstPopulatedExpansion()
        end
    end

    SyncEditorDifficultiesToInstance()
end

local function LoadRuleIntoEditor(rule)
    editor = {
        editingID = rule.id,
        expansion = rule.expansion or UNKNOWN_EXPANSION,
        instanceType = rule.instanceType or RAID_TYPE,
        instanceName = rule.instanceName or "",
        instanceMapID = rule.instanceMapID,
        journalInstanceID = rule.journalInstanceID,
        mode = rule.mode or HIDE_MODE,
        difficulties = CopyTable(rule.difficulties),
        bars = CopyTable(rule.bars),
    }

    CopyDefaults(editor.difficulties, {})
    CopyDefaults(editor.bars, DEFAULT_BARS)
    SyncEditorDifficultiesToInstance()
end

local function GetBarFrames(barNumber)
    local frames = {}
    local seen = {}
    local names = BAR_FRAME_NAMES[barNumber]

    local function AddFrame(barFrame)
        if barFrame and not seen[barFrame] then
            frames[#frames + 1] = barFrame
            seen[barFrame] = true
        end
    end

    local function AddChildren(parent)
        if not (parent and parent.GetChildren) then
            return
        end

        for _, child in ipairs({ parent:GetChildren() }) do
            if child and not seen[child] then
                AddFrame(child)
                AddChildren(child)
            end
        end
    end

    for _, name in ipairs(names or {}) do
        local barFrame = _G[name]
        AddFrame(barFrame)
        AddChildren(barFrame)
    end

    for _, name in ipairs(BAR_BUTTON_NAMES[barNumber] or {}) do
        AddFrame(_G[name])
    end

    return frames
end

local function RuleMatches(rule, instanceName, instanceType, difficultyID, instanceMapID)
    if not rule or not rule.instanceName or rule.instanceName == "" then
        return false
    end

    if instanceType ~= rule.instanceType then
        return false
    end

    if not (rule.difficulties and (rule.difficulties[0] or rule.difficulties[difficultyID])) then
        return false
    end

    if rule.instanceMapID and instanceMapID and instanceMapID ~= 0 and rule.instanceMapID == instanceMapID then
        return true
    end

    return Normalize(instanceName) == Normalize(rule.instanceName)
end

local function GetBarsToHide()
    local instanceName, instanceType, difficultyID, _, _, _, _, instanceMapID = GetInstanceInfo()
    local barsToHide = {}
    local showControlledBars = {}
    local matchedShowBars = {}

    for _, rule in ipairs(ZoneBarsDB.rules or {}) do
        local mode = rule.mode or HIDE_MODE
        local matches = RuleMatches(rule, instanceName, instanceType, difficultyID, instanceMapID)

        if mode == SHOW_MODE then
            for barNumber, enabled in pairs(rule.bars or {}) do
                if enabled then
                    showControlledBars[barNumber] = true

                    if matches then
                        matchedShowBars[barNumber] = true
                    end
                end
            end
        elseif matches then
            for barNumber, enabled in pairs(rule.bars or {}) do
                if enabled then
                    barsToHide[barNumber] = true
                end
            end
        end
    end

    for barNumber, enabled in pairs(showControlledBars) do
        if enabled and not matchedShowBars[barNumber] then
            barsToHide[barNumber] = true
        end
    end

    return barsToHide
end

local function RestoreHiddenFrames()
    for barFrame, state in pairs(hiddenFrames) do
        if barFrame and barFrame.Show then
            barFrame:SetAlpha(state.alpha or 1)

            if state.mouseEnabled ~= nil and barFrame.EnableMouse then
                barFrame:EnableMouse(state.mouseEnabled)
            end

            if state.wasShown then
                barFrame:Show()
            elseif barFrame.Hide then
                barFrame:Hide()
            end
        end
    end

    wipe(hiddenFrames)
end

local function HideFrame(barFrame)
    if not hiddenFrames[barFrame] then
        hiddenFrames[barFrame] = {
            alpha = barFrame:GetAlpha(),
            wasShown = barFrame:IsShown(),
            mouseEnabled = barFrame.IsMouseEnabled and barFrame:IsMouseEnabled() or nil,
        }
    end

    barFrame:SetAlpha(0)

    if barFrame.EnableMouse then
        barFrame:EnableMouse(false)
    end

    barFrame:Hide()
end

local function HideRuleFrames(rule)
    for barNumber, enabled in pairs(rule.bars or {}) do
        if enabled then
            for _, barFrame in ipairs(GetBarFrames(barNumber)) do
                HideFrame(barFrame)
            end
        end
    end
end

local function HideBars(barSet)
    HideRuleFrames({ bars = barSet })
end

local function ApplyVisibility()
    pendingUpdate = false

    if InCombatLockdown() then
        pendingUpdate = true
        return
    end

    RememberCurrentInstance()
    RestoreHiddenFrames()

    local barsToHide = GetBarsToHide()

    local hasBarsToHide = false

    for _, enabled in pairs(barsToHide) do
        if enabled then
            hasBarsToHide = true
            break
        end
    end

    if hasBarsToHide then
        HideBars(barsToHide)
    end
end

local function QueueUpdate()
    C_Timer.After(0.5, ApplyVisibility)
end

local RefreshOptions
local RefreshRuleList
local RefreshDifficultyMenu
local RefreshBarMenu

local function EnsureAddonState()
    ZoneBarsDB = ZoneBarsDB or {}
    CopyDefaults(ZoneBarsDB, DEFAULTS)

    if not editor then
        RebuildCatalog()
        ResetEditor()
    end
end

local function HasCheckedValue(values)
    for _, enabled in pairs(values or {}) do
        if enabled then
            return true
        end
    end

    return false
end

local function SetsAreEqual(left, right)
    for key, value in pairs(left or {}) do
        if (value and true or false) ~= ((right and right[key]) and true or false) then
            return false
        end
    end

    for key, value in pairs(right or {}) do
        if (value and true or false) ~= ((left and left[key]) and true or false) then
            return false
        end
    end

    return true
end

local function RulesAreIdentical(left, right)
    return (left.mode or HIDE_MODE) == (right.mode or HIDE_MODE)
        and (left.expansion or UNKNOWN_EXPANSION) == (right.expansion or UNKNOWN_EXPANSION)
        and (left.instanceType or RAID_TYPE) == (right.instanceType or RAID_TYPE)
        and (left.instanceName or "") == (right.instanceName or "")
        and (left.instanceMapID or 0) == (right.instanceMapID or 0)
        and (left.journalInstanceID or 0) == (right.journalInstanceID or 0)
        and SetsAreEqual(left.difficulties, right.difficulties)
        and SetsAreEqual(left.bars, right.bars)
end

local function FindDuplicateRule(candidate)
    for _, rule in ipairs(ZoneBarsDB.rules or {}) do
        if rule.id ~= candidate.id and RulesAreIdentical(rule, candidate) then
            return rule
        end
    end
end

local function RemoveDuplicateRules()
    local uniqueRules = {}

    for _, rule in ipairs(ZoneBarsDB.rules or {}) do
        local isDuplicate = false

        for _, existingRule in ipairs(uniqueRules) do
            if RulesAreIdentical(existingRule, rule) then
                isDuplicate = true
                break
            end
        end

        if not isDuplicate then
            uniqueRules[#uniqueRules + 1] = rule
        end
    end

    ZoneBarsDB.rules = uniqueRules
end

local function UpsertRule()
    RemoveDuplicateRules()

    if editor.instanceName == "" then
        print("ZoneBars: select a dungeon or raid first.")
        return
    end

    if not HasCheckedValue(editor.difficulties) then
        print("ZoneBars: select at least one difficulty.")
        return
    end

    if not HasCheckedValue(editor.bars) then
        print("ZoneBars: select at least one bar.")
        return
    end

    local rule = {
        id = editor.editingID,
        expansion = editor.expansion,
        instanceType = editor.instanceType,
        instanceName = editor.instanceName,
        instanceMapID = editor.instanceMapID,
        journalInstanceID = editor.journalInstanceID,
        mode = editor.mode or HIDE_MODE,
        difficulties = CopyTable(editor.difficulties),
        bars = CopyTable(editor.bars),
    }

    if FindDuplicateRule(rule) then
        print("ZoneBars: that exact rule already exists.")
        return
    end

    if rule.id then
        for index, existingRule in ipairs(ZoneBarsDB.rules) do
            if existingRule.id == rule.id then
                ZoneBarsDB.rules[index] = rule
                break
            end
        end
    else
        rule.id = ZoneBarsDB.nextRuleID or 1
        ZoneBarsDB.nextRuleID = rule.id + 1
        ZoneBarsDB.rules[#ZoneBarsDB.rules + 1] = rule
    end

    ResetEditor()
    RefreshOptions()
    RefreshRuleList()
    ApplyVisibility()
end

local function DeleteRule(ruleID)
    for index, rule in ipairs(ZoneBarsDB.rules) do
        if rule.id == ruleID then
            table.remove(ZoneBarsDB.rules, index)
            break
        end
    end

    if editor and editor.editingID == ruleID then
        ResetEditor()
    end

    RefreshOptions()
    RefreshRuleList()
    ApplyVisibility()
end

local function EditRule(ruleID)
    for _, rule in ipairs(ZoneBarsDB.rules) do
        if rule.id == ruleID then
            LoadRuleIntoEditor(rule)
            RefreshOptions()
            RefreshRuleList()
            return
        end
    end
end

local function AddDropDown(parent, name, label, point, relativeFrame, relativePoint, x, y, width, initializer)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint(point, relativeFrame, relativePoint, x, y)
    text:SetText(label)

    local dropDown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropDown:SetPoint("TOPLEFT", text, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dropDown, width)
    UIDropDownMenu_Initialize(dropDown, initializer)

    return text, dropDown
end

RefreshOptions = function()
    if not optionsFrame then
        return
    end

    SyncEditorDifficultiesToInstance()

    UIDropDownMenu_SetSelectedValue(optionsFrame.expansionDropDown, editor.expansion)
    UIDropDownMenu_SetText(optionsFrame.expansionDropDown, editor.expansion or UNKNOWN_EXPANSION)
    UIDropDownMenu_SetSelectedValue(optionsFrame.typeDropDown, editor.instanceType)
    UIDropDownMenu_SetText(optionsFrame.typeDropDown, TYPE_LABELS[editor.instanceType] or "Raids")
    UIDropDownMenu_SetSelectedValue(optionsFrame.modeDropDown, editor.mode)
    UIDropDownMenu_SetText(optionsFrame.modeDropDown, MODE_LABELS[editor.mode or HIDE_MODE])
    UIDropDownMenu_SetSelectedValue(optionsFrame.instanceDropDown, editor.instanceMapID or editor.instanceName)
    UIDropDownMenu_SetText(optionsFrame.instanceDropDown, editor.instanceName ~= "" and editor.instanceName or "None")
    UIDropDownMenu_SetText(optionsFrame.difficultyDropDown, GetDifficultyPickerLabel(editor.difficulties))
    UIDropDownMenu_SetText(optionsFrame.barDropDown, GetBarPickerLabel(editor.bars))

    optionsFrame.saveButton:SetText(editor.editingID and "Save Rule" or "Add Rule")

    if optionsFrame.saveButtonGlow then
        if editor.editingID then
            optionsFrame.saveButtonGlow:Show()
        else
            optionsFrame.saveButtonGlow:Hide()
        end
    end
end

RefreshRuleList = function()
    if not optionsFrame then
        return
    end

    local content = optionsFrame.ruleContent

    for _, row in ipairs(content.rows or {}) do
        row:Hide()
    end

    content.rows = content.rows or {}

    local previous

    if #ZoneBarsDB.rules == 0 then
        if not content.emptyText then
            content.emptyText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            content.emptyText:SetPoint("TOPLEFT", 4, -4)
            content.emptyText:SetWidth(520)
            content.emptyText:SetJustifyH("LEFT")
            content.emptyText:SetText("No rules added yet.")
        end

        content.emptyText:Show()
        content:SetHeight(34)
        return
    elseif content.emptyText then
        content.emptyText:Hide()
    end

    for index, rule in ipairs(ZoneBarsDB.rules) do
        local ruleID = rule.id
        local row = content.rows[index]

        if not row then
            row = CreateFrame("Frame", nil, content)
            row:SetSize(RULE_ROW_WIDTH, 34)

            row.highlight = CreateFrame("Frame", nil, row, "BackdropTemplate")
            row.highlight:SetPoint("TOPLEFT", row, "TOPLEFT", -2, 2)
            row.highlight:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 2, -2)
            row.highlight:SetBackdrop({
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 12,
            })
            row.highlight:SetBackdropBorderColor(1, 0.82, 0, 1)
            row.highlight:Hide()

            row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", 4, 0)
            row.text:SetWidth(450)
            row.text:SetJustifyH("LEFT")

            row.editButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.editButton:SetSize(58, 22)
            row.editButton:SetPoint("RIGHT", row, "RIGHT", -68, 0)
            row.editButton:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Edit rule")
                GameTooltip:Show()
            end)
            row.editButton:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            row.editButton:SetText("Edit")

            row.deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.deleteButton:SetSize(62, 22)
            row.deleteButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            row.deleteButton:SetText("Delete")

            content.rows[index] = row
        end

        row:ClearAllPoints()

        if previous then
            row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
        else
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -4)
        end

        row.text:SetText((MODE_LABELS[rule.mode or HIDE_MODE] or "Hide") .. " - " .. (rule.instanceName or "Unknown") .. " - " .. GetDifficultiesLabel(rule.difficulties) .. " - " .. GetBarsLabel(rule.bars))
        row.editButton:SetScript("OnClick", function()
            EditRule(ruleID)
        end)
        row.deleteButton:SetScript("OnClick", function()
            DeleteRule(ruleID)
        end)

        if editor and editor.editingID == ruleID then
            row.highlight:Show()
        else
            row.highlight:Hide()
        end

        row:Show()
        previous = row
    end

    content:SetHeight(math.max(34, #ZoneBarsDB.rules * 36))
end

RefreshDifficultyMenu = function()
    if not optionsFrame then
        return
    end

    if UIDropDownMenu_Refresh then
        UIDropDownMenu_Refresh(optionsFrame.difficultyDropDown, nil, 1)
    end
end

RefreshBarMenu = function()
    if not optionsFrame then
        return
    end

    if UIDropDownMenu_Refresh then
        UIDropDownMenu_Refresh(optionsFrame.barDropDown, nil, 1)
    end

    UIDropDownMenu_SetText(optionsFrame.barDropDown, GetBarPickerLabel(editor.bars))
end

local function ScheduleBarMenuRefresh()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, function()
            RefreshOptions()
            RefreshBarMenu()
        end)
    else
        RefreshOptions()
        RefreshBarMenu()
    end
end

local function CreateOptionsPanel()
    EnsureAddonState()

    local panel = CreateFrame("Frame", "ZoneBarsOptionsPanel", UIParent)
    panel.name = "ZoneBars"
    panel:Hide()
    optionsFrame = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ZoneBars")

    local editorTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    editorTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -18)
    editorTitle:SetText("Add or edit rule")

    local _, expansionDropDown = AddDropDown(panel, "ZoneBarsExpansionDropDown", "Expansion", "TOPLEFT", editorTitle, "BOTTOMLEFT", 0, -8, 190, function(_, level)
        local data = EnsureCatalog()

        for _, expansionName in ipairs(data.expansions) do
            local selectedExpansion = expansionName
            local info = UIDropDownMenu_CreateInfo()
            info.text = "   " .. selectedExpansion
            info.value = selectedExpansion
            info.func = function(button)
                editor.expansion = button.value
                SelectFirstAvailableInstance()
                RefreshOptions()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    panel.expansionDropDown = expansionDropDown

    local _, typeDropDown = AddDropDown(panel, "ZoneBarsTypeDropDown", "Content type", "TOPLEFT", editorTitle, "BOTTOMLEFT", 250, -8, 125, function(_, level)
        for _, instanceType in ipairs({ RAID_TYPE, DUNGEON_TYPE }) do
            local selectedType = instanceType
            local info = UIDropDownMenu_CreateInfo()
            info.text = "   " .. TYPE_LABELS[selectedType]
            info.value = selectedType
            info.func = function(button)
                editor.instanceType = button.value
                SelectFirstAvailableInstance()
                RefreshOptions()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    panel.typeDropDown = typeDropDown

    local _, modeDropDown = AddDropDown(panel, "ZoneBarsModeDropDown", "Rule mode", "TOPLEFT", editorTitle, "BOTTOMLEFT", 425, -8, 80, function(_, level)
        for _, mode in ipairs({ HIDE_MODE, SHOW_MODE }) do
            local selectedMode = mode
            local info = UIDropDownMenu_CreateInfo()
            info.text = "   " .. MODE_LABELS[selectedMode]
            info.value = selectedMode
            info.func = function(button)
                editor.mode = button.value
                RefreshOptions()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    panel.modeDropDown = modeDropDown

    local _, instanceDropDown = AddDropDown(panel, "ZoneBarsInstanceDropDown", "Instance", "TOPLEFT", expansionDropDown, "BOTTOMLEFT", 16, -16, 300, function(_, level)
        for _, instance in ipairs(GetAvailableInstances()) do
            local selectedInstance = instance
            local info = UIDropDownMenu_CreateInfo()
            info.text = "   " .. selectedInstance.name
            info.value = selectedInstance.mapID or selectedInstance.name
            info.func = function()
                editor.instanceName = selectedInstance.name
                editor.instanceMapID = selectedInstance.mapID
                editor.journalInstanceID = selectedInstance.journalInstanceID
                SyncEditorDifficultiesToInstance()
                RefreshOptions()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    panel.instanceDropDown = instanceDropDown

    local _, difficultyDropDown = AddDropDown(panel, "ZoneBarsDifficultyDropDown", "Difficulties", "TOPLEFT", expansionDropDown, "BOTTOMLEFT", 376, -16, 160, function(_, level)
        for _, difficulty in ipairs(GetAvailableDifficulties()) do
            local difficultyID = difficulty.id
            local info = UIDropDownMenu_CreateInfo()
            info.text = "   " .. difficulty.label
            info.value = difficultyID
            info.keepShownOnClick = true
            info.notCheckable = false
            info.isNotRadio = true
            info.isNotRadioButton = true
            info.checked = function()
                return editor.difficulties[difficultyID] and true or false
            end
            info.func = function()
                if difficultyID == 0 then
                    wipe(editor.difficulties)
                    editor.difficulties[0] = true
                else
                    editor.difficulties[0] = nil
                    editor.difficulties[difficultyID] = not editor.difficulties[difficultyID] or nil
                end

                RefreshOptions()
                RefreshDifficultyMenu()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    panel.difficultyDropDown = difficultyDropDown

    local barsLabel, barDropDown = AddDropDown(panel, "ZoneBarsBarDropDown", "Bars", "TOPLEFT", instanceDropDown, "BOTTOMLEFT", 16, -16, 180, function(_, level)
        for _, bar in ipairs(BAR_OPTIONS) do
            local barID = bar.id
            local info = UIDropDownMenu_CreateInfo()
            info.text = "   " .. bar.label
            info.keepShownOnClick = true
            info.notCheckable = false
            info.isNotRadio = true
            info.isNotRadioButton = true
            info.ignoreAsMenuSelection = true
            info.checked = function()
                return editor.bars[barID] and true or false
            end
            info.func = function()
                editor.bars[barID] = not editor.bars[barID] or nil
                ScheduleBarMenuRefresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    panel.barDropDown = barDropDown

    local barInfo = CreateFrame("Button", nil, panel, "UIPanelInfoButton")
    barInfo:SetPoint("LEFT", barsLabel, "RIGHT", 6, 0)
    barInfo:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Bar numbers vary by UI", 1, 1, 1)
        GameTooltip:AddLine("A numbered bar is matched against default UI frames and supported action bar addons. The same number may not represent the same physical bar in every setup; for example, ElvUI bar 6 is not necessarily the same as default UI bar 6 or Dominos bar 6.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    barInfo:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    panel.saveButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.saveButton:SetSize(100, 24)
    panel.saveButton:SetPoint("TOPLEFT", barDropDown, "BOTTOMLEFT", 16, -10)
    panel.saveButton:SetScript("OnClick", UpsertRule)

    panel.saveButtonGlow = CreateFrame("Frame", nil, panel.saveButton, "BackdropTemplate")
    panel.saveButtonGlow:SetPoint("TOPLEFT", panel.saveButton, "TOPLEFT", -3, 3)
    panel.saveButtonGlow:SetPoint("BOTTOMRIGHT", panel.saveButton, "BOTTOMRIGHT", 3, -3)
    panel.saveButtonGlow:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    panel.saveButtonGlow:SetBackdropBorderColor(1, 0.82, 0, 1)
    panel.saveButtonGlow:Hide()

    panel.newButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.newButton:SetSize(100, 24)
    panel.newButton:SetPoint("LEFT", panel.saveButton, "RIGHT", 8, 0)
    panel.newButton:SetText("New Rule")
    panel.newButton:SetScript("OnClick", function()
        ResetEditor()
        RefreshOptions()
        RefreshRuleList()
    end)

    local listTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    listTitle:SetPoint("TOPLEFT", panel.saveButton, "BOTTOMLEFT", 0, -18)
    listTitle:SetText("Current rules")

    local scrollFrame = CreateFrame("ScrollFrame", "ZoneBarsRuleScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", listTitle, "BOTTOMLEFT", 0, -8)
    scrollFrame:SetSize(RULE_SCROLL_WIDTH, 190)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(RULE_ROW_WIDTH, 190)
    scrollFrame:SetScrollChild(content)
    panel.ruleContent = content

    local registeredCategory = false

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)

        if ok and category then
            ok = pcall(Settings.RegisterAddOnCategory, category)

            if ok then
                panel.category = category
                registeredCategory = true
            end
        end
    end

    if not registeredCategory and InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    RefreshOptions()
    RefreshRuleList()

    return panel
end

local function MigrateOldSettings()
    if ZoneBarsDB.rules and #ZoneBarsDB.rules > 0 then
        return
    end

    if not ZoneBarsDB.instanceName or ZoneBarsDB.instanceName == "" then
        return
    end

    ZoneBarsDB.rules = {
        {
            id = ZoneBarsDB.nextRuleID or 1,
            expansion = ZoneBarsDB.expansion or UNKNOWN_EXPANSION,
            instanceType = ZoneBarsDB.instanceType or RAID_TYPE,
            instanceName = ZoneBarsDB.instanceName,
            instanceMapID = ZoneBarsDB.instanceMapID,
            journalInstanceID = ZoneBarsDB.journalInstanceID,
            mode = HIDE_MODE,
            difficulties = {
                [ZoneBarsDB.difficultyID or 16] = true,
            },
            bars = CopyTable(ZoneBarsDB.bars or DEFAULT_BARS),
        },
    }
    ZoneBarsDB.nextRuleID = ZoneBarsDB.rules[1].id + 1
end

SLASH_ZONEBARS1 = "/zonebars"
SlashCmdList.ZONEBARS = function()
    EnsureAddonState()

    if not optionsFrame then
        CreateOptionsPanel()
    end

    RebuildCatalog()
    RefreshOptions()
    RefreshRuleList()

    if Settings and Settings.OpenToCategory and optionsFrame.category then
        Settings.OpenToCategory(optionsFrame.category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(optionsFrame)
    elseif SettingsPanel and SettingsPanel.Open then
        SettingsPanel:Open()
        optionsFrame:Show()
    else
        optionsFrame:Show()
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        EnsureAddonState()
        MigrateOldSettings()
        RemoveDuplicateRules()
        RebuildCatalog()
        ResetEditor()
        CreateOptionsPanel()
        QueueUpdate()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" and pendingUpdate then
        ApplyVisibility()
        return
    end

    if ZoneBarsDB then
        QueueUpdate()
    end
end)
