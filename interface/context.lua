-- interface/context.lua

local Context = {}
Context.__index = Context

function Context.new(parsed)
    return setmetatable({
        domain      = parsed.domain,
        action      = parsed.action,
        positionals = parsed.positionals,
        flags       = parsed.flags,
        raw         = parsed.raw,
    }, Context)
end

function Context:die(msg)
    io.stderr:write("error: " .. tostring(msg) .. "\n")
    os.exit(1)
end

function Context:usage()
    return {
        kind   = "usage",
        domain = self.domain,
        action = self.action,
    }
end

return Context
