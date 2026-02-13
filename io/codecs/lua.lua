-- io/codecs/lua.lua
--
-- Lua data codec.
--
-- Contract:
--   • read(path)  -> { codec = "lua", data = table } | throws
--   • write(path, table) -> true | throws
--
-- Strictly data-only:
--   • File MUST return a table
--   • No global access
--   • No injected environment
--   • No metatables allowed

---@class LuaReadResult
---@field codec "lua"
---@field data table

local LuaCodec = {}

----------------------------------------------------------------
-- Deep validation: literal-safe tables only
----------------------------------------------------------------

---@param value any
---@param seen? table<table, boolean>
---@return boolean ok
---@return string? err
local function validate_literal(value, seen)
    local t = type(value)

    if t == "nil" or t == "number" or t == "boolean" or t == "string" then
        return true
    end

    if t ~= "table" then
        return false, "unsupported lua data type: " .. t
    end

    if getmetatable(value) ~= nil then
        return false, "metatables not allowed in lua data files"
    end

    seen = seen or {}
    if seen[value] then
        return false, "cyclic table detected"
    end
    seen[value] = true

    for k, v in pairs(value) do
        local kt = type(k)
        if kt ~= "string" and kt ~= "number" then
            return false, "invalid table key type: " .. kt
        end

        local ok, err = validate_literal(v, seen)
        if not ok then
            return false, err
        end
    end

    return true
end

----------------------------------------------------------------
-- Read
----------------------------------------------------------------

---@param path string
---@return LuaReadResult
function LuaCodec.read(path)
    local fh, err = io.open(path, "r")
    if not fh then
        error(err)
    end

    local src = fh:read("*a")
    fh:close()

    local chunk, load_err = load(
        src,
        "@" .. path,
        "t",
        {}  -- empty environment
    )

    if not chunk then
        error(load_err)
    end

    local ok, result = pcall(chunk)
    if not ok then
        error(result)
    end

    if type(result) ~= "table" then
        error("lua data file must return table")
    end

    local valid, verr = validate_literal(result)
    if not valid then
        error("invalid lua data: " .. verr)
    end

    return {
        codec = "lua",
        data  = result,
    }
end

----------------------------------------------------------------
-- Write
----------------------------------------------------------------

---@param value any
---@param indent? integer
---@return string
local function serialize(value, indent)
    indent = indent or 0
    local pad = string.rep("  ", indent)

    local t = type(value)

    if t == "nil" then
        return "nil"
    elseif t == "number" or t == "boolean" then
        return tostring(value)
    elseif t == "string" then
        return string.format("%q", value)
    elseif t == "table" then
        local parts = {}
        parts[#parts + 1] = "{"

        for k, v in pairs(value) do
            local key
            if type(k) == "string" then
                key = string.format("[%q]", k)
            else
                key = "[" .. tostring(k) .. "]"
            end

            parts[#parts + 1] =
                "\n" .. pad .. "  " ..
                key .. " = " ..
                serialize(v, indent + 1) .. ","
        end

        parts[#parts + 1] = "\n" .. pad .. "}"
        return table.concat(parts)
    else
        error("unsupported lua data type: " .. t)
    end
end

---@param path string
---@param value table
---@return true
function LuaCodec.write(path, value)
    if type(value) ~= "table" then
        error("lua write requires table")
    end

    local valid, err = validate_literal(value)
    if not valid then
        error("invalid lua data: " .. err)
    end

    local fh, open_err = io.open(path, "w")
    if not fh then
        error(open_err)
    end

    fh:write("return ", serialize(value), "\n")
    fh:close()

    return true
end

return LuaCodec
