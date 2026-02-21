-- canopy/runtime/config.lua
--
-- Loads and saves Lua config files safely.

local Config = {}

function Config.load(path)
    local chunk, err = loadfile(path)
    if not chunk then
        error("Failed to load config: " .. err)
    end

    local ok, result = pcall(chunk)
    if not ok then
        error("Error executing config: " .. result)
    end

    if type(result) ~= "table" then
        error("Config must return a table")
    end

    return result
end

local function serialize_table(tbl, indent)
    indent = indent or 0
    local lines = {}
    local prefix = string.rep("    ", indent)

    table.insert(lines, "{")

    for k, v in pairs(tbl) do
        local key = type(k) == "string" and k or "[" .. tostring(k) .. "]"

        if type(v) == "table" then
            local sub = serialize_table(v, indent + 1)
            table.insert(lines,
                prefix .. "    " .. key .. " = " .. sub .. ",")
        elseif type(v) == "string" then
            table.insert(lines,
                prefix .. "    " .. key .. " = " .. string.format("%q", v) .. ",")
        else
            table.insert(lines,
                prefix .. "    " .. key .. " = " .. tostring(v) .. ",")
        end
    end

    table.insert(lines, prefix .. "}")
    return table.concat(lines, "\n")
end

function Config.save(path, tbl)
    local content = "return " .. serialize_table(tbl)

    local file, err = io.open(path, "w")
    if not file then
        error("Failed to write config: " .. err)
    end

    file:write(content)
    file:close()
end

return Config
