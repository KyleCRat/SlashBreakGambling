local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local FRAME_WIDTH = 240
local FRAME_HEIGHT = 302

local function CreateMainFrame()
    local db = addon.db

    local bgR, bgG, bgB, bgA = db:GetColor("frame", "backgroundColor")
    local pos = db:Get("frame", "position")

    local frame = CreateFrame("Frame", "SlashBreakGamblingFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(bgR, bgG, bgB, bgA)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:EnableMouse(true)

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local point, _, relativePoint, x, y = self:GetPoint()
        db:Set("frame", "position", { point = point, relativePoint = relativePoint, x = x, y = y })
    end)

    return frame
end

UI.CreateMainFrame = CreateMainFrame
