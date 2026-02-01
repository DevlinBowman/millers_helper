-- tests/view_smoke_test.lua
--
-- Quiet smoke test for debug.view (INGESTION V2)
-- PASS / FAIL only
-- Error details only on failure

local View = require("debug.view")

local INPUT = "tests/data_format/input.txt"

----------------------------------------------------------------
-- Smoke targets (VALID ROUTER PATHS)
----------------------------------------------------------------
local targets = {
    { name = "io",      fn = function() View.io(INPUT) end },
    { name = "records", fn = function() View.run("records", INPUT) end },
    { name = "parser",  fn = function() View.run("text.parser", INPUT) end },
    { name = "ingest",  fn = function() View.ingest(INPUT) end },
    { name = "boards",  fn = function()
        local ingest = View.ingest(INPUT)
        assert(ingest.boards and ingest.boards.data, "boards missing from ingest")
    end },
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
    io.stderr = {
        write = function() end,
        flush = function() end,
    }

    local ok, err = pcall(fn)

    io.stderr = old_stderr
    io.write  = old_write
    print     = old_print

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
