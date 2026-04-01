local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local function GetButtonText()
    local playerList = UI.frame and UI.frame.playerList

    if playerList and playerList:IsShown() then
        return "Hide Player List"
    end

    return "Show Player List"
end

local function OnClick(button)
    local playerList = UI.frame and UI.frame.playerList

    if not playerList then
        return
    end

    local showing = not playerList:IsShown()
    playerList:SetShown(showing)

    if showing then
        local statsFrame = UI.frame.statsFrame

        if statsFrame and statsFrame:IsShown() then
            statsFrame:Hide()

            if UI.frame.statsButton then
                UI.frame.statsButton.text:SetText("Show Stats")
            end
        end
    end

    button.text:SetText(GetButtonText())
end

local function UpdateTogglePlayerListButton(button, state)
    if state == STATES.IDLE then
        button:Show()
    else
        button:Hide()
    end

    button.text:SetText(GetButtonText())
end

local function CreateTogglePlayerListButton(self, parentFrame, anchorElement, yOffset)
    local button = UI.Partials.CreateStyledButton(
        parentFrame,
        "SlashBreakGamblingTogglePlayerListButton",
        parentFrame:GetWidth() - 20,
        28,
        GetButtonText()
    )

    button:SetPoint("TOP", anchorElement, "BOTTOM", 0, yOffset)
    button:SetScript("OnClick", OnClick)

    return button
end

UI.CreateTogglePlayerListButton = CreateTogglePlayerListButton
UI.UpdateTogglePlayerListButton = UpdateTogglePlayerListButton
