local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local FRAME_WIDTH = 300
local PADDING = 12
local BODY_TOP = 38
local MIN_BODY_HEIGHT = 40
local MAX_BODY_HEIGHT = 280
local SCROLLBAR_COLUMN = 24

local function GetReminders()
    local char = addon.db.acedb.char

    if not char.debtReminders then
        char.debtReminders = {}
    end

    return char.debtReminders
end

function UI.FormatResultPayment(result, debtor)
    if not result or result.tie or not result.winner
        or not result.amountPerLoser or result.amountPerLoser <= 0 then
        return nil
    end

    local losers = result.losers or { result.loser }

    if #losers == 0 then
        return nil
    end

    if not debtor then
        debtor = table.concat(losers, ", ") .. (#losers == 1 and " owes " or " each owe ")
    end

    local amount = result.amountPerLoser
    local guildAmount = math.floor(amount * (result.guildCut or 0) / 100)
    local text = debtor .. result.winner .. " " .. BreakUpLargeNumbers(amount - guildAmount) .. " gold"

    if guildAmount > 0 then
        text = text .. "\n" .. debtor .. "the guild " .. BreakUpLargeNumbers(guildAmount) .. " gold"
    end

    return text
end

local function PositionReminder(frame)
    local position = addon.db:Get("debtReminder", "position")
    frame:ClearAllPoints()

    if position then
        frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)

        return
    end

    local mainFrame = UI.frame
    local right, top = mainFrame:GetRight(), mainFrame:GetTop()

    if right and top then
        local scale = mainFrame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", right * scale + PADDING, top * scale)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 280, 80)
    end
end

local function StopMoving(frame)
    if not frame.moving then
        return
    end

    frame:StopMovingOrSizing()
    frame.moving = nil
    frame:SetUserPlaced(false)

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    addon.db:Set("debtReminder", "position", { point = point, relativePoint = relativePoint, x = x, y = y })
end

function UI:CreateDebtReminder()
    local frame = CreateFrame("Frame", "SlashBreakGamblingDebtReminder", UIParent, "BackdropTemplate")
    frame:Hide()
    frame:SetSize(FRAME_WIDTH, 90)
    frame:SetPoint("CENTER", UIParent, "CENTER", 280, 80)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetToplevel(true)
    frame:SetDontSavePosition(true)
    frame:SetUserPlaced(false)
    frame.entries = GetReminders()

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.15, 0.15, 0.15, 1)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
    frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -PADDING)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetText("Payment Due")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetSize(24, 24)
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    frame.closeButton:SetScript("OnClick", function()
        wipe(frame.entries)
        frame.body:SetText("")
        frame:Hide()
    end)

    frame.scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBox")
    frame.scrollBox:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -BODY_TOP)
    frame.scrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING - SCROLLBAR_COLUMN, PADDING)
    frame.scrollBox:EnableMouseWheel(true)

    frame.content = CreateFrame("Frame", nil, frame.scrollBox)
    frame.content.scrollable = true
    frame.content:SetSize(FRAME_WIDTH - PADDING * 2 - SCROLLBAR_COLUMN, 1)

    frame.body = frame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.body:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.body:SetWidth(frame.content:GetWidth())
    frame.body:SetJustifyH("LEFT")
    frame.body:SetWordWrap(true)
    frame.body:SetNonSpaceWrap(true)

    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING - 4, -BODY_TOP)
    frame.scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING - 4, PADDING)

    local view = CreateScrollBoxLinearView()
    view:SetPanExtent(28)
    ScrollUtil.InitScrollBoxWithScrollBar(frame.scrollBox, frame.scrollBar, view)
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.scrollBox, frame.scrollBar)

    frame:SetScript("OnDragStart", function(self)
        self.moving = true
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", StopMoving)
    frame:SetScript("OnHide", StopMoving)

    return frame
end

function UI.ShowDebtReminder(frame)
    if #frame.entries == 0 then
        return
    end

    frame.body:SetText(table.concat(frame.entries, "\n\n"))

    local contentHeight = frame.body:GetStringHeight() + 2
    local visibleHeight = math.min(MAX_BODY_HEIGHT, math.max(MIN_BODY_HEIGHT, contentHeight))
    frame.content:SetHeight(contentHeight)
    frame:SetHeight(BODY_TOP + visibleHeight + PADDING)

    if not frame:IsShown() then
        PositionReminder(frame)
        frame:Show()
    end

    frame.scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
    frame.scrollBox:ScrollToEnd(ScrollBoxConstants.NoScrollInterpolation)
end

function UI.UpdateDebtReminder(frame)
    local session = addon.session
    local result = session and session.lastResult

    if addon:GetSessionState() ~= addon.SESSION_STATES.IDLE or not result then
        return
    end

    -- Keep this marker after dismissal so repeated result events cannot reopen it.
    if frame.result == result then
        return
    end

    local text = UI.FormatResultPayment(result, "You owe ")

    if not text then
        return
    end

    local playerName = addon:GetFullPlayerName()
    local losers = result.losers or { result.loser }

    for _, loser in ipairs(losers) do
        if loser == playerName then
            frame.result = result
            table.insert(frame.entries, text)
            UI.ShowDebtReminder(frame)

            return
        end
    end
end
