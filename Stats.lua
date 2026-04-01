local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

local function GetStatsTable()
    local char = addon.db.acedb.char

    if not char.stats then
        char.stats = {}
    end

    return char.stats
end

local function NormalizeName(name)
    if not name or name == "" then
        return nil
    end

    if not name:find("-") then
        name = name .. "-" .. (GetRealmName():gsub("%s+", ""))
    end

    return name
end

function addon:GetStats()
    return GetStatsTable()
end

function addon:GetPlayerStats(name)
    local stats = GetStatsTable()

    return stats[name] or 0
end

function addon:UpdateStats(amountPerLoser, winner, losers)
    if not winner or not losers or #losers == 0 or not amountPerLoser or amountPerLoser <= 0 then
        return
    end

    local stats = GetStatsTable()

    stats[winner] = (stats[winner] or 0) + (amountPerLoser * #losers)

    for _, loser in ipairs(losers) do
        stats[loser] = (stats[loser] or 0) - amountPerLoser
    end

    self:SendMessage("SBG_STATS_UPDATED")
end

function addon:ResetStats()
    addon.db.acedb.char.stats = {}
    self:SendMessage("SBG_STATS_UPDATED")
end

function addon:RemovePlayerStats(name)
    local stats = GetStatsTable()
    stats[name] = nil
    self:SendMessage("SBG_STATS_UPDATED")
end

function addon:AdjustPlayerStats(name, amount)
    local stats = GetStatsTable()
    stats[name] = (stats[name] or 0) + amount
    self:SendMessage("SBG_STATS_UPDATED")
end

function addon:GetSortedStats()
    local stats = GetStatsTable()
    local winners = {}
    local losers = {}

    for name, net in pairs(stats) do
        if net > 0 then
            table.insert(winners, { name = name, net = net })
        elseif net < 0 then
            table.insert(losers, { name = name, net = net })
        end
    end

    table.sort(winners, function(a, b)
        return a.net > b.net
    end)

    table.sort(losers, function(a, b)
        return a.net < b.net
    end)

    return winners, losers
end

local function FindStatName(input)
    local stats = GetStatsTable()
    local normalized = NormalizeName(input)

    if not normalized then
        return nil
    end

    if stats[normalized] then
        return normalized
    end

    local lower = normalized:lower()

    for name in pairs(stats) do
        if name:lower() == lower then
            return name
        end
    end

    return normalized
end

addon.NormalizeName = NormalizeName
addon.FindStatName = FindStatName
