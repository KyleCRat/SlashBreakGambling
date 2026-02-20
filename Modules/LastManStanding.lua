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

local function AllActivePlayersRolled(session)
    for _, player in ipairs(session.players) do
        if not session.moduleState.eliminated[player.name] and not player.roll then
            return false
        end
    end

    return true
end

local function FindLowestRoll(active)
    local lowest = nil

    for _, player in ipairs(active) do
        if lowest == nil or player.roll < lowest then
            lowest = player.roll
        end
    end

    return lowest
end

local function OnRoll(session, player)
    if not session.moduleState.eliminated then
        session.moduleState.eliminated = {}
    end

    if not AllActivePlayersRolled(session) then
        return {}
    end

    local active = GetActivePlayers(session)
    local lowest = FindLowestRoll(active)
    local eliminated = {}

    for _, p in ipairs(active) do
        if p.roll == lowest then
            session.moduleState.eliminated[p.name] = true
            table.insert(eliminated, p.name)
        end
    end

    local remaining = GetActivePlayers(session)

    if #remaining == 1 then
        local loserCount = #session.players - 1

        session.lastResult = {
            winner = remaining[1].name,
            losers = {},
            amount = session.goldAmount * loserCount,
        }

        for _, p in ipairs(session.players) do
            if session.moduleState.eliminated[p.name] then
                table.insert(session.lastResult.losers, p.name)
            end
        end

        return { done = true }
    end

    if #remaining == 0 then
        session.lastResult = {
            winner = nil,
            losers = {},
            amount = 0,
        }

        for _, p in ipairs(session.players) do
            table.insert(session.lastResult.losers, p.name)
        end

        return { done = true }
    end

    local eliminationMessage = table.concat(eliminated, ", ") .. " rolled lowest (" .. lowest .. ") and " .. (#eliminated == 1 and "is" or "are") .. " eliminated!"

    for _, p in ipairs(session.players) do
        p.roll = nil
    end

    return {
        eliminationMessage = eliminationMessage,
        nextRollAmount     = session.rollAmount,
    }
end

local function AnnounceResults(players, goldAmount, lastResult)
    if not lastResult then
        return nil
    end

    if not lastResult.winner then
        return "Everyone tied — no winner!"
    end

    local loserList = table.concat(lastResult.losers, ", ")

    return loserList .. " each owe " .. lastResult.winner .. " " .. BreakUpLargeNumbers(goldAmount) .. "g! (" .. BreakUpLargeNumbers(lastResult.amount) .. "g total)"
end

addon:RegisterGameModule("LastManStanding", "Last Man Standing", {
    description = "Everyone rolls each round. The lowest roller is eliminated. Last player standing wins — all losers pay.",
    maxPlayers = nil,
    turnBased  = false,
    GetRollCommand = function(goldAmount)
        return goldAmount
    end,
    OnRoll          = OnRoll,
    AnnounceResults = AnnounceResults,
})
