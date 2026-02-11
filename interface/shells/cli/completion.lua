-- interface/shells/cli/completion.lua

local Registry = require("interface.registry")

local Completion = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function starts_with(str, prefix)
    prefix = prefix or ""
    return str:sub(1, #prefix) == prefix
end

local function print_list(list)
    for _, item in ipairs(list or {}) do
        io.stdout:write(item)
        io.stdout:write("\n")
    end
end

local function filter_keys(map, prefix, ignore_private)
    local out = {}
    for k in pairs(map or {}) do
        if (not ignore_private or k:sub(1,1) ~= "_")
           and starts_with(k, prefix) then
            out[#out + 1] = k
        end
    end
    table.sort(out)
    return out
end

local function extract_flags(spec, prefix)
    local out = {}

    if not spec.help or not spec.help.options then
        return out
    end

    for _, opt in ipairs(spec.help.options) do
        for flag in opt[1]:gmatch("%-%-?[%w-]+") do
            if starts_with(flag, prefix) then
                out[#out + 1] = flag
            end
        end
    end

    table.sort(out)
    return out
end

----------------------------------------------------------------
-- Main
----------------------------------------------------------------

function Completion.run(argv)
    argv = argv or {}

    local domains  = Registry.domains_all()
    local position = #argv
    local prefix   = argv[position] or ""

    ----------------------------------------------------------------
    -- DOMAIN
    ----------------------------------------------------------------

    if position <= 1 then
        return print_list(filter_keys(domains, prefix))
    end

    local domain = argv[1]
    if not domains[domain] then
        return print_list(filter_keys(domains, prefix))
    end

    ----------------------------------------------------------------
    -- ACTION
    ----------------------------------------------------------------

    if position == 2 then
        return print_list(filter_keys(domains[domain], prefix, true))
    end

    local action = argv[2]
    local spec   = domains[domain][action]

    if not spec then
        return print_list(filter_keys(domains[domain], prefix, true))
    end

    ----------------------------------------------------------------
    -- AFTER ACTION (true command context)
    ----------------------------------------------------------------

    local candidates = {}

    --  Flags are ALWAYS valid after action
    local flags = extract_flags(spec, prefix)
    for _, f in ipairs(flags) do
        candidates[#candidates + 1] = f
    end

    -- If prefix does not start with "-", we allow positional fallback.
    -- We do NOT add anything here; zsh will handle file completion.
    --
    -- If flags matched, we return them.
    -- If flags did not match, we return nothing → zsh handles files.

    if #candidates > 0 then
        return print_list(candidates)
    end

    return
end

return Completion
