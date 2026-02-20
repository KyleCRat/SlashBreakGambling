local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local function OnClick()
    addon:RequestRolls()
end

local function UpdateRequestRollsButton(button, state)
    if state == STATES.CLOSED and addon:IsSessionLeader() and addon:HasUnrolledPlayers() then
        button:Show()
    else
        button:Hide()
    end
end

local function CreateRequestRollsButton(self, parentFrame)
    local button = UI.Partials.CreateStyledButton(
        parentFrame,
        "SlashBreakGamblingRequestRollsButton",
        parentFrame:GetWidth() - 20,
        28,
        "Request Rolls"
    )

    button:SetPoint("TOP", parentFrame, "TOP", 0, -108)
    button:SetScript("OnClick", OnClick)
    button:Hide()

    return button
end

UI.CreateRequestRollsButton = CreateRequestRollsButton
UI.UpdateRequestRollsButton = UpdateRequestRollsButton
