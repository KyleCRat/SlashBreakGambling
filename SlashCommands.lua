local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

local function ToggleFrame(self)
    local frame = self:GetModule("UI").frame
    local shown = not frame:IsShown()

    frame:SetShown(shown)
    self.db:Set("frame", "shown", shown)
end

local function FormatGold(amount)
    local formatted = BreakUpLargeNumbers(math.abs(amount))

    if amount >= 0 then
        return formatted .. "g"
    end

    return "-" .. formatted .. "g"
end

StaticPopupDialogs["SBG_CONFIRM_STATS_RESET"] = {
    text = "Are you sure you want to reset all stats? This cannot be undone.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        addon:ResetStats()
        addon:Print("Stats have been reset.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function HandleStatsCommand(rest)
    if not rest or rest == "" then
        local stats = addon:GetStats()
        local count = 0

        for name, net in pairs(stats) do
            addon:Print("  " .. name .. ": " .. FormatGold(net))
            count = count + 1
        end

        if count == 0 then
            addon:Print("No stats recorded yet.")
        else
            addon:Print(count .. " player(s) in stats.")
        end

        return
    end

    local subcommand, arg2, arg3 = strsplit(" ", rest, 3)
    local subcommandLower = subcommand:lower()

    if subcommandLower == "reset" then
        StaticPopup_Show("SBG_CONFIRM_STATS_RESET")

        return
    end

    if subcommandLower == "rm" then
        if not arg2 or arg2 == "" then
            addon:Print("Usage: /sbg stats rm PlayerName-Realm")

            return
        end

        local name = addon.FindStatName(arg2)

        if not name then
            return
        end

        local stats = addon:GetStats()

        if not stats[name] then
            addon:Print(name .. " not found in stats.")

            return
        end

        addon:RemovePlayerStats(name)
        addon:Print("Removed " .. name .. " from stats.")

        return
    end

    if subcommandLower == "add" then
        if not arg2 or arg2 == "" or not arg3 or arg3 == "" then
            addon:Print("Usage: /sbg stats add PlayerName-Realm amount")

            return
        end

        local name = addon.FindStatName(arg2)
        local amount = tonumber(arg3)

        if not name then
            return
        end

        if not amount then
            addon:Print("Invalid amount: " .. arg3)

            return
        end

        addon:AdjustPlayerStats(name, amount)
        local newTotal = addon:GetPlayerStats(name)
        addon:Print(name .. " adjusted by " .. FormatGold(amount) .. ". New total: " .. FormatGold(newTotal))

        return
    end

    -- Treat as player name lookup
    local name = addon.FindStatName(subcommand)

    if not name then
        return
    end

    local net = addon:GetPlayerStats(name)
    local stats = addon:GetStats()

    if net == 0 and not stats[name] then
        addon:Print(name .. " not found in stats.")

        return
    end

    addon:Print(name .. ": " .. FormatGold(net))
end

local commands = {
    show  = ToggleFrame,
    s     = ToggleFrame,
    open  = ToggleFrame,
    o     = ToggleFrame,
    hide  = ToggleFrame,
    h     = ToggleFrame,
}

local function HandleSlashCommand(input)
    local command, rest = strsplit(" ", input, 2)
    command = (command or ""):lower()

    if command == "" then
        addon:Print("Available commands:")
        addon:Print("  /sbg show  - Toggle the gambling window (aliases: s, o, open, h, hide)")
        addon:Print("  /sbg stats - View all player stats")
        addon:Print("  /sbg stats <name> - View a player's stats")
        addon:Print("  /sbg stats add <name> <amount> - Adjust a player's stats")
        addon:Print("  /sbg stats rm <name> - Remove a player from stats")
        addon:Print("  /sbg stats reset - Reset all stats")

        return
    end

    if command == "stats" then
        HandleStatsCommand(rest)

        return
    end

    local handler = commands[command]

    if not handler then
        addon:Print("Unknown command: " .. command)

        return
    end

    handler(addon)
end

function addon:RegisterSlashCommands()
    self:RegisterChatCommand("sbg", HandleSlashCommand)
end
