-- interface/domains/compare/menu.lua

local M = {}

function M.handle(input, session, cli_run)

    session.input_path  = session.input_path
    session.vendor_paths = session.vendor_paths or {}

    ------------------------------------------------------------
    -- Set input
    ------------------------------------------------------------

    if input:match("^input%s+") then
        session.input_path = input:match("^input%s+(.+)")
        print("input set")
        return
    end

    ------------------------------------------------------------
    -- Add vendor
    ------------------------------------------------------------

    if input:match("^vendor%s+") then
        local path = input:match("^vendor%s+(.+)")
        table.insert(session.vendor_paths, path)
        print("vendor added")
        return
    end

    ------------------------------------------------------------
    -- Run compare
    ------------------------------------------------------------

    if input == "run" then

        if not session.input_path then
            print("missing input")
            return
        end

        if #session.vendor_paths == 0 then
            print("missing vendor")
            return
        end

        local argv = {"compare", session.input_path}
        for _, v in ipairs(session.vendor_paths) do
            table.insert(argv, v)
        end

        cli_run(argv)
        return
    end

    print("compare commands:")
    print("  input <path>")
    print("  vendor <path>")
    print("  run")
end

return M
