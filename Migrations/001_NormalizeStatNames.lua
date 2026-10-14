local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

addon:RegisterMigration(1, function(char)
    if not char.stats then return end

    local stats = {}

    for name, balance in pairs(char.stats) do
        -- Freeze the version 1 format independently of future NormalizeName changes.
        local character, realm = strsplit("-", name, 2)

        if not realm or realm == "" then
            realm = GetNormalizedRealmName()
        end

        local normalized = character .. "-" .. (realm:gsub("[%s%-]+", ""))
        assert(stats[normalized] == nil, "Conflicting saved stat names for " .. normalized)
        stats[normalized] = balance
    end

    char.stats = stats
end)
