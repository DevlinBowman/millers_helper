-- interface/shells/tui/router.lua
--
-- High-level interaction router for TUI.

local Registry = require("interface.registry")
local List     = require("interface.shells.tui.widgets.list")
local Prompts  = require("interface.shells.tui.prompts")

local Router = {}

local function sorted_keys(map, predicate)
    local out = {}
    for k, v in pairs(map or {}) do
        if not predicate or predicate(k, v) then
            out[#out + 1] = k
        end
    end
    table.sort(out)
    return out
end

local function parse_usage_positionals(usage)
    -- Extract "<foo> <bar> <baz...>" from usage
    if not usage then return {} end

    local _, _, tail = usage:find("^%S+%s+%S+%s*(.*)$")
    if not tail then return {} end

    local fields = {}
    for token in tail:gmatch("<([^>]+)>") do
        fields[#fields + 1] = token
    end

    return fields
end

function Router.run(state)
    io.stderr:write("[TUI] router start\n")
    io.stderr:flush()

    local domains_map = Registry.domains_all()
    local domains = sorted_keys(domains_map)

    if #domains == 0 then
        io.stderr:write("[TUI] no domains registered\n")
        io.stderr:flush()
        return nil
    end

    -- 1) Select domain
    local domain = List.select("Select domain", domains)
    if not domain then return nil end

    local actions_map = domains_map[domain]
    local actions = sorted_keys(actions_map, function(name)
        return name:sub(1, 1) ~= "_"
    end)

    -- 2) Select command
    local action = List.select("Select command", actions)
    if not action then return nil end

    local spec = Registry.resolve(domain, action)
    if not spec then
        return nil
    end

    ----------------------------------------------------------------
    -- 3) Collect positional arguments
    ----------------------------------------------------------------

    local positionals = {}
    local usage = spec.help and spec.help.usage
    local fields = parse_usage_positionals(usage)

    for _, field in ipairs(fields) do
        if field:sub(-3) == "..." then
            local label = field:sub(1, -4)
            local values = Prompts.ask_many("Enter " .. label)
            for _, v in ipairs(values) do
                positionals[#positionals + 1] = v
            end
        else
            local v = Prompts.ask("Enter " .. field)
            if v and v ~= "" then
                positionals[#positionals + 1] = v
            end
        end
    end

    ----------------------------------------------------------------
    -- 4) Flags (later — stubbed cleanly)
    ----------------------------------------------------------------

    local flags = {}

    return {
        domain      = domain,
        action      = action,
        positionals = positionals,
        flags       = flags,
    }
end

return Router
