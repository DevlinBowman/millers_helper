local Entrypoint = require("system.entrypoint")
local Backend    = require("system.backend")

local entry      = Entrypoint.new()

local function decode(input)
    if type(input) ~= "string" or input == "" then
        return nil
    end

    local chunk = load("return " .. input, "request", "t", {})
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
        local t = type(v)

        if t == "string" then
            return string.format("%q", v)
        elseif t == "number" or t == "boolean" then
            return tostring(v)
        elseif t == "table" then
            local parts = {}

            for k, val in pairs(v) do
                parts[#parts + 1] =
                    "[" .. serialize(k) .. "]=" .. serialize(val)
            end

            return "{" .. table.concat(parts, ",") .. "}"
        else
            return "nil"
        end
    end

    return serialize(value)
end

local input   = io.read("*a")
local request = decode(input)

if not request then
    io.write(encode({ ok = false, error = "invalid_request" }))
    return
end

------------------------------------------------
-- expose backend runtime state
------------------------------------------------

if request.command == "inspect_state" then

    local instance = "default"

    if request.args and request.args.instance then
        instance = request.args.instance
    end

    local app = Backend.run(instance)
    local runtime = app:data():runtime()

    local state = {
        intent = app:data():intent():inspect(),

        resources = app:data():resources(),

        runtime = {
            system_vendor_count =
                #(runtime:batches("system","vendor") or {}),

            user_job_count =
                #(runtime:batches("user","job") or {})
        }
    }

    io.write(encode({
        ok = true,
        state = state
    }))

    io.flush()
    return
end

------------------------------------------------
-- normal command routing
------------------------------------------------

local result = entry:handle(request)

-- if service supports print(), capture it
if type(result) == "table" and type(result.print) == "function" then

    local buffer = {}

    local original_print = print

    print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[#parts+1] = tostring(select(i,...))
        end
        buffer[#buffer+1] = table.concat(parts, "\t")
    end

    local ok, err = pcall(function()
        result:print()
    end)

    print = original_print

    if not ok then
        io.write(encode({
            ok=false,
            error="print_failed",
            message=err
        }))
        io.flush()
        return
    end

    io.write(encode({
        ok=true,
        output=table.concat(buffer,"\n")
    }))
    io.flush()
    return
end

-- fallback: return raw result
io.write(encode(result))
io.flush()


