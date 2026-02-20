local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local ROW_HEIGHT = 18
local HEADER_HEIGHT = 18
local PADDING = 8
local MIN_HEIGHT = 40

local function PositionAtOffset(frame, element, yOffset)
    element:ClearAllPoints()
    element:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -yOffset)
    element:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -yOffset)
end

local function CreatePlayerRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.name:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.name:SetTextColor(1, 1, 1, 1)

    row.roll = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.roll:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.roll:SetTextColor(1, 0.82, 0, 1)

    return row
end

local function SortPlayers(players)
    local rolled = {}
    local unrolled = {}

    for _, player in ipairs(players) do
        if player.roll then
            table.insert(rolled, player)
        else
            table.insert(unrolled, player)
        end
    end

    table.sort(rolled, function(a, b)
        return a.roll > b.roll
    end)

    local sorted = {}

    for _, player in ipairs(rolled) do
        table.insert(sorted, player)
    end

    for _, player in ipairs(unrolled) do
        table.insert(sorted, player)
    end

    return sorted
end

local function GetModuleLabel()
    local key = addon.session and addon.session.moduleName

    if not key then
        return ""
    end

    for _, entry in ipairs(addon.GameModules) do
        if entry.key == key then
            return entry.label
        end
    end

    return key
end

local function FormatResultLine(result)
    if not result or result.tie then
        return nil
    end

    return result.winner .. " won " .. BreakUpLargeNumbers(result.amount) .. " |TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
end

local function RefreshPlayerList(frame)
    local session = addon.session
    local players = session and session.players or {}
    local sorted = SortPlayers(players)

    -- Hide all reusable rows
    for _, row in ipairs(frame.rows) do
        row:Hide()
    end

    local yOffset = PADDING

    -- Header: module name
    if session then
        frame.headerLabel:SetText(GetModuleLabel())
        frame.headerLabel:Show()
        PositionAtOffset(frame, frame.headerLabel, yOffset)
        yOffset = yOffset + HEADER_HEIGHT

        frame.goldLabel:SetText("for " .. BreakUpLargeNumbers(math.floor(session.goldAmount)) .. " |TInterface\\MoneyFrame\\UI-GoldIcon:0|t")
        frame.goldLabel:Show()
        PositionAtOffset(frame, frame.goldLabel, yOffset)
        yOffset = yOffset + HEADER_HEIGHT + PADDING

        -- Result line
        local resultLine = FormatResultLine(session.lastResult)

        if resultLine then
            frame.resultLabel:SetText(resultLine)
            frame.resultLabel:Show()
            PositionAtOffset(frame, frame.resultLabel, yOffset)
            yOffset = yOffset + HEADER_HEIGHT + PADDING
        else
            frame.resultLabel:Hide()
        end
    else
        frame.headerLabel:Hide()
        frame.goldLabel:Hide()
        frame.resultLabel:Hide()
    end

    -- Player rows
    for i, player in ipairs(sorted) do
        if not frame.rows[i] then
            frame.rows[i] = CreatePlayerRow(frame)
        end

        local row = frame.rows[i]
        row.name:SetText(player.name)

        local color = RAID_CLASS_COLORS[player.classFile]

        if color then
            row.name:SetTextColor(color.r, color.g, color.b, 1)
        else
            row.name:SetTextColor(1, 1, 1, 1)
        end

        if player.roll then
            row.roll:SetText(BreakUpLargeNumbers(player.roll))
        else
            row.roll:SetText("")
        end

        PositionAtOffset(frame, row, yOffset + (i - 1) * ROW_HEIGHT)
        row:Show()
    end

    local rowsHeight = math.max(1, #sorted) * ROW_HEIGHT
    local totalHeight = yOffset + rowsHeight + PADDING
    frame:SetHeight(math.max(MIN_HEIGHT, totalHeight))
end

local function CreatePlayerList(self, parentFrame)
    local frame = CreateFrame("Frame", "SlashBreakGamblingPlayerList", parentFrame, "BackdropTemplate")
    frame:SetPoint("TOPRIGHT", parentFrame, "TOPLEFT", -4, 0)
    frame:SetWidth(240)
    frame:SetHeight(MIN_HEIGHT)

    frame:SetFrameStrata("HIGH")

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.15, 0.15, 0.15, 1)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    frame.headerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.headerLabel:SetJustifyH("CENTER")
    frame.headerLabel:SetTextColor(1, 0.82, 0, 1)
    frame.headerLabel:Hide()

    frame.goldLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.goldLabel:SetJustifyH("CENTER")
    frame.goldLabel:SetTextColor(1, 1, 1, 1)
    frame.goldLabel:Hide()

    frame.resultLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.resultLabel:SetJustifyH("CENTER")
    frame.resultLabel:SetTextColor(0.4, 1, 0.4, 1)
    frame.resultLabel:Hide()

    frame.rows = {}

    return frame
end

UI.CreatePlayerList = CreatePlayerList
UI.RefreshPlayerList = RefreshPlayerList
