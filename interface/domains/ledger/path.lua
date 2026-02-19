local Session = require("interface.session")

local M = {}

function M.resolve(ctx)

    local path = (ctx and ctx.flags and ctx.flags.ledger)
                 or Session.get_ledger_path()

    if not path then
        io.write("ledger path not set. Enter path: ")
        local input = io.read()

        if input and input ~= "" then
            Session.set_ledger_path(input)
            print("ledger set:", input)
            return input
        end

        io.stderr:write("ledger required\n")
        return nil
    end

    return path
end

return M
