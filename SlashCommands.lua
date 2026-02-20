local addon = LibStub("AceAddon-3.0"):GetAddon("SlashBreakGambling")

local function ToggleFrame(self)
    local frame = self:GetModule("UI").frame
    local shown = not frame:IsShown()

    frame:SetShown(shown)
    self.db:Set("frame", "shown", shown)
end

local commands = {
    show = ToggleFrame,
    s    = ToggleFrame,
    o    = ToggleFrame,
    open = ToggleFrame,
    h    = ToggleFrame,
    hide = ToggleFrame,
}

local function HandleSlashCommand(input)
    local command = addon:GetArgs(input)

    if not command or command == "" then
        addon:Print("Usage: /sbg <command>")

        return
    end

    local handler = commands[command]
    if not handler then
        addon:Print("Unknown command: " .. command)

        return
    end

    handler(addon)
end

function addon:RegisterSlashCommands()
    self:RegisterChatCommand("sbg", HandleSlashCommand)
end
