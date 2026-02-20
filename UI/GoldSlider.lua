local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local MIN_GOLD = 1
local MAX_GOLD = 1000000
local SLIDER_MIN = 1000
local SLIDER_MAX = 1000000

local function FormatGoldText(amount)
    amount = math.floor(amount)

    return BreakUpLargeNumbers(amount) .. " |TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
end

local function SetEnabled(slider, editBox, enabled)
    if enabled then
        slider:Enable()
        editBox:EnableMouse(true)
        editBox:SetTextColor(1, 1, 1, 1)
    else
        slider:Disable()
        editBox:EnableMouse(false)
        editBox:SetTextColor(0.5, 0.5, 0.5, 1)
    end
end

local function UpdateGoldSlider(container, state)
    SetEnabled(container.slider, container.editBox, state == STATES.IDLE)
end

local function CreateGoldSlider(self, parentFrame, anchorElement, yOffset)
    local containerWidth = parentFrame:GetWidth() - 20

    local container = CreateFrame("Frame", nil, parentFrame)
    container:SetSize(containerWidth, 66)
    container:SetPoint("TOPLEFT", anchorElement, "BOTTOMLEFT", 0, yOffset)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOP", container, "TOP", 0, 0)
    label:SetText("Gold Amount")
    label:SetTextColor(1, 0.82, 0, 1)

    local slider = CreateFrame("Slider", "SlashBreakGamblingGoldSlider",
        container, "OptionsSliderTemplate")
    slider:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    slider:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    slider:SetHeight(16)
    slider:SetMinMaxValues(SLIDER_MIN, SLIDER_MAX)
    slider:SetValueStep(1000)
    slider:SetObeyStepOnDrag(true)

    slider.Low:SetText("")
    slider.High:SetText("")
    slider.Text:SetText("")

    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetHeight(28)
    editBox:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 20)
    editBox:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 20)
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("CENTER")
    editBox:SetFontObject("GameFontNormal")
    editBox:SetTextInsets(4, 4, 0, 0)
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    editBox:SetBackdropColor(0, 0, 0, 1)
    editBox:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    editBox:SetTextColor(1, 1, 1, 1)

    local currentAmount = addon.db:Get("session", "goldAmount")
    slider:SetValue(currentAmount)
    editBox:SetText(FormatGoldText(currentAmount))

    local sliderUpdating = false

    slider:SetScript("OnValueChanged", function(self, value)
        if sliderUpdating then
            return
        end

        value = math.floor(value)
        editBox:SetText(FormatGoldText(value))
        addon.db:Set("session", "goldAmount", value)
    end)

    editBox:SetScript("OnEditFocusGained", function(self)
        local value = addon.db:Get("session", "goldAmount")
        self:SetText(tostring(value))
        self:HighlightText()
    end)

    local committing = false

    local function CommitEditBox(self)
        if committing then
            return
        end

        committing = true

        local value = tonumber(self:GetText()) or MIN_GOLD
        value = math.max(MIN_GOLD, math.min(MAX_GOLD, math.floor(value)))

        addon.db:Set("session", "goldAmount", value)
        self:SetText(FormatGoldText(value))
        self:ClearFocus()

        sliderUpdating = true
        local sliderValue = math.max(SLIDER_MIN, math.min(SLIDER_MAX, value))
        slider:SetValue(sliderValue)
        sliderUpdating = false

        committing = false
    end

    editBox:SetScript("OnEnterPressed", CommitEditBox)
    editBox:SetScript("OnEditFocusLost", CommitEditBox)

    function container:SetGoldAmount(value)
        value = math.max(MIN_GOLD, math.min(MAX_GOLD, math.floor(value)))

        addon.db:Set("session", "goldAmount", value)
        editBox:SetText(FormatGoldText(value))

        sliderUpdating = true
        local sliderValue = math.max(SLIDER_MIN, math.min(SLIDER_MAX, value))
        slider:SetValue(sliderValue)
        sliderUpdating = false
    end

    container.slider = slider
    container.editBox = editBox

    return container
end

UI.CreateGoldSlider = CreateGoldSlider
UI.UpdateGoldSlider = UpdateGoldSlider
