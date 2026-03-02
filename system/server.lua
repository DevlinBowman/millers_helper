local Entrypoint = require("system.entrypoint")

local entry = Entrypoint.new()

local function decode(input)
    if type(input) ~= "string" or input == "" then
        return nil
    end

    local chunk, err = load("return " .. input, "request", "t", {})
    if not chunk then
        return nil
    end

    local ok, result = pcall(chunk)
    if not ok then
        return nil
    end

    if type(result) ~= "table" then
        return nil
    end

    return result
end

local function encode(value)
    local function serialize(v)
        if type(v) == "string" then
            return string.format("%q", v)
        elseif type(v) == "number" or type(v) == "boolean" then
            return tostring(v)
        elseif type(v) == "table" then
            local parts = {}
            for k, val in pairs(v) do
                table.insert(parts,
                    "[" .. serialize(k) .. "]=" .. serialize(val))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        else
            return "nil"
        end
    end
    return serialize(value)
end

local input = io.read("*a")
local request = decode(input)

if not request then
    io.write(encode({ ok=false, error="invalid_request" }))
    return
end

local result = entry:handle(request)

io.write(encode(result))
io.flush()
