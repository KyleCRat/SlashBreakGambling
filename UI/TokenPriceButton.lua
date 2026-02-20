local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local UI = addon:GetModule("UI")

local STATES = addon.SESSION_STATES

local function OnClick()
    local priceCopper = C_WowTokenPublic.GetCurrentMarketPrice()

    if not priceCopper then
        C_WowTokenPublic.UpdateMarketPrice()
        addon:Print("Fetching token price, please try again in a moment.")

        return
    end

    local priceGold = math.floor(priceCopper / 10000)
    local goldSlider = UI.frame and UI.frame.goldSlider

    if goldSlider then
        goldSlider:SetGoldAmount(priceGold)
    end
end

local function UpdateTokenPriceButton(button, state)
    if state == STATES.IDLE then
        button:Show()
    else
        button:Hide()
    end
end

local function CreateTokenPriceButton(self, parentFrame, anchorElement, yOffset)
    local button = UI.Partials.CreateStyledButton(
        parentFrame,
        "SlashBreakGamblingTokenPriceButton",
        parentFrame:GetWidth() - 20,
        28,
        "Use Token Price"
    )

    button:SetPoint("TOP", anchorElement, "BOTTOM", 0, yOffset)
    button:SetScript("OnClick", OnClick)

    return button
end

UI.CreateTokenPriceButton = CreateTokenPriceButton
UI.UpdateTokenPriceButton = UpdateTokenPriceButton
