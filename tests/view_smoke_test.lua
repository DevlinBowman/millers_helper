-- tests/view_smoke_test.lua
--
-- Quiet smoke test for debug.view (INGESTION V2)
-- PASS / FAIL only
-- Error details only on failure

local View = require("debug.view")

local INPUT = "tests/data_format/input.txt"

local targets = {
    { name = "io",     fn = function() View.io(INPUT) end },
    { name = "text",   fn = function() View.text(INPUT) end },
    { name = "parser", fn = function() View.parser(INPUT) end },
    { name = "boards", fn = function() View.boards(INPUT) end },
    { name = "ingest", fn = function() View.ingest(INPUT) end },
}

----------------------------------------------------------------
-- Output suppression
----------------------------------------------------------------
local function silence(fn)
    local old_print  = print
    local old_write  = io.write
    local old_stderr = io.stderr

    print = function() end
    io.write = function() end
    io.stderr = { write = function() end }

    local ok, err = pcall(fn)

    print = old_print
    io.write = old_write
    io.stderr = old_stderr

    return ok, err
end

----------------------------------------------------------------
-- Run tests
----------------------------------------------------------------
local failed = false

print("\nVIEW SMOKE TEST (INGESTION V2)\n")

for _, t in ipairs(targets) do
    io.write(string.format("• %-8s ", t.name))

    local ok, err = silence(t.fn)

    if ok then
        print("PASS")
    else
        print("FAIL")
        print("  error:")
        print("  " .. tostring(err))
        failed = true
    end
end

if failed then
    print("\nRESULT: FAIL\n")
    os.exit(1)
else
    print("\nRESULT: PASS\n")
end
