-- cli/parser.lua
--
-- Argument vector parser.
--
-- Responsibilities:
--   • Convert raw argv into structured intent:
--       { domain, action, positionals, flags }
--   • Support short and long flags
--   • Handle combined short flags (-ckv)
--   • Remain domain-agnostic
--
-- This module does NOT execute commands.
-- It only interprets command-line syntax.
--
-- argv → { domain, action, positionals, flags }
--
-- Supports:
--   • <domain> <action> [pos...] [flags...]
--   • default_domain mode: <action> [pos...] [flags...]
-- Flags:
--   • --long
--   • --long=value
--   • --long value
--   • -k
--   • -ck  (combined short flags)

local Parser = {}

local function is_flag(s)
    return type(s) == "string" and s:match("^%-") ~= nil
end

local function take(argv)
    return table.remove(argv, 1)
end

--- Parse argv into intent
--- @param argv table
--- @param opts table|nil { default_domain?: string }
function Parser.parse(argv, opts)
    opts = opts or {}
    assert(type(argv) == "table", "argv must be table")

    -- copy so callers can reuse argv table if they want
    local args = {}
    for i = 1, #argv do args[i] = argv[i] end

    if #args == 0 then
        error("no command provided")
    end

    local domain
    local action

    if opts.default_domain then
        domain = opts.default_domain
        action = take(args)
        if not action then
            error("missing action for domain: " .. tostring(domain))
        end
    else
        domain = take(args)
        action = take(args)
        if not action then
            error("missing action for domain: " .. tostring(domain))
        end
    end

    local positionals = {}
    local flags = {}

    while #args > 0 do
        local arg = take(args)

        -- long flag
        if arg:sub(1, 2) == "--" then
            local body = arg:sub(3)

            -- --key=value
            local k, v = body:match("^([^=]+)=(.*)$")
            if k then
                flags[k] = v
            else
                local key = body
                -- --key <value> (only if next token exists and is not a flag)
                if #args > 0 and not is_flag(args[1]) then
                    flags[key] = take(args)
                else
                    flags[key] = true
                end
            end

            -- short flag(s)
        elseif arg:sub(1, 1) == "-" and #arg > 1 then
            local body = arg:sub(2)

            -- single short flag: -o <value> OR -v
            if #body == 1 then
                local key = body

                -- value form: -o <value>
                if #args > 0 and not is_flag(args[1]) then
                    flags[key] = take(args)
                else
                    flags[key] = true
                end

                -- combined flags: -ckv
            else
                for i = 1, #body do
                    local ch = body:sub(i, i)
                    flags[ch] = true
                end
            end

            -- positional
        else
            positionals[#positionals + 1] = arg
        end
    end

    return {
        domain      = domain,
        action      = action,
        positionals = positionals,
        flags       = flags,
        raw         = argv,
    }
end

return Parser
