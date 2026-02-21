-- interface/state/store.lua
--
-- Persistent state store (Lua-backed). Umbrella-owned.

local Store = {}
Store.__index = Store

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

local function serialize_table(tbl, indent)
    indent = indent or 0
    local spacing = string.rep("    ", indent)
    local lines = {"{\n"}

    for k, v in pairs(tbl) do
        local key_repr
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
            key_repr = k
        else
            key_repr = "[" .. string.format("%q", tostring(k)) .. "]"
        end

        local prefix = string.format("%s    %s = ", spacing, key_repr)

        if type(v) == "string" then
            table.insert(lines, prefix .. string.format("%q", v) .. ",\n")
        elseif type(v) == "number" or type(v) == "boolean" then
            table.insert(lines, prefix .. tostring(v) .. ",\n")
        elseif type(v) == "table" then
            table.insert(lines, prefix .. serialize_table(v, indent + 1) .. ",\n")
        else
            table.insert(lines, prefix .. "nil,\n")
        end
    end

    table.insert(lines, spacing .. "}")
    return table.concat(lines)
end

function Store.new(opts)
    opts = opts or {}
    local path = opts.path or (os.getenv("HOME") .. "/.lumber_app_state.lua")

    return setmetatable({
        _path = path,
        _loaded = false,
        _state = {},
    }, Store)
end

function Store:load()
    if self._loaded then return end
    self._loaded = true

    if not file_exists(self._path) then
        self._state = {}
        return
    end

    local chunk, err = loadfile(self._path)
    if not chunk then
        io.stderr:write("state load error: " .. tostring(err) .. "\n")
        self._state = {}
        return
    end

    local ok, result = pcall(chunk)
    if ok and type(result) == "table" then
        self._state = result
    else
        self._state = {}
    end
end

function Store:save()
    self:load()
    local content = "return " .. serialize_table(self._state) .. "\n"
    local f = io.open(self._path, "w")
    if not f then
        io.stderr:write("failed to write state file: " .. tostring(self._path) .. "\n")
        return false
    end
    f:write(content)
    f:close()
    return true
end

function Store:get(key)
    self:load()
    return self._state[key]
end

function Store:set(key, value)
    self:load()
    self._state[key] = value
    return self:save()
end

function Store:clear(key)
    self:load()
    self._state[key] = nil
    return self:save()
end

return Store
