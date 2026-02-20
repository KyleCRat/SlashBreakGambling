local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

local function AnnounceResults(players, goldAmount)
    if #players < 2 then
        return nil
    end

    local lowest = players[1]
    local highest = players[1]

    for _, player in ipairs(players) do
        if player.roll < lowest.roll then
            lowest = player
        end

        if player.roll > highest.roll then
            highest = player
        end
    end

    if lowest.roll == highest.roll then
        return "It's a tie! No one pays."
    end

    local diff = highest.roll - lowest.roll

    return lowest.name .. " owes " .. highest.name .. " " .. BreakUpLargeNumbers(diff) .. "g!"
end

addon:RegisterGameModule("LowPaysHigh", "Low Pays High", {
    maxPlayers = nil,
    GetRollCommand = function(goldAmount)
        return goldAmount
    end,
    AnnounceResults = AnnounceResults,
})
