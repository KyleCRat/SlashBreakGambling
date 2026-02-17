local addon = LibStub("AceAddon-3.0"):NewAddon("SlashBreakGambling", "AceEvent-3.0")
addon:SetDefaultModuleState(false)

addon.COLOR = "ff3366aa"
addon.ABBR  = "/BG"

--------------------------------------------------------------------------------
--- Module State Hooks
---

local originalEnableModule = addon.EnableModule
local originalDisableModule = addon.DisableModule

function addon:EnableModule(name)
    originalEnableModule(self, name)
    self.db:Set("modules", name, "enabled", true)
end

function addon:DisableModule(name)
    originalDisableModule(self, name)
    self.db:Set("modules", name, "enabled", false)
end

--------------------------------------------------------------------------------
--- Lifecycle
---

function addon:OnInitialize()
    self.db = LibStub("AddonDB-1.0"):New("SlashBreakGamblingDB", self.defaults)

    for name, module in self:IterateModules() do
        if self.db:Get("modules", name, "enabled") then
            module:Enable()
        end
    end
end
