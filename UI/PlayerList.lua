local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local ROW_HEIGHT = 18
local PADDING = 8
local MIN_HEIGHT = 40

local function CreatePlayerRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, -(PADDING + (index - 1) * ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING, -(PADDING + (index - 1) * ROW_HEIGHT))

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.name:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.name:SetTextColor(1, 1, 1, 1)

    row.roll = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.roll:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.roll:SetTextColor(1, 0.82, 0, 1)

    return row
end

local function RefreshPlayerList(frame)
    local players = addon.session and addon.session.players or {}

    for _, row in ipairs(frame.rows) do
        row:Hide()
    end

    for i, player in ipairs(players) do
        if not frame.rows[i] then
            frame.rows[i] = CreatePlayerRow(frame, i)
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
            row.roll:SetText(tostring(player.roll))
        else
            row.roll:SetText("")
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -(PADDING + (i - 1) * ROW_HEIGHT))
        row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -(PADDING + (i - 1) * ROW_HEIGHT))
        row:Show()
    end

    local contentHeight = PADDING * 2 + math.max(1, #players) * ROW_HEIGHT
    frame:SetHeight(math.max(MIN_HEIGHT, contentHeight))
end

local function CreatePlayerList(self, parentFrame)
    local frame = CreateFrame("Frame", "SlashBreakGamblingPlayerList", parentFrame, "BackdropTemplate")
    frame:SetPoint("TOPRIGHT", parentFrame, "TOPLEFT", -4, 0)
    frame:SetWidth(160)
    frame:SetHeight(MIN_HEIGHT)

    frame:SetFrameStrata("HIGH")

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetBackdropBorderColor(1, 1, 1, 1)

    frame.rows = {}

    return frame
end

UI.CreatePlayerList = CreatePlayerList
UI.RefreshPlayerList = RefreshPlayerList
