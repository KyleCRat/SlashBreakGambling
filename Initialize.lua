local addon = LibStub("AceAddon-3.0"):NewAddon("SlashBreakGambling",
    "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
addon:SetDefaultModuleState(false)

addon.COLOR = "ffffd700"
addon.ABBR  = "[SBG]"
addon.TAG   = "|c" .. addon.COLOR .. addon.ABBR .. ":|r"

--------------------------------------------------------------------------------
--- Module State Hooks
---

local function OnEnableModule(self, name)
    self.db:Set("modules", name, "enabled", true)
end

local function OnDisableModule(self, name)
    self.db:Set("modules", name, "enabled", false)
end

--------------------------------------------------------------------------------
--- Lifecycle
---

local BREAK_TIMER_TYPE = 3

function addon:OnBreakTimerStart(event, timerType)
    if timerType ~= BREAK_TIMER_TYPE then
        return
    end

    self:SendMessage("SBG_BREAK_TIMER_STARTED")
end

function addon:OnEncounterStart()
    self:SendMessage("SBG_ENCOUNTER_STARTED")
end

function addon:OnInitialize()
    self:RegisterSlashCommands()
    self.db = LibStub("AddonDB-1.0"):New("SlashBreakGamblingDB", self.defaults)
    self:RegisterMinimapButton()

    C_ChatInfo.RegisterAddonMessagePrefix("SBG")
    C_ChatInfo.RegisterAddonMessagePrefix("D5")
    self:RegisterEvent("CHAT_MSG_ADDON", "OnAddonMessage")
    self:RegisterEvent("START_TIMER", "OnBreakTimerStart")
    self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")

    self:Hook(self, "EnableModule", OnEnableModule)
    self:Hook(self, "DisableModule", OnDisableModule)

    for name, module in self:IterateModules() do
        if self.db:Get("modules", name, "enabled") then
            module:Enable()
        end
    end
end
