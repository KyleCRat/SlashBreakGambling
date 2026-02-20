local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

local function GetOtherPlayer(session, currentPlayer)
    for _, player in ipairs(session.players) do
        if player.name ~= currentPlayer.name then
            return player
        end
    end

    return nil
end

local function OnRoll(session, player)
    if player.roll == 1 then
        local loser = player
        local winner = GetOtherPlayer(session, player)

        session.lastResult = {
            winner = winner and winner.name or nil,
            loser  = loser.name,
            amount = session.goldAmount,
        }

        return { done = true }
    end

    local nextPlayer = GetOtherPlayer(session, player)

    return {
        nextRollAmount = player.roll,
        nextPlayer     = nextPlayer and nextPlayer.name or player.name,
    }
end

local function GetResult(players, goldAmount)
    -- Result is set directly on session.lastResult by OnRoll before EndSession is called.
    -- This is a passthrough so AnnounceResults can read it.
    for _, player in ipairs(players) do
        if player.roll == 1 then
            local loser = player

            for _, other in ipairs(players) do
                if other.name ~= loser.name then
                    return {
                        winner = other.name,
                        loser  = loser.name,
                        amount = goldAmount,
                    }
                end
            end
        end
    end

    return nil
end

local function AnnounceResults(players, goldAmount, lastResult)
    local result = GetResult(players, goldAmount)

    if not result then
        return nil
    end

    return result.loser .. " rolled 1! " .. result.loser .. " owes " .. result.winner .. " " .. BreakUpLargeNumbers(result.amount) .. "g!"
end

addon:RegisterGameModule("DeathRoll", "Death Roll (1v1)", {
    maxPlayers = 2,
    GetRollCommand = function(goldAmount)
        return goldAmount
    end,
    OnRoll         = OnRoll,
    GetResult      = GetResult,
    AnnounceResults = AnnounceResults,
})
