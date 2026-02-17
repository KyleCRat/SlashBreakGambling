local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

-- Verbose: short end-user messages to chat
function addon:Print(...)
    print(addon.COLOR .. addon.ABBR .. ":|r", ...)
end

function addon:Warn(...)
    print(addon.COLOR .. addon.ABBR .. ":|r |cffff4444" ..
          "\124TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t", ..., "|r")
end

function addon:Verbose(...)
    if not addon.db.verbose then return end

    print(addon.COLOR .. addon.ABBR .. ":|r", ...)
end
