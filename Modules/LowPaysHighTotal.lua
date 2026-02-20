local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

local function FindLowestAndHighest(players)
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

    return lowest, highest
end

local function GetResult(players, goldAmount)
    if #players < 2 then
        return nil
    end

    local lowest, highest = FindLowestAndHighest(players)

    if lowest.roll == highest.roll then
        return { tie = true }
    end

    return {
        winner = highest.name,
        loser  = lowest.name,
        amount = goldAmount,
    }
end

local function AnnounceResults(players, goldAmount, lastResult)
    if not lastResult then
        return nil
    end

    if lastResult.tie then
        return "It's a tie! No one pays."
    end

    return lastResult.loser .. " owes " .. lastResult.winner .. " " .. BreakUpLargeNumbers(lastResult.amount) .. "g!"
end

addon:RegisterGameModule("LowPaysHighTotal", "Low Pays High (Total)", {
    description = "Everyone rolls. The lowest roller pays the highest roller the total gold amount.",
    maxPlayers = nil,
    GetRollCommand = function(goldAmount)
        return goldAmount
    end,
    GetResult = GetResult,
    AnnounceResults = AnnounceResults,
})
