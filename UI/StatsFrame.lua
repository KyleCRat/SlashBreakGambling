local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local ROW_HEIGHT = 18
local PADDING = 8
local SECTION_SPACING = 6
local MIN_HEIGHT = 40
local MAX_DISPLAY = 10
local CHAT_MAX_LENGTH = 255

local function PositionAtOffset(frame, element, yOffset)
    element:ClearAllPoints()
    element:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -yOffset)
    element:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -yOffset)
end

local function CreateRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.name:SetPoint("LEFT", row, "LEFT", 0, 0)

    row.amount = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.amount:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    return row
end

local function FormatGold(amount)
    local formatted = BreakUpLargeNumbers(math.abs(amount))

    if amount >= 0 then
        return formatted .. "g"
    end

    return "-" .. formatted .. "g"
end

local function GetChatChannel()
    if IsInRaid() then
        return "RAID"
    end

    if IsInGroup() then
        return "PARTY"
    end

    return nil
end

local function BuildReportLines(winners, losers, maxEntries)
    local lines = {}
    local winCount = math.min(maxEntries, #winners)
    local loseCount = math.min(maxEntries, #losers)

    for i = 1, winCount do
        local entry = winners[i]
        table.insert(lines, addon.ABBR .. " " .. i .. ". " .. entry.name .. " " .. FormatGold(entry.net))
    end

    for i = 1, loseCount do
        local entry = losers[i]
        table.insert(lines, addon.ABBR .. " " .. (winCount + i) .. ". " .. entry.name .. " " .. FormatGold(entry.net))
    end

    return lines
end


local function SendLinesIndividually(lines)
    local channel = GetChatChannel()

    if not channel then
        for _, line in ipairs(lines) do
            addon:Print(line)
        end

        return
    end

    for _, line in ipairs(lines) do
        SendChatMessage(line, channel)
    end
end

local function OnReportTop3Click()
    local winners, losers = addon:GetSortedStats()
    local lines = BuildReportLines(winners, losers, 3)

    if #lines == 0 then
        addon:Print("No stats to report.")

        return
    end

    SendLinesIndividually(lines)
end

local function SendLine(msg, channel)
    if channel then
        SendChatMessage(msg, channel)
    else
        addon:Print(msg)
    end
end

local function SendBatchedSection(entries, header, channel)
    SendLine(addon.ABBR .. " " .. header, channel)

    local batch = ""

    for i, entry in ipairs(entries) do
        local part = i .. ". " .. entry.name .. " " .. FormatGold(entry.net)

        if batch == "" then
            batch = part
        elseif #batch + #part + 2 > CHAT_MAX_LENGTH then
            SendLine(batch, channel)
            batch = part
        else
            batch = batch .. "  " .. part
        end
    end

    if batch ~= "" then
        SendLine(batch, channel)
    end
end

local function OnReportAllClick()
    local winners, losers = addon:GetSortedStats()

    if #winners == 0 and #losers == 0 then
        addon:Print("No stats to report.")

        return
    end

    local channel = GetChatChannel()

    if #winners > 0 then
        SendBatchedSection(winners, "Winners:", channel)
    end

    if #losers > 0 then
        SendBatchedSection(losers, "Losers:", channel)
    end
end

local function RefreshStatsFrame(frame)
    for _, row in ipairs(frame.winnerRows) do
        row:Hide()
    end

    for _, row in ipairs(frame.loserRows) do
        row:Hide()
    end

    local winners, losers = addon:GetSortedStats()
    local yOffset = PADDING

    -- Header
    PositionAtOffset(frame, frame.headerLabel, yOffset)
    yOffset = yOffset + ROW_HEIGHT + SECTION_SPACING

    -- Winners section
    local winnerCount = math.min(MAX_DISPLAY, #winners)

    if winnerCount > 0 then
        PositionAtOffset(frame, frame.winnersLabel, yOffset)
        frame.winnersLabel:Show()
        yOffset = yOffset + ROW_HEIGHT

        for i = 1, winnerCount do
            if not frame.winnerRows[i] then
                frame.winnerRows[i] = CreateRow(frame)
            end

            local row = frame.winnerRows[i]
            row.name:SetText(i .. ". " .. winners[i].name)
            row.name:SetTextColor(0.4, 1, 0.4, 1)
            row.amount:SetText(FormatGold(winners[i].net))
            row.amount:SetTextColor(0.4, 1, 0.4, 1)
            PositionAtOffset(frame, row, yOffset)
            row:Show()
            yOffset = yOffset + ROW_HEIGHT
        end

        yOffset = yOffset + SECTION_SPACING
    else
        frame.winnersLabel:Hide()
    end

    -- Losers section
    local loserCount = math.min(MAX_DISPLAY, #losers)

    if loserCount > 0 then
        PositionAtOffset(frame, frame.losersLabel, yOffset)
        frame.losersLabel:Show()
        yOffset = yOffset + ROW_HEIGHT

        for i = 1, loserCount do
            if not frame.loserRows[i] then
                frame.loserRows[i] = CreateRow(frame)
            end

            local row = frame.loserRows[i]
            row.name:SetText(i .. ". " .. losers[i].name)
            row.name:SetTextColor(1, 0.4, 0.4, 1)
            row.amount:SetText(FormatGold(losers[i].net))
            row.amount:SetTextColor(1, 0.4, 0.4, 1)
            PositionAtOffset(frame, row, yOffset)
            row:Show()
            yOffset = yOffset + ROW_HEIGHT
        end

        yOffset = yOffset + SECTION_SPACING
    else
        frame.losersLabel:Hide()
    end

    -- No data message
    if winnerCount == 0 and loserCount == 0 then
        PositionAtOffset(frame, frame.emptyLabel, yOffset)
        frame.emptyLabel:Show()
        yOffset = yOffset + ROW_HEIGHT + SECTION_SPACING
    else
        frame.emptyLabel:Hide()
    end

    -- Buttons
    frame.reportTop3Button:ClearAllPoints()
    frame.reportTop3Button:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -yOffset)
    frame.reportTop3Button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -yOffset)
    yOffset = yOffset + 28 + 4

    frame.reportAllButton:ClearAllPoints()
    frame.reportAllButton:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -yOffset)
    frame.reportAllButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -yOffset)
    yOffset = yOffset + 28 + PADDING

    frame:SetHeight(math.max(MIN_HEIGHT, yOffset))
end

local function CreateStatsFrame(self, parentFrame)
    local frame = CreateFrame("Frame", "SlashBreakGamblingStatsFrame", parentFrame, "BackdropTemplate")
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

    frame.headerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.headerLabel:SetJustifyH("CENTER")
    frame.headerLabel:SetText("Statistics")
    frame.headerLabel:SetTextColor(1, 0.82, 0, 1)

    frame.winnersLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.winnersLabel:SetJustifyH("LEFT")
    frame.winnersLabel:SetText("Winners")
    frame.winnersLabel:SetTextColor(0.4, 1, 0.4, 1)

    frame.losersLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.losersLabel:SetJustifyH("LEFT")
    frame.losersLabel:SetText("Losers")
    frame.losersLabel:SetTextColor(1, 0.4, 0.4, 1)

    frame.emptyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.emptyLabel:SetJustifyH("CENTER")
    frame.emptyLabel:SetText("No stats recorded yet.")
    frame.emptyLabel:SetTextColor(0.5, 0.5, 0.5, 1)

    frame.winnerRows = {}
    frame.loserRows = {}

    frame.reportTop3Button = UI.Partials.CreateStyledButton(
        frame, "SlashBreakGamblingReportTop3", 200, 24, "Report Top 3")
    frame.reportTop3Button:SetScript("OnClick", OnReportTop3Click)

    frame.reportAllButton = UI.Partials.CreateStyledButton(
        frame, "SlashBreakGamblingReportAll", 200, 24, "Report All")
    frame.reportAllButton:SetScript("OnClick", OnReportAllClick)

    frame:Hide()

    return frame
end

UI.CreateStatsFrame = CreateStatsFrame
UI.RefreshStatsFrame = RefreshStatsFrame
