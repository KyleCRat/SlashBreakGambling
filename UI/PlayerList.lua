local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local function CreatePlayerList()
    local frame = CreateFrame("Frame", "SlashBreakGamblingPlayerList", UI.mainFrame)
    frame:SetPoint("LEFT", UI.mainFrame, "RIGHT", 0, 0)
    frame:SetClampedToScreen(true)

    UI.playerList = frame
end

UI.CreatePlayerList = CreatePlayerList
