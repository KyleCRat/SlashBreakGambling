local MAJOR, MINOR = "AddonDB-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

--------------------------------------------------------------------------------
--- Traverse
---

local function traverse(tbl, keys, count)
    local current = tbl

    for i = 1, count do
        if type(current) ~= "table" then
            return nil
        end
        current = current[keys[i]]
    end

    return current
end

--------------------------------------------------------------------------------
--- New
---

function lib:New(savedVariableName, defaults)
    local acedb = LibStub("AceDB-3.0"):New(savedVariableName,
        { profile = defaults })

    local db = {}

    db.acedb    = acedb
    db.defaults = defaults

    db.Get             = lib.Get
    db.GetRaw          = lib.GetRaw
    db.Set             = lib.Set
    db.Reset           = lib.Reset
    db.GetColor        = lib.GetColor
    db.GetDefaultColor = lib.GetDefaultColor
    db.SetColor        = lib.SetColor
    db.ResetAll        = lib.ResetAll

    return db
end

--------------------------------------------------------------------------------
--- Get
---
-- db:Get("frame", "width") -> returns profile value, or default if nil
function lib.Get(db, ...)
    local keys = { ... }
    local value = traverse(db.acedb.profile, keys, #keys)

    if value ~= nil then
        return value
    end

    return traverse(db.defaults, keys, #keys)
end

-- db:GetRaw("frame", "width") -> returns profile value only, no fallback
function lib.GetRaw(db, ...)
    local keys = { ... }

    return traverse(db.acedb.profile, keys, #keys)
end

--------------------------------------------------------------------------------
--- Set
---
-- db:Set("frame", "width", 500) -> sets profile.frame.width = 500
function lib.Set(db, ...)
    local args = { ... }
    local value = args[#args]

    local current = db.acedb.profile
    for i = 1, #args - 2 do
        local key = args[i]
        if current[key] == nil then
            current[key] = {}
        end
        current = current[key]
    end

    local finalKey = args[#args - 1]
    current[finalKey] = value
end

--------------------------------------------------------------------------------
--- Reset
---
-- db:Reset("frame", "width") -> resets to default value
function lib.Reset(db, ...)
    local keys = { ... }

    local default_value = traverse(db.defaults, keys, #keys)

    if type(default_value) == "table" then
        default_value = CopyTable(default_value)
    end

    keys[#keys + 1] = default_value
    lib.Set(db, unpack(keys))

    return default_value
end

-- db:ResetAll() -> wipes all profile data back to defaults
function lib.ResetAll(db)
    db.acedb:ResetProfile()
end

--------------------------------------------------------------------------------
--- Color
---
-- db:GetColor("frame", "background_color") -> r, g, b, a
function lib.GetColor(db, ...)
    local color = lib.Get(db, ...)

    if type(color) == "table" and color.r and color.g and color.b and color.a then
        return color.r, color.g, color.b, color.a
    end

    return 1, 1, 1, 1
end

-- db:GetDefaultColor("frame", "background_color") -> default r, g, b, a
function lib.GetDefaultColor(db, ...)
    local keys = { ... }
    local color = traverse(db.defaults, keys, #keys)

    if type(color) == "table" and color.r and color.g and color.b and color.a then
        return color.r, color.g, color.b, color.a
    end

    return 1, 1, 1, 1
end

-- db:SetColor("frame", "background_color", { r = 1, g = 0, b = 0, a = 1 })
function lib.SetColor(db, ...)
    local args = { ... }
    local new_color = args[#args]

    if type(new_color) ~= "table" or not (new_color.r and new_color.g and new_color.b and new_color.a) then
        return
    end

    local keys = {}
    for i = 1, #args - 1 do
        keys[i] = args[i]
    end

    local color = lib.GetRaw(db, unpack(keys))

    if type(color) == "table" then
        color.r = new_color.r
        color.g = new_color.g
        color.b = new_color.b
        color.a = new_color.a
    else
        lib.Set(db, unpack(args))
    end
end
