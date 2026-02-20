local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

local function GetActivePlayers(session)
    local active = {}

    for _, player in ipairs(session.players) do
        if not session.moduleState.eliminated[player.name] then
            table.insert(active, player)
        end
    end

    return active
end

local function GetNextActivePlayer(session, currentPlayer)
    local players = session.players
    local count = #players
    local currentIndex = session.moduleState.currentPlayerIndex

    for i = 1, count - 1 do
        local nextIndex = (currentIndex + i - 1) % count + 1
        local candidate = players[nextIndex]

        if not session.moduleState.eliminated[candidate.name] then
            return nextIndex, candidate
        end
    end

    return currentIndex, currentPlayer
end

local function OnRoll(session, player)
    if not session.moduleState.eliminated then
        session.moduleState.eliminated = {}
        session.moduleState.currentPlayerIndex = 1

        for i, p in ipairs(session.players) do
            if p.name == player.name then
                session.moduleState.currentPlayerIndex = i
                break
            end
        end
    end

    if player.roll == 1 then
        session.moduleState.eliminated[player.name] = true

        local active = GetActivePlayers(session)

        if #active == 1 then
            local loserCount = #session.players - 1

            session.lastResult = {
                winner      = active[1].name,
                losers      = {},
                amount      = session.goldAmount * loserCount,
            }

            for _, p in ipairs(session.players) do
                if session.moduleState.eliminated[p.name] then
                    table.insert(session.lastResult.losers, p.name)
                end
            end

            return { done = true }
        end

        local nextIndex, nextPlayer = GetNextActivePlayer(session, player)
        session.moduleState.currentPlayerIndex = nextIndex

        return {
            eliminationMessage = player.name .. " rolled 1 and is eliminated!",
            nextRollAmount     = session.rollAmount,
            nextPlayer         = nextPlayer.name,
        }
    end

    local nextIndex, nextPlayer = GetNextActivePlayer(session, player)
    session.moduleState.currentPlayerIndex = nextIndex

    return {
        nextRollAmount = player.roll,
        nextPlayer     = nextPlayer.name,
    }
end

local function GetResult(players, goldAmount)
    if not players or #players < 2 then
        return nil
    end

    local losers = {}
    local winner = nil

    for _, player in ipairs(players) do
        if player.roll == 1 then
            table.insert(losers, player.name)
        else
            winner = player.name
        end
    end

    if not winner or #losers == 0 then
        return nil
    end

    return {
        winner = winner,
        losers = losers,
        amount = goldAmount,
    }
end

local function AnnounceResults(players, goldAmount, lastResult)
    if not lastResult then
        return nil
    end

    local loserList = table.concat(lastResult.losers, ", ")

    return loserList .. " each owe " .. lastResult.winner .. " " .. BreakUpLargeNumbers(goldAmount) .. "g! (" .. BreakUpLargeNumbers(lastResult.amount) .. "g total)"
end

addon:RegisterGameModule("DeathRollRR", "Death Roll (Round Robin)", {
    maxPlayers = nil,
    GetRollCommand = function(goldAmount)
        return goldAmount
    end,
    OnRoll          = OnRoll,
    GetResult       = GetResult,
    AnnounceResults = AnnounceResults,
})
