local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local GUILD_CUT_VALUES = { 0, 5, 10, 25, 50, 75 }

local function FormatPercent(value)
    return value .. "%"
end

local function FindNextPreset(current)
    for i, value in ipairs(GUILD_CUT_VALUES) do
        if value > current then
            return value
        end
    end

    return GUILD_CUT_VALUES[1]
end

local function SetGuildCut(container, value)
    value = math.max(0, math.min(100, math.floor(value)))
    addon.db:Set("session", "guildCut", value)
    container.editBox:SetText(FormatPercent(value))
end

local function UpdateGuildCutButton(container, state)
    if state == STATES.IDLE then
        container:Show()
    else
        container:Hide()
    end
end

local function CreateGuildCutButton(self, parentFrame, anchorElement, yOffset)
    local containerWidth = parentFrame:GetWidth() - 20
    local gap = 6
    local buttonWidth = math.floor(containerWidth * 0.5)
    local editBoxWidth = containerWidth - buttonWidth - gap

    local container = CreateFrame("Frame", nil, parentFrame)
    container:SetSize(containerWidth, 28)
    container:SetPoint("TOPLEFT", anchorElement, "BOTTOMLEFT", 0, yOffset)

    local button = UI.Partials.CreateStyledButton(
        container,
        "SlashBreakGamblingGuildCutButton",
        buttonWidth,
        28,
        "Guild Cut"
    )
    button:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnClick", function(btn, mouseButton)
        if mouseButton == "RightButton" then
            SetGuildCut(container, 0)

            return
        end

        local current = addon.db:Get("session", "guildCut")
        local nextValue = FindNextPreset(current)
        SetGuildCut(container, nextValue)
    end)

    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetSize(editBoxWidth, 28)
    editBox:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("CENTER")
    editBox:SetFontObject("GameFontNormal")
    editBox:SetTextInsets(4, 4, 0, 0)
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    editBox:SetBackdropColor(0, 0, 0, 1)
    editBox:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    editBox:SetTextColor(1, 1, 1, 1)

    local currentValue = addon.db:Get("session", "guildCut")
    editBox:SetText(FormatPercent(currentValue))

    editBox:SetScript("OnEditFocusGained", function(self)
        local value = addon.db:Get("session", "guildCut")
        self:SetText(tostring(value))
        self:HighlightText()
    end)

    local committing = false

    local function CommitEditBox(self)
        if committing then
            return
        end

        committing = true

        local value = tonumber(self:GetText()) or 0
        SetGuildCut(container, value)
        self:ClearFocus()

        committing = false
    end

    editBox:SetScript("OnEnterPressed", CommitEditBox)
    editBox:SetScript("OnEditFocusLost", CommitEditBox)

    container.button = button
    container.editBox = editBox

    return container
end

UI.CreateGuildCutButton = CreateGuildCutButton
UI.UpdateGuildCutButton = UpdateGuildCutButton
