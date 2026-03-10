local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local ICON_PATH = "Interface\\AddOns\\SlashBreakGambling\\SBG_Icon.tga"

local dataObject = LDB:NewDataObject("SlashBreakGambling", {
    type = "launcher",
    icon = ICON_PATH,
    OnClick = function(_, button)
        if button == "LeftButton" then
            local frame = addon:GetModule("UI").frame
            local shown = not frame:IsShown()

            frame:SetShown(shown)
            addon.db:Set("frame", "shown", shown)
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("/break Gambling")
        tooltip:AddLine("|cffffffffLeft-click|r to toggle window", 0.8, 0.8, 0.8)
    end,
})

function addon:RegisterMinimapButton()
    local profile = self.db.acedb.profile

    if not profile.minimap then
        profile.minimap = { hide = false }
    end

    LDBIcon:Register("SlashBreakGambling", dataObject, profile.minimap)
end
