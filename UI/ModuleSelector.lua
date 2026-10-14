local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES
local ROW_HEIGHT = 28

local function GetSelectedLabel()
    local key = addon.db:Get("session", "selectedModule")

    for _, entry in ipairs(addon.GameModules) do
        if entry.key == key then
            return entry.label
        end
    end

    return key
end

local function UpdateSelector(button)
    button.text:SetText(GetSelectedLabel())
end

local function SetEnabled(button, enabled)
    if enabled then
        button:Enable()
        button.text:SetTextColor(1, 0.82, 0, 1)
    else
        button:Disable()
        button.text:SetTextColor(0.5, 0.5, 0.5, 1)
    end
end

local function HideDropdown(button)
    if button.dropdown then
        button.dropdown:Hide()
    end
end

local DROPDOWN_PADDING = 10

local function UpdateRowStyle(row)
    if row.isSelected then
        row.text:SetTextColor(1, 1, 1, 1)
        row:SetBackdropColor(0.3, 0.25, 0, 1)
        row:SetBackdropBorderColor(1, 0.82, 0, 1)
    else
        row.text:SetTextColor(1, 0.82, 0, 1)
        row:SetBackdropColor(0.15, 0.15, 0.15, 1)
        row:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end
end

local function CreateModuleRow(button, width)
    local row = UI.Partials.CreateStyledButton(button.dropdown, nil, width, ROW_HEIGHT, "")

    row:SetScript("OnClick", function(self)
        addon.db:Set("session", "selectedModule", self.entry.key)
        addon:SendMessage("SBG_MODULE_CHANGED", self.entry.key)
        HideDropdown(button)
    end)

    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 1)
        self:SetBackdropBorderColor(1, 0.82, 0, 1)

        local description = self.entry.config.description

        if description then
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("LEFT", self, "RIGHT", 16, 0)
            GameTooltip:SetText(self.entry.label, 1, 0.82, 0, 1)
            GameTooltip:AddLine(description, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)

    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        UpdateRowStyle(self)
    end)

    row:SetScript("OnHide", function(self)
        if GameTooltip:IsOwned(self) then
            GameTooltip:Hide()
        end
    end)

    return row
end

local function ShowDropdown(button)
    local dropdown = button.dropdown

    for _, row in ipairs(dropdown.rows) do
        row:Hide()
    end

    local modules = addon.GameModules
    local selectedKey = addon.db:Get("session", "selectedModule")
    local rowWidth = dropdown:GetWidth() - (DROPDOWN_PADDING * 2)

    for i, entry in ipairs(modules) do
        local row = dropdown.rows[i]

        if not row then
            row = CreateModuleRow(button, rowWidth)
            dropdown.rows[i] = row
        end

        row.entry = entry
        row.isSelected = entry.key == selectedKey
        row:SetWidth(rowWidth)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", dropdown, "TOPLEFT",
            DROPDOWN_PADDING, -DROPDOWN_PADDING - (i - 1) * ROW_HEIGHT)
        row.text:SetPoint("CENTER", 0, 0)
        row.text:SetText(entry.label)
        UpdateRowStyle(row)
        row:Show()
    end

    dropdown:SetHeight(#modules * ROW_HEIGHT + (DROPDOWN_PADDING * 2))
    dropdown:Show()
end

local function ToggleDropdown(button)
    if button.dropdown:IsShown() then
        HideDropdown(button)
    else
        ShowDropdown(button)
    end
end

local function UpdateModuleSelector(button, state)
    local enabled = state == STATES.IDLE

    SetEnabled(button, enabled)

    if not enabled then
        HideDropdown(button)
    end
end

local function CreateModuleSelector(self, parentFrame, anchorElement, yOffset, width)
    local button = UI.Partials.CreateStyledButton(
        parentFrame,
        "SlashBreakGamblingModuleSelector",
        width,
        ROW_HEIGHT,
        GetSelectedLabel()
    )

    button:SetPoint("TOPLEFT", anchorElement, "BOTTOMLEFT", 0, yOffset)

    local dropdown = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    dropdown:SetWidth(width)
    dropdown:SetFrameStrata("TOOLTIP")
    dropdown:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, 0)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 1)
    dropdown:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    dropdown:Hide()
    dropdown.rows = {}

    button.dropdown = dropdown

    button:SetScript("OnClick", function()
        ToggleDropdown(button)
    end)

    dropdown:SetScript("OnHide", function()
        for _, row in ipairs(dropdown.rows) do
            row:Hide()
        end
    end)

    parentFrame:HookScript("OnHide", function()
        HideDropdown(button)
    end)

    return button
end

UI.CreateModuleSelector = CreateModuleSelector
UI.UpdateModuleSelector = UpdateModuleSelector
UI.UpdateModuleSelectorLabel = UpdateSelector
