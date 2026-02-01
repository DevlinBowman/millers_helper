-- cli/context.lua

local Context = {}
Context.__index = Context

function Context.new(parsed)
    return setmetatable({
        domain      = parsed.domain,
        action      = parsed.action,
        positionals = parsed.positionals,
        flags       = parsed.flags,
        raw         = parsed.raw,
        stdout      = io.stdout,
        stderr      = io.stderr,
    }, Context)
end

function Context:die(msg)
    self.stderr:write("error: " .. msg .. "\n")
    os.exit(1)
end

function Context:note(msg)
    self.stderr:write(msg .. "\n")
end

function Context:usage()
    -- signal to CLI runner that usage was requested
    return {
        kind = "usage",
        domain = self.domain,
        action = self.action,
    }
end

return Context
