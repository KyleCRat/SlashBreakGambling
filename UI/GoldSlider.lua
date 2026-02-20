local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local MIN_GOLD = 1
local MAX_GOLD = 9999999
local SLIDER_MIN = 1000
local SLIDER_MAX = 1000000

local function FormatGoldText(amount)
    amount = math.floor(amount)

    return BreakUpLargeNumbers(amount) .. " gold"
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

local function CreateGoldSlider(self, parentFrame)
    local containerWidth = parentFrame:GetWidth() - 20

    local container = CreateFrame("Frame", nil, parentFrame)
    container:SetSize(containerWidth, 58)
    container:SetPoint("TOP", parentFrame, "TOP", 0, -44)

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

    local editBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    editBox:SetHeight(20)
    editBox:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 6, 20)
    editBox:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 20)
    editBox:SetAutoFocus(false)

    local currentAmount = addon.db:Get("session", "goldAmount")
    slider:SetValue(currentAmount)
    editBox:SetText(FormatGoldText(currentAmount))

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        editBox:SetText(FormatGoldText(value))
        addon.db:Set("session", "goldAmount", value)
    end)

    editBox:SetScript("OnEditFocusGained", function(self)
        local value = math.floor(slider:GetValue())
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

        slider:SetValue(value)
        self:SetText(FormatGoldText(value))
        self:ClearFocus()

        committing = false
    end

    editBox:SetScript("OnEnterPressed", CommitEditBox)
    editBox:SetScript("OnEditFocusLost", CommitEditBox)

    container.slider = slider
    container.editBox = editBox

    return container
end

UI.CreateGoldSlider = CreateGoldSlider
UI.UpdateGoldSlider = UpdateGoldSlider
