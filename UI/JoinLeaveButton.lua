local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local function IsLocalPlayerInSession()
    if not addon.session then
        return false
    end

    local name = GetUnitName("player", true)

    for _, player in ipairs(addon.session.players) do
        if player.name == name then
            return true
        end
    end

    return false
end

local function GetChannel()
    if IsInRaid() then
        return "RAID"
    end

    if IsInGroup() then
        return "PARTY"
    end

    return nil
end

local function OnClick()
    local channel = GetChannel()

    if not channel then
        return
    end

    if IsLocalPlayerInSession() then
        SendChatMessage("-1", channel)
    else
        SendChatMessage("1", channel)
    end
end

local function UpdateJoinLeaveButton(button, state)
    if state ~= STATES.OPEN and state ~= STATES.LAST_CALL then
        button:Hide()

        return
    end

    button:Show()

    if IsLocalPlayerInSession() then
        button.text:SetText("Leave Game")
    else
        button.text:SetText("Join Game")
    end
end

local function CreateJoinLeaveButton(self, parentFrame, anchorElement, yOffset)
    local button = UI.Partials.CreateStyledButton(
        parentFrame,
        "SlashBreakGamblingJoinLeaveButton",
        parentFrame:GetWidth() - 20,
        28,
        "Join Game"
    )

    button:SetPoint("TOP", anchorElement, "BOTTOM", 0, yOffset)
    button:SetScript("OnClick", OnClick)
    button:Hide()

    return button
end

UI.CreateJoinLeaveButton = CreateJoinLeaveButton
UI.UpdateJoinLeaveButton = UpdateJoinLeaveButton
