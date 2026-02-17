local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

addon.Modules = {}

function addon:RegisterModule(fn)
    if not self.onModuleInitialize then self.onModuleInitialize = {} end
    table.insert(self.onModuleInitialize, fn)
end

function addon:InitializeModules()
    if Addon.onModuleInitialize then
        for _, func in ipairs(addon.onModuleInitialize) do
            func()
        end
    end
end
