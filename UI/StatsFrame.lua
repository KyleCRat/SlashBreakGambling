local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local ROW_HEIGHT = 18
local PADDING = 8
local SECTION_SPACING = 6
local MIN_HEIGHT = 40
local MAX_DISPLAY = 20
local CHAT_MAX_LENGTH = 255
local DIVIDER_HEIGHT = 2

local COLOR_GOLD = { 1, 0.82, 0 }
local COLOR_SILVER = { 0.75, 0.75, 0.75 }
local COLOR_BRONZE = { 0.8, 0.5, 0.2 }
local COLOR_GREEN = { 0.4, 1, 0.4 }
local COLOR_RED = { 1, 0.4, 0.4 }

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

local function ShortName(fullName)
    return fullName:match("^([^%-]+)") or fullName
end

local function FormatGold(amount)
    local formatted = BreakUpLargeNumbers(math.abs(amount))

    if amount >= 0 then
        return formatted .. "g"
    end

    return "-" .. formatted .. "g"
end

local function GetRowColor(rank, net)
    if net < 0 then
        return COLOR_RED
    end

    if rank == 1 then
        return COLOR_GOLD
    end

    if rank == 2 then
        return COLOR_SILVER
    end

    if rank == 3 then
        return COLOR_BRONZE
    end

    return COLOR_GREEN
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
        table.insert(lines, addon.ABBR .. " " .. entry.name .. " " .. FormatGold(entry.net))
    end

    table.insert(lines, addon.ABBR .. " ----------")

    for i = loseCount, 1, -1 do
        local entry = losers[i]
        table.insert(lines, addon.ABBR .. " " .. entry.name .. " " .. FormatGold(entry.net))
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

local function MergeSorted(winners, losers)
    local all = {}

    for _, entry in ipairs(winners) do
        table.insert(all, entry)
    end

    for _, entry in ipairs(losers) do
        table.insert(all, entry)
    end

    table.sort(all, function(a, b)
        return a.net > b.net
    end)

    return all
end

local function RefreshStatsFrame(frame)
    for _, row in ipairs(frame.rows) do
        row:Hide()
    end

    frame.divider:Hide()

    local winners, losers = addon:GetSortedStats()
    local all = MergeSorted(winners, losers)
    local displayCount = math.min(MAX_DISPLAY, #all)
    local yOffset = PADDING

    -- Header
    PositionAtOffset(frame, frame.headerLabel, yOffset)
    yOffset = yOffset + ROW_HEIGHT + SECTION_SPACING

    if displayCount > 0 then
        local dividerPlaced = false

        for i = 1, displayCount do
            local entry = all[i]

            if not dividerPlaced and entry.net < 0 then
                yOffset = yOffset + 4
                frame.divider:ClearAllPoints()
                frame.divider:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -yOffset)
                frame.divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -yOffset)
                frame.divider:Show()
                yOffset = yOffset + DIVIDER_HEIGHT + SECTION_SPACING - 1
                dividerPlaced = true
            end

            if not frame.rows[i] then
                frame.rows[i] = CreateRow(frame)
            end

            local row = frame.rows[i]
            local color = GetRowColor(i, entry.net)
            row.name:SetText(i .. ". " .. ShortName(entry.name))
            row.name:SetTextColor(color[1], color[2], color[3], 1)
            row.amount:SetText(FormatGold(entry.net))
            row.amount:SetTextColor(color[1], color[2], color[3], 1)
            PositionAtOffset(frame, row, yOffset)
            row:Show()
            yOffset = yOffset + ROW_HEIGHT
        end

        yOffset = yOffset + SECTION_SPACING
        frame.emptyLabel:Hide()
    else
        PositionAtOffset(frame, frame.emptyLabel, yOffset)
        frame.emptyLabel:Show()
        yOffset = yOffset + ROW_HEIGHT + SECTION_SPACING
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

    frame.emptyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.emptyLabel:SetJustifyH("CENTER")
    frame.emptyLabel:SetText("No stats recorded yet.")
    frame.emptyLabel:SetTextColor(0.5, 0.5, 0.5, 1)

    frame.divider = frame:CreateTexture(nil, "ARTWORK")
    frame.divider:SetHeight(DIVIDER_HEIGHT)
    frame.divider:SetColorTexture(0.3, 0.3, 0.3, 1)

    frame.rows = {}

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
