local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

addon.GameModules = {}

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
        SendChatMessage(message, channel)
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
    local key = addon.db:Get("session", "selectedModule")

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

    return self.session.leader == UnitName("player")
end

function addon:StartSession()
    if self:GetSessionState() ~= SESSION_STATES.IDLE then
        return
    end

    self:ResetSession()
    self.session.state = SESSION_STATES.OPEN
    self.session.leader = UnitName("player")

    RegisterChatEvents()

    BroadcastMessage("START", self.session.goldAmount, self.session.moduleName)

    local gold = FormatGold(self.session.goldAmount)
    local mode = GetSelectedModuleLabel()
    Announce("/break Gambling — " .. mode .. " for " .. gold .. "! Type 1 to join!")

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.OPEN)
end

function addon:LastCall()
    if self:GetSessionState() ~= SESSION_STATES.OPEN then
        return
    end

    self.session.state = SESSION_STATES.LAST_CALL

    BroadcastMessage("LASTCALL")

    Announce("/break Gambling — LAST CALL! Type 1 now or miss out!")

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

    Announce("/break Gambling — Entries closed! Type /roll " .. rollAmount)

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.CLOSED)
end

function addon:EndSession()
    local state = self:GetSessionState()

    if state == SESSION_STATES.IDLE then
        return
    end

    local isLeader = self:IsSessionLeader()

    if isLeader then
        BroadcastMessage("END")
    end

    UnregisterSessionEvents()

    if isLeader then
        if not self:HasUnrolledPlayers() and #self.session.players >= 2 then
            local config = GetSelectedModuleConfig()

            if config.AnnounceResults then
                local result = config.AnnounceResults(self.session.players, self.session.goldAmount)

                if result then
                    Announce("/break Gambling — " .. result)
                end
            end
        end

        Announce("/break Gambling — Game ended!")
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

    local unrolled = {}

    for _, player in ipairs(self.session.players) do
        if not player.roll then
            table.insert(unrolled, player.name)
        end
    end

    if #unrolled == 0 then
        return
    end

    Announce("/break Gambling — Waiting on: " .. table.concat(unrolled, ", ") .. " — /roll " .. self.session.rollAmount)
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

local function AddPlayer(name)
    local players = addon.session.players
    local index = FindPlayer(players, name)

    if index then
        return
    end

    local _, classFile = UnitClass(name)

    table.insert(players, { name = name, roll = nil, classFile = classFile })
    addon:SendMessage("SBG_PLAYER_JOINED", name)
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

    local name = Ambiguate(sender, "short")

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

    local index, player = FindPlayer(self.session.players, name)

    if not index then
        return
    end

    if player.roll then
        return
    end

    player.roll = roll
    self:SendMessage("SBG_PLAYER_ROLLED", name, roll)

    if not self:HasUnrolledPlayers() then
        self:EndSession()
    end
end

--------------------------------------------------------------------------------
--- Addon Communication
---

function addon:OnAddonMessage(event, prefix, message, channel, sender)
    if prefix ~= ADDON_PREFIX then
        return
    end

    local senderName = Ambiguate(sender, "short")

    if senderName == UnitName("player") then
        return
    end

    local command, payload = strsplit(":", message, 2)

    if command == "START" then
        local goldAmount, moduleKey = strsplit(",", payload, 2)
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

    if command == "END" then
        self:OnRemoteEnd(senderName)
    end
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

    self:RegisterEvent("CHAT_MSG_SYSTEM", "OnSystemMessage")

    self:SendMessage("SBG_SESSION_STATE_CHANGED", SESSION_STATES.CLOSED)
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
