local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local function GetButtonText()
    local statsFrame = UI.frame and UI.frame.statsFrame

    if statsFrame and statsFrame:IsShown() then
        return "Hide Stats"
    end

    return "Show Stats"
end

local function OnClick(button)
    local statsFrame = UI.frame and UI.frame.statsFrame
    local playerList = UI.frame and UI.frame.playerList

    if not statsFrame then
        return
    end

    if statsFrame:IsShown() then
        statsFrame:Hide()
    else
        if playerList and playerList:IsShown() then
            playerList:Hide()

            if UI.frame.togglePlayerListButton then
                UI.frame.togglePlayerListButton.text:SetText("Show Player List")
            end
        end

        statsFrame:Show()
        UI.RefreshStatsFrame(statsFrame)
    end

    button.text:SetText(GetButtonText())
end

local function UpdateStatsButton(button, state)
    if state == STATES.IDLE then
        button:Show()
    else
        button:Hide()
    end

    button.text:SetText(GetButtonText())
end

local function CreateStatsButton(self, parentFrame, anchorElement, yOffset)
    local button = UI.Partials.CreateStyledButton(
        parentFrame,
        "SlashBreakGamblingStatsButton",
        parentFrame:GetWidth() - 20,
        28,
        "Show Stats"
    )

    button:SetPoint("TOP", anchorElement, "BOTTOM", 0, yOffset)
    button:SetScript("OnClick", OnClick)

    return button
end

UI.CreateStatsButton = CreateStatsButton
UI.UpdateStatsButton = UpdateStatsButton
