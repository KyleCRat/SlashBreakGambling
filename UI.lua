local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:NewModule("UI", "AceEvent-3.0")
UI:SetEnabledState(true)

UI.Partials = {}

local function OnSessionStateChanged(event, state)
    local frame = UI.frame

    if not frame then
        return
    end

    if frame.gameButton then
        UI.UpdateGameButton(frame.gameButton, state)
    end

    if frame.requestRollsButton then
        UI.UpdateRequestRollsButton(frame.requestRollsButton, state)
    end

    if frame.goldSlider then
        UI.UpdateGoldSlider(frame.goldSlider, state)
    end

    if frame.moduleSelector then
        UI.UpdateModuleSelector(frame.moduleSelector, state)
    end

    if frame.playerList then
        UI.RefreshPlayerList(frame.playerList)
    end
end

local function OnModuleChanged(event, key)
    local frame = UI.frame

    if not frame or not frame.moduleSelector then
        return
    end

    UI.UpdateModuleSelectorLabel(frame.moduleSelector)
end

local function OnPlayerChanged(event, name)
    local frame = UI.frame

    if not frame then
        return
    end

    if frame.playerList then
        UI.RefreshPlayerList(frame.playerList)
    end

    if frame.gameButton then
        UI.UpdateGameButton(frame.gameButton, addon:GetSessionState())
    end
end

local function OnPlayerRolled(event, name, roll)
    local frame = UI.frame

    if not frame or not frame.playerList then
        return
    end

    UI.RefreshPlayerList(frame.playerList)

    if frame.requestRollsButton then
        UI.UpdateRequestRollsButton(frame.requestRollsButton, addon:GetSessionState())
    end
end

function UI:OnEnable()
    local frame = self:CreateMainFrame()
    frame.playerList = self:CreatePlayerList(frame)
    frame.goldSlider = self:CreateGoldSlider(frame)
    frame.moduleSelector = self:CreateModuleSelector(frame)
    frame.requestRollsButton = self:CreateRequestRollsButton(frame)
    frame.gameButton = self:CreateGameButton(frame)

    frame:SetShown(addon.db:Get("frame", "shown"))
    self.frame = frame

    self:RegisterMessage("SBG_SESSION_STATE_CHANGED", OnSessionStateChanged)
    self:RegisterMessage("SBG_MODULE_CHANGED", OnModuleChanged)
    self:RegisterMessage("SBG_PLAYER_JOINED", OnPlayerChanged)
    self:RegisterMessage("SBG_PLAYER_LEFT", OnPlayerChanged)
    self:RegisterMessage("SBG_PLAYER_ROLLED", OnPlayerRolled)
end
