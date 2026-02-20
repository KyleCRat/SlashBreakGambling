local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:NewModule("UI")
UI:SetEnabledState(true)

UI.Partials = {}

function UI:OnEnable()
    local frame = self:CreateMainFrame()
    frame.playerList = self:CreatePlayerList(frame)

    frame:SetShown(addon.db:Get("frame", "shown"))
    self.frame = frame
end
