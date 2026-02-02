-- cli/context.lua
--
-- Invocation context for CLI command execution.
--
-- Responsibilities:
--   • Carry parsed command intent (args, flags)
--   • Provide standard IO handles (stdout, stderr)
--   • Expose helper methods for errors, notes, and usage
--
-- Context is passed through the CLI → controller boundary.
-- It is the primary execution envelope for commands.

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
