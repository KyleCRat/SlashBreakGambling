local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local function CreateMainFrame()
    local db = addon.db

    local width = db:Get("frame", "width")
    local height = db:Get("frame", "height")
    local bgR, bgG, bgB, bgA = db:GetColor("frame", "backgroundColor")
    local pos = db:Get("frame", "position")

    local frame = CreateFrame("Frame", "SlashBreakGamblingFrame", UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    frame:SetClampedToScreen(true)
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
    frame:SetBackdropColor(bgR, bgG, bgB, bgA)
    frame:SetBackdropBorderColor(1, 1, 1, 1)

    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:EnableMouse(true)

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    return frame
end

UI.CreateMainFrame = CreateMainFrame
