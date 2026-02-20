local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local STATE_CONFIG = {
    [STATES.IDLE]      = { text = "Start Game",     handler = "StartSession" },
    [STATES.OPEN]      = { text = "Last Call",      handler = "LastCall" },
    [STATES.LAST_CALL] = { text = "Close Entries",  handler = "CloseEntries" },
    [STATES.CLOSED]    = { text = "End Game",       handler = "EndSession" },
}

local function SetButtonEnabled(button, enabled)
    if enabled then
        button:Enable()
        button.text:SetTextColor(1, 0.82, 0, 1)
    else
        button:Disable()
        button.text:SetTextColor(0.5, 0.5, 0.5, 1)
    end
end

local function UpdateGameButton(button, state)
    local config = STATE_CONFIG[state] or STATE_CONFIG[STATES.IDLE]
    local players = addon.session and addon.session.players or {}
    local hasPlayers = #players > 0
    local isLeader = addon:IsSessionLeader()

    if not hasPlayers and (state == STATES.OPEN or state == STATES.LAST_CALL) then
        button.text:SetText("End Game")
        button.handler = "EndSession"
        SetButtonEnabled(button, isLeader)

        return
    end

    button.text:SetText(config.text)
    button.handler = config.handler

    if state == STATES.IDLE then
        SetButtonEnabled(button, true)
    else
        SetButtonEnabled(button, isLeader)
    end
end

StaticPopupDialogs["SBG_CONFIRM_END_GAME"] = {
    text = "Players have not rolled. Are you sure you want to end the game? The game will not be scored.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        addon:EndSession()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function OnClick(button)
    if not button.handler then
        return
    end

    if button.handler == "EndSession" and addon:HasUnrolledPlayers() then
        StaticPopup_Show("SBG_CONFIRM_END_GAME")

        return
    end

    addon[button.handler](addon)
end

local function CreateGameButton(self, parentFrame, anchorElement, yOffset)
    local button = UI.Partials.CreateStyledButton(
        parentFrame,
        "SlashBreakGamblingGameButton",
        parentFrame:GetWidth() - 20,
        28,
        "Start Game"
    )

    button:SetPoint("TOP", anchorElement, "BOTTOM", 0, yOffset)
    button:SetScript("OnClick", OnClick)

    button.handler = "StartSession"

    return button
end

UI.CreateGameButton = CreateGameButton
UI.UpdateGameButton = UpdateGameButton
