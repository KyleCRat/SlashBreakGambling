local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local LPH = addon:NewModule("LowPaysHigh")

function LPH:OnEnable()
    self:RegisterEvent("CHAT_MSG_SYSTEM", "OnChatMessage")

    addon:Print("LowPaysHigh: Enabled")
end

function LPH:OnDisable()
    self:UnregisterEvent("CHAT_MSG_SYSTEM")

    addon:Print("LowPaysHigh: Disabled")
end

function LPH:OnChatMessage(event, msg)
    addon:Print("Got Message: ", msg)
end
