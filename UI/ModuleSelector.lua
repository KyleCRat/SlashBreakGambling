local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

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

local function OnClick()
    addon:CycleGameModule()
end

local function UpdateModuleSelector(button, state)
    SetEnabled(button, state == STATES.IDLE)
end

local function CreateModuleSelector(self, parentFrame)
    local button = UI.Partials.CreateStyledButton(
        parentFrame,
        "SlashBreakGamblingModuleSelector",
        parentFrame:GetWidth() - 20,
        28,
        GetSelectedLabel()
    )

    button:SetPoint("TOP", parentFrame, "TOP", 0, -10)

    button:SetScript("OnClick", OnClick)

    return button
end

UI.CreateModuleSelector = CreateModuleSelector
UI.UpdateModuleSelector = UpdateModuleSelector
UI.UpdateModuleSelectorLabel = UpdateSelector
