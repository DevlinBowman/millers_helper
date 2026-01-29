-- file_handler/writers/json.lua
local JsonWriter = {}

local function encode(v)
    local t = type(v)
    if t == "nil" then
        return "null"
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "table" then
        local is_array = (#v > 0)
        local out = {}

        if is_array then
            for i = 1, #v do
                out[#out + 1] = encode(v[i])
            end
            return "[" .. table.concat(out, ",") .. "]"
        else
            for k, val in pairs(v) do
                out[#out + 1] =
                    encode(tostring(k)) .. ":" .. encode(val)
            end
            return "{" .. table.concat(out, ",") .. "}"
        end
    else
        error("unsupported JSON type: " .. t)
    end
end

function JsonWriter.write(path, value)
    local fh, err = io.open(path, "w")
    if not fh then return nil, err end

    fh:write(encode(value))
    fh:close()
    return true
end

return JsonWriter
