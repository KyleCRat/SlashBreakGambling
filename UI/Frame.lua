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
    frame:SetPoint(pos.point, UIParent, pos.relative_point, pos.x, pos.y)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(bgR, bgG, bgB, bgA)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

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
