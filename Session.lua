local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

addon.GameModules = {}

local function GetFullPlayerName()
    local name = GetUnitName("player", true)

    if not name:find("-") then
        name = name .. "-" .. (GetRealmName():gsub("%s+", ""))
    end

    return name
end

function addon:GetFullPlayerName()
    return GetFullPlayerName()
end

local SESSION_STATES = {
    IDLE      = "idle",
    OPEN      = "open",
    LAST_CALL = "last_call",
    CLOSED    = "closed",
}

addon.SESSION_STATES = SESSION_STATES

local function GetChatChannel()
    if IsInRaid() then
        return "RAID"
    end

    if IsInGroup() then
        return "PARTY"
    end

    return nil
end

local function Announce(message)
    local channel = GetChatChannel()

    if channel then
        SendChatMessage(addon.ABBR .. " " .. message, channel)
    else
        addon:Print(message)
    end
end

local function GetSelectedModuleLabel()
    local key = addon.db:Get("session", "selectedModule")

    for _, entry in ipairs(addon.GameModules) do
        if entry.key == key then
            return entry.label
        end
    end

    return key
end

local function GetSelectedModuleConfig()
    local key = (addon.session and addon.session.moduleName) or addon.db:Get("session", "selectedModule")

    for _, entry in ipairs(addon.GameModules) do
        if entry.key == key then
            return entry.config or {}
        end
    end

    return {}
end

local ADDON_PREFIX = "SBG"

local function BroadcastMessage(command, ...)
    local channel = GetChatChannel()

    if not channel then
        return
    end

    local parts = { command }

    for i = 1, select("#", ...) do
        table.insert(parts, tostring(select(i, ...)))
    end

    local payload = table.concat(parts, ":")

    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, payload, channel)
end

local function RegisterChatEvents()
    addon:RegisterEvent("CHAT_MSG_PARTY", "OnChatMessage")
    addon:RegisterEvent("CHAT_MSG_PARTY_LEADER", "OnChatMessage")
    addon:RegisterEvent("CHAT_MSG_RAID", "OnChatMessage")
    addon:RegisterEvent("CHAT_MSG_RAID_LEADER", "OnChatMessage")
end

local function UnregisterSessionEvents()
    addon:UnregisterAllEvents()
    addon:RegisterEvent("CHAT_MSG_ADDON", "OnAddonMessage")
end

local function FormatGold(amount)
    return tostring(amount) .. "g"
end

function addon:ResetSession()
    self.session = {
        state = SESSION_STATES.IDLE,
        leader = nil,
        players = {},
        goldAmount = self.db:Get("session", "goldAmount"),
        moduleName = self.db:Get("session", "selectedModule"),
        moduleState = {},
    }

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.IDLE)
end

function addon:GetSessionState()
    if not self.session then
        return SESSION_STATES.IDLE
    end

    return self.session.state
end

function addon:IsSessionLeader()
    if not self.session then
        return false
    end

    return self.session.leader == GetFullPlayerName()
end

function addon:StartSession()
    if self:GetSessionState() ~= SESSION_STATES.IDLE then
        return
    end

    self:ResetSession()
    self.session.state = SESSION_STATES.OPEN
    self.session.leader = GetFullPlayerName()

    RegisterChatEvents()

    BroadcastMessage("START", self.session.goldAmount, self.session.moduleName)

    local gold = FormatGold(self.session.goldAmount)
    local mode = GetSelectedModuleLabel()
    Announce(mode .. " for " .. gold .. "! Type 1 to join, -1 to leave.")

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.OPEN)
end

function addon:LastCall()
    if self:GetSessionState() ~= SESSION_STATES.OPEN then
        return
    end

    self.session.state = SESSION_STATES.LAST_CALL

    BroadcastMessage("LASTCALL")

    Announce("LAST CALL! Type 1 now or miss out!")

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.LAST_CALL)
end

function addon:CloseEntries()
    if self:GetSessionState() ~= SESSION_STATES.LAST_CALL then
        return
    end

    self:UnregisterEvent("CHAT_MSG_PARTY")
    self:UnregisterEvent("CHAT_MSG_PARTY_LEADER")
    self:UnregisterEvent("CHAT_MSG_RAID")
    self:UnregisterEvent("CHAT_MSG_RAID_LEADER")

    if #self.session.players == 0 then
        self:EndSession()

        return
    end

    self.session.state = SESSION_STATES.CLOSED
    self:RegisterEvent("CHAT_MSG_SYSTEM", "OnSystemMessage")

    local config = GetSelectedModuleConfig()
    local rollAmount = self.session.goldAmount

    if config.GetRollCommand then
        rollAmount = config.GetRollCommand(self.session.goldAmount)
    end

    self.session.rollAmount = rollAmount

    BroadcastMessage("CLOSE", rollAmount)

    if config.OnRoll and config.turnBased then
        self.session.moduleState.currentPlayerName = self.session.players[1].name
        Announce("Entries closed! " .. self.session.players[1].name .. " — /roll " .. rollAmount)
    else
        Announce("Entries closed! Type /roll " .. rollAmount)
    end

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.CLOSED)
end

local function BroadcastAndUpdateStats(session)
    local result = session.lastResult

    if not result or result.tie then
        return
    end

    local winner = result.winner

    if not winner then
        return
    end

    local losers = result.losers and result.losers or { result.loser }
    local amountPerLoser

    if result.losers then
        amountPerLoser = session.goldAmount
    else
        amountPerLoser = result.amount
    end

    BroadcastMessage("RESULT", amountPerLoser, winner, unpack(losers))
    addon:UpdateStats(amountPerLoser, winner, losers)
end

function addon:EndSession()
    local state = self:GetSessionState()

    if state == SESSION_STATES.IDLE then
        return
    end

    local isLeader = self:IsSessionLeader()

    UnregisterSessionEvents()

    local config = GetSelectedModuleConfig()

    if not self.session.lastResult and config.GetResult then
        self.session.lastResult = config.GetResult(self.session.players, self.session.goldAmount)
    end

    if isLeader and self.session.lastResult then
        BroadcastAndUpdateStats(self.session)

        if config.AnnounceResults then
            local announcement = config.AnnounceResults(self.session.players, self.session.goldAmount, self.session.lastResult)

            if announcement then
                Announce(announcement)
            end
        end

        Announce("Game ended!")
    elseif isLeader then
        Announce("Game ended!")
        self.session.players = {}
        self.session.lastResult = nil
    end

    if isLeader then
        BroadcastMessage("END")
    end

    self.session.state = SESSION_STATES.IDLE
    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.IDLE)
end

function addon:HasUnrolledPlayers()
    if not self.session then
        return false
    end

    for _, player in ipairs(self.session.players) do
        if not player.roll then
            return true
        end
    end

    return false
end

function addon:RequestRolls()
    if self:GetSessionState() ~= SESSION_STATES.CLOSED then
        return
    end

    local currentPlayerName = self.session.moduleState.currentPlayerName

    if currentPlayerName then
        Announce("Waiting on: " .. currentPlayerName .. " — /roll " .. self.session.rollAmount)

        return
    end

    local unrolled = {}
    local eliminated = self.session.moduleState.eliminated

    for _, player in ipairs(self.session.players) do
        if not player.roll and not (eliminated and eliminated[player.name]) then
            table.insert(unrolled, player.name)
        end
    end

    if #unrolled == 0 then
        return
    end

    Announce("Waiting on: " .. table.concat(unrolled, ", ") .. " — /roll " .. self.session.rollAmount)
end

--------------------------------------------------------------------------------
--- Player Management
---

local function FindPlayer(players, name)
    for i, player in ipairs(players) do
        if player.name == name then
            return i, player
        end
    end

    return nil, nil
end

local function FindPlayerByShortName(players, shortName)
    for i, player in ipairs(players) do
        local playerShortName = player.name:match("^([^%-]+)")

        if playerShortName == shortName then
            return i, player
        end
    end

    return nil, nil
end

function addon:CanRollForMe()
    if self:GetSessionState() ~= SESSION_STATES.CLOSED then
        return false
    end

    local name = GetFullPlayerName()
    local _, player = FindPlayer(self.session.players, name)

    if not player then
        return false
    end

    if player.roll then
        return false
    end

    local currentPlayerName = self.session.moduleState.currentPlayerName

    if currentPlayerName and currentPlayerName ~= name then
        return false
    end

    return true
end

function addon:RollForMe()
    if not self:CanRollForMe() then
        return
    end

    RandomRoll(1, self.session.rollAmount)
end

local function AddPlayer(name)
    local players = addon.session.players
    local index = FindPlayer(players, name)

    if index then
        return
    end

    local config = GetSelectedModuleConfig()

    if config.maxPlayers and #players >= config.maxPlayers then
        return
    end

    local classFile
    local unitName = GetFullPlayerName()

    if unitName == name then
        _, classFile = UnitClass("player")
    else
        local realm = GetRealmName():gsub("%s+", "")

        for i = 1, GetNumGroupMembers() do
            local unit = (IsInRaid() and "raid" or "party") .. i
            local unitName = GetUnitName(unit, true)

            if unitName and not unitName:find("-") then
                unitName = unitName .. "-" .. realm
            end

            if unitName == name then
                _, classFile = UnitClass(unit)
                break
            end
        end
    end

    table.insert(players, { name = name, roll = nil, classFile = classFile })
    addon:SendMessage("SBG_PLAYER_JOINED", name)

    if addon:IsSessionLeader() and config.maxPlayers and #players >= config.maxPlayers then
        addon:LastCall()
        addon:CloseEntries()
    end
end

local function RemovePlayer(name)
    local players = addon.session.players
    local index = FindPlayer(players, name)

    if not index then
        return
    end

    table.remove(players, index)
    addon:SendMessage("SBG_PLAYER_LEFT", name)
end

--------------------------------------------------------------------------------
--- Chat Handlers
---

local ROLL_PATTERN = "(.+) rolls (%d+) %(1%-(%d+)%)"

function addon:OnChatMessage(event, msg, sender)
    local state = self:GetSessionState()

    if state ~= SESSION_STATES.OPEN and state ~= SESSION_STATES.LAST_CALL then
        return
    end

    local name = sender

    if msg == "1" then
        AddPlayer(name)

        return
    end

    if msg == "-1" then
        RemovePlayer(name)
    end
end

function addon:OnSystemMessage(event, msg)
    if self:GetSessionState() ~= SESSION_STATES.CLOSED then
        return
    end

    local name, roll, maxRoll = msg:match(ROLL_PATTERN)

    if not name then
        return
    end

    roll = tonumber(roll)
    maxRoll = tonumber(maxRoll)

    if maxRoll ~= self.session.rollAmount then
        return
    end

    local index, player = FindPlayerByShortName(self.session.players, name)

    if not index then
        return
    end

    if player.roll then
        return
    end

    local config = GetSelectedModuleConfig()

    if config.OnRoll and config.turnBased then
        local currentName = self.session.moduleState.currentPlayerName
        local shortCurrent = currentName and currentName:match("^([^%-]+)")

        if name ~= shortCurrent then
            return
        end
    end

    player.roll = roll
    self:SendMessage("SBG_PLAYER_ROLLED", name, roll)

    if not self:IsSessionLeader() then
        return
    end

    if config.OnRoll then
        local result = config.OnRoll(self.session, player)

        if result.done then
            self:EndSession()
        elseif result.nextRollAmount then
            self.session.rollAmount = result.nextRollAmount

            if config.turnBased then
                self.session.moduleState.currentPlayerName = result.nextPlayer
            end

            if result.clearRolls then
                for _, p in ipairs(self.session.players) do
                    p.roll = nil
                end

                player.roll = roll
            end

            if result.eliminationMessage then
                Announce(result.eliminationMessage)
            end

            BroadcastMessage("ROLLADVANCED", result.nextRollAmount, player.name, roll, result.nextPlayer or "")

            if result.nextPlayer then
                Announce(result.nextPlayer .. " — /roll " .. result.nextRollAmount)
            else
                Announce("Type /roll " .. result.nextRollAmount)
            end

            self:SendMessage("SBG_SESSION_ROLL_ADVANCED", result.nextRollAmount)
        end

        return
    end

    if not self:HasUnrolledPlayers() then
        self:EndSession()
    end
end

--------------------------------------------------------------------------------
--- Addon Communication
---

local DBM_PREFIX = "D5"
local DBM_BREAK_TYPE = "BT"

function addon:OnBreakTimerAddonMessage(event, prefix, message)
    if prefix ~= DBM_PREFIX then
        return
    end

    local parts = { strsplit("\t", message) }

    if parts[3] ~= DBM_BREAK_TYPE then
        return
    end

    self:SendMessage("SBG_BREAK_TIMER_STARTED")
end

function addon:OnAddonMessage(event, prefix, message, channel, sender)
    if prefix == DBM_PREFIX then
        self:OnBreakTimerAddonMessage(event, prefix, message)

        return
    end

    if prefix ~= ADDON_PREFIX then
        return
    end

    local senderName = sender

    if senderName == GetFullPlayerName() then
        return
    end

    local command, payload = strsplit(":", message, 2)

    if command == "START" then
        local goldAmount, moduleKey = strsplit(":", payload, 2)
        self:OnRemoteStart(senderName, tonumber(goldAmount), moduleKey)

        return
    end

    if command == "LASTCALL" then
        self:OnRemoteLastCall(senderName)

        return
    end

    if command == "CLOSE" then
        self:OnRemoteClose(senderName, tonumber(payload))

        return
    end

    if command == "ROLLADVANCED" then
        local nextRollAmount, rollerName, rollerRoll, nextPlayerName = strsplit(":", payload, 4)

        if nextPlayerName == "" then
            nextPlayerName = nil
        end

        self:OnRemoteRollAdvanced(senderName, tonumber(nextRollAmount), rollerName, tonumber(rollerRoll), nextPlayerName)

        return
    end

    if command == "RESULT" then
        self:OnRemoteResult(payload)

        return
    end

    if command == "END" then
        self:OnRemoteEnd(senderName)
    end
end

function addon:OnRemoteResult(payload)
    local parts = { strsplit(":", payload) }
    local amountPerLoser = tonumber(parts[1])
    local winner = parts[2]
    local losers = {}

    for i = 3, #parts do
        table.insert(losers, parts[i])
    end

    self:UpdateStats(amountPerLoser, winner, losers)
end

function addon:OnRemoteStart(leader, goldAmount, moduleKey)
    if self:GetSessionState() ~= SESSION_STATES.IDLE then
        return
    end

    self.session = {
        state = SESSION_STATES.OPEN,
        leader = leader,
        players = {},
        goldAmount = goldAmount,
        moduleName = moduleKey,
        moduleState = {},
    }

    RegisterChatEvents()

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.OPEN)
end

function addon:OnRemoteLastCall(leader)
    if self:GetSessionState() ~= SESSION_STATES.OPEN then
        return
    end

    if not self.session or self.session.leader ~= leader then
        return
    end

    self.session.state = SESSION_STATES.LAST_CALL

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.LAST_CALL)
end

function addon:OnRemoteClose(leader, rollAmount)
    if self:GetSessionState() ~= SESSION_STATES.LAST_CALL then
        return
    end

    if not self.session or self.session.leader ~= leader then
        return
    end

    self:UnregisterEvent("CHAT_MSG_PARTY")
    self:UnregisterEvent("CHAT_MSG_PARTY_LEADER")
    self:UnregisterEvent("CHAT_MSG_RAID")
    self:UnregisterEvent("CHAT_MSG_RAID_LEADER")

    self.session.state = SESSION_STATES.CLOSED
    self.session.rollAmount = rollAmount

    local config = GetSelectedModuleConfig()

    if config.OnRoll and config.turnBased and #self.session.players > 0 then
        self.session.moduleState.currentPlayerName = self.session.players[1].name
    end

    self:RegisterEvent("CHAT_MSG_SYSTEM", "OnSystemMessage")

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.CLOSED)
end

function addon:OnRemoteRollAdvanced(leader, nextRollAmount, rollerName, rollerRoll, nextPlayerName)
    if self:GetSessionState() ~= SESSION_STATES.CLOSED then
        return
    end

    if not self.session or self.session.leader ~= leader then
        return
    end

    local config = GetSelectedModuleConfig()

    self.session.rollAmount = nextRollAmount

    if config.turnBased then
        self.session.moduleState.currentPlayerName = nextPlayerName
    end

    for _, player in ipairs(self.session.players) do
        player.roll = nil
    end

    local _, roller = FindPlayer(self.session.players, rollerName)

    if roller then
        roller.roll = rollerRoll
    end

    self:SendMessage("SBG_SESSION_ROLL_ADVANCED", nextRollAmount)
end

function addon:OnRemoteEnd(leader)
    local state = self:GetSessionState()

    if state == SESSION_STATES.IDLE then
        return
    end

    if not self.session or self.session.leader ~= leader then
        return
    end

    UnregisterSessionEvents()

    self.session.state = SESSION_STATES.IDLE

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.IDLE)
end

--------------------------------------------------------------------------------
--- Game Modules
---

function addon:RegisterGameModule(key, label, config)
    for _, entry in ipairs(self.GameModules) do
        if entry.key == key then
            return
        end
    end

    table.insert(self.GameModules, {
        key = key,
        label = label,
        config = config or {},
    })
end

function addon:CycleGameModule()
    if self:GetSessionState() ~= SESSION_STATES.IDLE then
        return
    end

    local modules = self.GameModules

    if #modules == 0 then
        return
    end

    local current = self.db:Get("session", "selectedModule")
    local nextIndex = 1

    for i, entry in ipairs(modules) do
        if entry.key == current then
            nextIndex = (i % #modules) + 1
            break
        end
    end

    self.db:Set("session", "selectedModule", modules[nextIndex].key)

    self:SendMessage("SBG_MODULE_CHANGED", modules[nextIndex].key)
end
