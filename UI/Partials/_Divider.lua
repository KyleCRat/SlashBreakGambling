local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local function CreateDivider(parentFrame, anchorElement, yOffset, width)
    local divider = parentFrame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(2)
    divider:SetWidth(width)
    divider:SetPoint("TOPLEFT", anchorElement, "BOTTOMLEFT", 0, yOffset)
    divider:SetColorTexture(0.3, 0.3, 0.3, 1)

    return divider
end

UI.Partials.CreateDivider = CreateDivider
