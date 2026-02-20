local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

addon.defaults = {
    frame = {
        shown = true,
        width = 240,
        height = 300,
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        position = {
            offsetX = 0,
            offsetY = -70,
            point = "CENTER",
            relativePoint = "CENTER",
        },
    },
}
