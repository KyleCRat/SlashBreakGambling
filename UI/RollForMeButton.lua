local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local function OnClick()
    addon:RollForMe()
end

local function UpdateRollForMeButton(button, state)
    if state == STATES.CLOSED and addon:CanRollForMe() then
        button:Show()
    else
        button:Hide()
    end
end

local function CreateRollForMeButton(self, parentFrame, anchorElement, yOffset)
    local button = UI.Partials.CreateStyledButton(
        parentFrame,
        "SlashBreakGamblingRollForMeButton",
        parentFrame:GetWidth() - 20,
        28,
        "Roll for Me"
    )

    button:SetPoint("TOP", anchorElement, "BOTTOM", 0, yOffset)
    button:SetScript("OnClick", OnClick)
    button:Hide()

    return button
end

UI.CreateRollForMeButton = CreateRollForMeButton
UI.UpdateRollForMeButton = UpdateRollForMeButton
