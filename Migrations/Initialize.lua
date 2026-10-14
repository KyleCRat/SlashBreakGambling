local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")
local migrations = {}

function addon:RegisterMigration(version, migrate)
    assert(version == #migrations + 1, "SBG migrations must be registered in sequence without gaps")
    migrations[version] = migrate
end

function addon:RunMigrations()
    local char = self.db.acedb.char
    local completedVersion = char.migrationVersion or 0

    for version = completedVersion + 1, #migrations do
        local ok, err = pcall(migrations[version], char)

        if not ok then
            self:SetEnabledState(false)

            -- AceAddon also queues each module for enabling independently.
            for _, module in self:IterateModules() do
                module:SetEnabledState(false)
            end

            error("SBG migration " .. version .. " failed: " .. tostring(err))
        end

        char.migrationVersion = version
    end
end
