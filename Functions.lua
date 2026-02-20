local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

-- Verbose: short end-user messages to chat
function addon:Print(...)
    print(addon.TAG, ...)
end

function addon:Warn(...)
    print(addon.TAG, "|cffff4444\124TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t", ..., "|r")
end

function addon:Verbose(...)
    if not addon.db.verbose then return end

    print(addon.TAG, ...)
end
