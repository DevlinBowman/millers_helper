-- tests/run.lua
--
-- Minimal test suite runner.
--
-- Guarantees:
--   • No test framework dependency
--   • Deterministic order
--   • PASS / FAIL summary
--   • Stack traces only on failure
--   • Suitable for CI or local use
--
-- Usage:
--   lua tests/run.lua
--   lua tests/run.lua view ingest

local tests = {
    "tests/view_smoke_test.lua",

    "tests/reader_smoke_test.lua",
    "tests/parser_multi_input_test.lua",

    "tests/ingest_contract_test.lua",
    "tests/ingest_signals_test.lua",
    "tests/board_invariants_test.lua",
}

----------------------------------------------------------------
-- Optional CLI filtering
----------------------------------------------------------------
local filter = {}
for i = 1, #arg do
    filter[arg[i]] = true
end

local function should_run(path)
    if next(filter) == nil then
        return true
    end

    for key in pairs(filter) do
        if path:find(key, 1, true) then
            return true
        end
    end

    return false
end

----------------------------------------------------------------
-- Runner
----------------------------------------------------------------

local total  = 0
local passed = 0
local failed = 0

print("\nTEST SUITE (INGESTION V2)")
print(string.rep("-", 72))

for _, path in ipairs(tests) do
    if should_run(path) then
        total = total + 1
        io.write(string.format("• %-40s ", path))

        local ok, err = pcall(dofile, path)

        if ok then
            passed = passed + 1
            print("PASS")
        else
            failed = failed + 1
            print("FAIL")
            print("  error:")
            print("  " .. tostring(err))
        end
    end
end

----------------------------------------------------------------
-- Summary
----------------------------------------------------------------

print("\n" .. string.rep("-", 72))
print(string.format(
    "RESULT: %d total | %d passed | %d failed",
    total, passed, failed
))
print(string.rep("-", 72))

if failed > 0 then
    os.exit(1)
end
