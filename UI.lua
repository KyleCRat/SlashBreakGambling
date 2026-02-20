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

    if frame.tokenPriceButton then
        UI.UpdateTokenPriceButton(frame.tokenPriceButton, state)
    end

    if frame.togglePlayerListButton then
        UI.UpdateTogglePlayerListButton(frame.togglePlayerListButton, state)
    end

    if frame.joinLeaveButton then
        UI.UpdateJoinLeaveButton(frame.joinLeaveButton, state)
    end

    if frame.requestRollsButton then
        UI.UpdateRequestRollsButton(frame.requestRollsButton, state)
    end

    if frame.rollForMeButton then
        UI.UpdateRollForMeButton(frame.rollForMeButton, state)
    end

    if frame.goldSlider then
        UI.UpdateGoldSlider(frame.goldSlider, state)
    end

    if frame.moduleSelector then
        UI.UpdateModuleSelector(frame.moduleSelector, state)
    end

    if frame.playerList then
        if state ~= addon.SESSION_STATES.IDLE then
            frame.playerList:Show()
        end

        UI.RefreshPlayerList(frame.playerList)
    end
end

local function OnBreakTimerStarted()
    local frame = UI.frame

    if not frame then
        return
    end

    frame:Show()
    addon.db:Set("frame", "shown", true)
end

local function OnEncounterStarted()
    local frame = UI.frame

    if not frame then
        return
    end

    frame:Hide()
    addon.db:Set("frame", "shown", false)
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

    if frame.joinLeaveButton then
        UI.UpdateJoinLeaveButton(frame.joinLeaveButton, addon:GetSessionState())
    end
end

local function OnRollAdvanced()
    local frame = UI.frame

    if not frame then
        return
    end

    if frame.playerList then
        UI.RefreshPlayerList(frame.playerList)
    end

    if frame.rollForMeButton then
        UI.UpdateRollForMeButton(frame.rollForMeButton, addon:GetSessionState())
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

    if frame.rollForMeButton then
        UI.UpdateRollForMeButton(frame.rollForMeButton, addon:GetSessionState())
    end
end

local BUTTON_SPACING = -6
local SECTION_SPACING = -10
local CLOSE_BUTTON_SIZE = 20
local FRAME_MARGIN = 10

function UI:OnEnable()
    local frame = self:CreateMainFrame()
    frame.playerList = self:CreatePlayerList(frame)
    frame.playerList:Hide()

    local frameBoxWidth = frame:GetWidth() - (FRAME_MARGIN * 2)
    local titleWidth = frameBoxWidth - CLOSE_BUTTON_SIZE - math.abs(BUTTON_SPACING)

    frame.title = UI.Partials.CreateTitle(frame,
        SECTION_SPACING, FRAME_MARGIN, titleWidth, CLOSE_BUTTON_SIZE)

    frame.closeButton = UI.Partials.CreateCloseButton(frame,
        CLOSE_BUTTON_SIZE, FRAME_MARGIN)

    frame.dividerOne = UI.Partials.CreateDivider(frame,
        frame.title, BUTTON_SPACING, frameBoxWidth)

    frame.moduleSelector = self:CreateModuleSelector(frame,
        frame.dividerOne, BUTTON_SPACING, frameBoxWidth)

    frame.dividerTwo = UI.Partials.CreateDivider(frame,
        frame.moduleSelector, BUTTON_SPACING, frameBoxWidth)

    frame.goldSlider = self:CreateGoldSlider(frame,
        frame.dividerTwo, BUTTON_SPACING)

    frame.gameButton = self:CreateGameButton(frame,
        frame.goldSlider, SECTION_SPACING)

    frame.joinLeaveButton = self:CreateJoinLeaveButton(frame,
        frame.gameButton, BUTTON_SPACING)

    frame.tokenPriceButton = self:CreateTokenPriceButton(frame,
        frame.gameButton, BUTTON_SPACING)

    frame.togglePlayerListButton = self:CreateTogglePlayerListButton(frame,
        frame.tokenPriceButton, BUTTON_SPACING)

    frame.requestRollsButton = self:CreateRequestRollsButton(frame,
        frame.gameButton, BUTTON_SPACING)

    frame.rollForMeButton = self:CreateRollForMeButton(frame,
        frame.requestRollsButton, BUTTON_SPACING)

    frame:SetShown(addon.db:Get("frame", "shown"))
    self.frame = frame

    self:RegisterMessage("SBG_SESSION_STATE_CHANGED", OnSessionStateChanged)
    self:RegisterMessage("SBG_BREAK_TIMER_STARTED", OnBreakTimerStarted)
    self:RegisterMessage("SBG_ENCOUNTER_STARTED", OnEncounterStarted)
    self:RegisterMessage("SBG_MODULE_CHANGED", OnModuleChanged)
    self:RegisterMessage("SBG_PLAYER_JOINED", OnPlayerChanged)
    self:RegisterMessage("SBG_PLAYER_LEFT", OnPlayerChanged)
    self:RegisterMessage("SBG_PLAYER_ROLLED", OnPlayerRolled)
    self:RegisterMessage("SBG_SESSION_ROLL_ADVANCED", OnRollAdvanced)
end
