local Format = require("application.runtime.format")

local function banner(name)
    print("\n=== " .. name .. " ===")
end

local function ok(label)
    print("  ✓", label)
end

----------------------------------------------------------------
-- JSON → RECORDS
----------------------------------------------------------------

banner("JSON")

do
    local result = Format.to_records_strict("json", {
        { a = 1 },
        { a = 2 },
    })

    assert(result.kind == "records")
    assert(#result.data == 2)
    ok("json array → records")
end

do
    local result = Format.to_records_strict("json", {
        a = 1,
        b = 2,
    })

    assert(result.kind == "records")
    assert(#result.data == 1)
    ok("json object → singleton record")
end

----------------------------------------------------------------
-- TABLE → RECORDS
----------------------------------------------------------------

banner("TABLE")

do
    local result = Format.to_records_strict("table", {
        header = { "a", "b" },
        rows = {
            { "1", "2" },
            { "3", "4" },
        }
    })

    assert(result.kind == "records")
    assert(result.data[1].a == "1")
    ok("table → records")
end

----------------------------------------------------------------
-- LINES → ERROR
----------------------------------------------------------------

banner("LINES")

do
    local result, err = Format.to_records("lines", { "a", "b" })
    assert(result == nil)
    assert(err)
    ok("lines rejected")
end

----------------------------------------------------------------
-- UNSUPPORTED KIND
----------------------------------------------------------------

banner("UNSUPPORTED")

do
    local result, err = Format.to_records("unknown", {})
    assert(result == nil)
    assert(err)
    ok("unsupported kind rejected")
end

----------------------------------------------------------------
-- STRICT FAILURE
----------------------------------------------------------------

banner("STRICT")

do
    local ok_throw = pcall(function()
        Format.to_records_strict("lines", { "a" })
    end)
    assert(not ok_throw)
    ok("strict throws")
end

print("\nALL FORMAT SURFACE TESTS COMPLETED")
