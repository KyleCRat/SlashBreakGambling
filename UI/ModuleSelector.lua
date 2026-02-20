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

local function ShowDropdown(button)
    local dropdown = button.dropdown

    -- Rebuild rows each open so newly registered modules appear
    for _, row in ipairs(dropdown.rows) do
        row:Hide()
    end

    dropdown.rows = {}

    local modules = addon.GameModules
    local selectedKey = addon.db:Get("session", "selectedModule")
    local rowWidth = dropdown:GetWidth() - (DROPDOWN_PADDING * 2)

    for i, entry in ipairs(modules) do
        local row = UI.Partials.CreateStyledButton(
            dropdown,
            nil,
            rowWidth,
            ROW_HEIGHT,
            entry.label
        )

        row:SetPoint("TOPLEFT", dropdown, "TOPLEFT",
            DROPDOWN_PADDING, -DROPDOWN_PADDING - (i - 1) * ROW_HEIGHT)

        if entry.key == selectedKey then
            row.isSelected = true
            row.text:SetTextColor(1, 1, 1, 1)
            row:SetBackdropColor(0.3, 0.25, 0, 1)
            row:SetBackdropBorderColor(1, 0.82, 0, 1)

            row:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0.3, 0.25, 0, 1)
                self:SetBackdropBorderColor(1, 0.82, 0, 1)
            end)
        end

        local key = entry.key

        row:SetScript("OnClick", function()
            addon.db:Set("session", "selectedModule", key)
            addon:SendMessage("SBG_MODULE_CHANGED", key)
            HideDropdown(button)
        end)

        dropdown.rows[i] = row
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

    -- Hide dropdown when clicking outside
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
