local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local function CreateStyledButton(parent, name, width, height, text)
    local button = CreateFrame("Button", name, parent, "BackdropTemplate")
    button:SetSize(width, height)

    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    button:SetBackdropColor(0.15, 0.15, 0.15, 1)
    button:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER", 0, 0)
    button.text:SetText(text)
    button.text:SetTextColor(1, 0.82, 0, 1)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 1)
        self:SetBackdropBorderColor(1, 0.82, 0, 1)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end)

    button:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.1, 0.1, 0.1, 1)
        self.text:SetPoint("CENTER", 1, -1)
    end)

    button:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 1)
        self.text:SetPoint("CENTER", 0, 0)
    end)

    return button
end

UI.Partials.CreateStyledButton = CreateStyledButton
