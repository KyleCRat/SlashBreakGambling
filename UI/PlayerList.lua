local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

function UI:CreatePlayerList(parentFrame)
    local frame = CreateFrame("Frame", "SlashBreakGamblingPlayerList", parentFrame, "BackdropTemplate")
    frame:SetPoint("TOPRIGHT", parentFrame, "TOPLEFT", -4, 0)
    frame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMLEFT", -4, 0)
    frame:SetWidth(160)


    frame:SetFrameStrata("HIGH")

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetBackdropBorderColor(1, 1, 1, 1)

    return frame
end
