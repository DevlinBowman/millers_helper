-- interface/session.lua
--
-- Persistent interface session (Lua-backed).

local Session = {
    _loaded = false,
    _path   = os.getenv("HOME") .. "/.lumber_app_session.lua",
    _state  = {
        ledger_path = nil,
    }
}

------------------------------------------------------------
-- Internal Helpers
------------------------------------------------------------

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

local function load_from_disk()
    if not file_exists(Session._path) then
        return
    end

    local chunk, err = loadfile(Session._path)
    if not chunk then
        io.stderr:write("session load error: " .. tostring(err) .. "\n")
        return
    end

    local ok, result = pcall(chunk)
    if ok and type(result) == "table" then
        Session._state = result
    end
end

local function serialize_table(tbl, indent)
    indent = indent or 0
    local spacing = string.rep("    ", indent)
    local lines = {"{\n"}

    for k, v in pairs(tbl) do
        local key = string.format("%s    %s = ", spacing, k)

        if type(v) == "string" then
            table.insert(lines, key .. string.format("%q", v) .. ",\n")
        elseif type(v) == "number" or type(v) == "boolean" then
            table.insert(lines, key .. tostring(v) .. ",\n")
        elseif type(v) == "table" then
            table.insert(lines, key .. serialize_table(v, indent + 1) .. ",\n")
        else
            table.insert(lines, key .. "nil,\n")
        end
    end

    table.insert(lines, spacing .. "}")
    return table.concat(lines)
end

local function save_to_disk()
    local content = "return " .. serialize_table(Session._state) .. "\n"

    local f = io.open(Session._path, "w")
    if not f then
        io.stderr:write("failed to write session file\n")
        return
    end

    f:write(content)
    f:close()
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

function Session.load()
    if Session._loaded then return end
    load_from_disk()
    Session._loaded = true
end

function Session.get_ledger_path()
    Session.load()
    return Session._state.ledger_path
end

function Session.set_ledger_path(path)
    Session.load()
    Session._state.ledger_path = path
    save_to_disk()
end

function Session.clear()
    Session._state = { ledger_path = nil }
    save_to_disk()
end

return Session
