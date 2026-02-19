-- interface/domains/ledger/menu.lua

local M = {}

local function split_words(line)
    local out = {}
    for w in tostring(line or ""):gmatch("%S+") do
        out[#out + 1] = w
    end
    return out
end

local function print_help()
    print("ledger commands:")
    print("  ledger <path>            set ledger path")
    print("  inspect                  list ledger index")
    print("  browse                   alias of inspect")
    print("  open <id|index>          open full bundle")
    print("  ingest <input_path>      runtime load -> commit")
    print("  browser                  interactive arrow browser")
    print("  back                     return to app mode")
end

function M.handle(controller, line)

    local parts = split_words(line)
    local cmd   = parts[1]

    if not cmd or cmd == "" then
        print_help()
        return
    end

    if cmd == "help" or cmd == "?" then
        print_help()
        return
    end

    if cmd == "back" then
        return "back"
    end

    ------------------------------------------------------------
    -- Build ctx
    ------------------------------------------------------------

    local ctx = {
        positionals = {},
        flags = {},
        usage = function() print_help() end,
        die = function(_, msg)
            io.stderr:write("error: " .. tostring(msg) .. "\n")
        end,
    }

    for i = 2, #parts do
        ctx.positionals[#ctx.positionals + 1] = parts[i]
    end

    ------------------------------------------------------------
    -- Direct dispatch (NO registry indirection)
    ------------------------------------------------------------

    if cmd == "ledger" then
        return controller:ledger(ctx)

    elseif cmd == "inspect" then
        return controller:inspect(ctx)

    elseif cmd == "browse" then
        return controller:browse(ctx)

    elseif cmd == "open" then
        return controller:open(ctx)

    elseif cmd == "ingest" then
        return controller:ingest(ctx)

    elseif cmd == "browser" then
        return controller:browser()

    else
        print_help()
    end
end

return M
