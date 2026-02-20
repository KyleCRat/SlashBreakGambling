local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

addon.defaults = {
    frame = {
        shown = true,
        width = 240,
        height = 300,
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        position = {
            x = 0,
            y = -70,
            point = "CENTER",
            relativePoint = "CENTER",
        },
    },
    session = {
        selectedModule = "LowPaysHigh",
        goldAmount = 1000,
    },
}
