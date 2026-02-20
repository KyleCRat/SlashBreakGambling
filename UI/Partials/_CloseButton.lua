local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local function CreateCloseButton(parentFrame, size, margin)
    local button = CreateFrame("Button", "SlashBreakGamblingCloseButton", parentFrame, "UIPanelCloseButton")
    button:SetSize(size, size)
    button:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -margin, -margin)
    button:SetScript("OnClick", function()
        parentFrame:Hide()
        addon.db:Set("frame", "shown", false)
    end)

    return button
end

UI.Partials.CreateCloseButton = CreateCloseButton
