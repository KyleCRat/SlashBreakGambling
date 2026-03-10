local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

addon.defaults = {
    frame = {
        shown = false,
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        position = {
            x = 0,
            y = -70,
            point = "CENTER",
            relativePoint = "CENTER",
        },
    },
    minimap = {
        hide = false,
    },
    session = {
        selectedModule = "LowPaysHighDiff",
        goldAmount = 1000,
    },
}
