local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local function CreateTitle(parentFrame, yOffset, xOffset, width, height)
    local label = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xOffset, yOffset)
    label:SetSize(width, height)
    label:SetText("Slash Break Gambling")
    label:SetTextColor(1, 0.82, 0, 1)

    return label
end

UI.Partials.CreateTitle = CreateTitle
