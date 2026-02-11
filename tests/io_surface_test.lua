local IO = require("application.runtime.io")
local BufferSink = require("io.sinks.buffer")

local function banner(name)
    print("\n=== " .. name .. " ===")
end

local function ok(label)
    print("  ✓", label)
end

local function fail(label, err)
    print("  ✗", label, "|", err)
end

----------------------------------------------------------------
-- READ TESTS
----------------------------------------------------------------

banner("READ")

do
    local result = IO.read_strict("data/test_inputs/test_lumber.json")
    assert(result.kind == "json")
    assert(type(result.data) == "table")
    ok("json read")
end

do
    local result = IO.read_strict("data/test_inputs/test_lumber.csv")
    assert(result.kind == "table")
    ok("csv read")
end

do
    local result = IO.read_strict("data/test_inputs/test_lumber.txt")
    assert(result.kind == "lines")
    ok("text read")
end

do
    local result, err = IO.read("nope.json")
    assert(result == nil)
    assert(err)
    ok("missing file handled")
end

do
    local ok_throw = pcall(function()
        IO.read_strict("nope.json")
    end)
    assert(not ok_throw)
    ok("strict read throws")
end

----------------------------------------------------------------
-- WRITE TESTS
----------------------------------------------------------------

banner("WRITE")

do
    local meta = IO.write_strict("data/out/test.json", {
        kind = "json",
        data = { a = 1, b = true }
    })
    assert(meta.size_bytes > 0)
    ok("json write")
end

do
    local meta = IO.write_strict("data/out/test.txt", {
        kind = "lines",
        data = { "a", "b", "c" }
    })
    assert(meta.size_bytes > 0)
    ok("lines write")
end

do
    local meta = IO.write_strict("data/out/test.lua", {
        kind = "lua",
        data = { x = 10 }
    })
    assert(meta.size_bytes > 0)
    ok("lua write")
end

do
    local meta, err = IO.write("data/out/test.invalid", {
        kind = "invalid",
        data = {}
    })
    assert(meta == nil)
    assert(err)
    ok("invalid payload rejected")
end

do
    local ok_throw = pcall(function()
        IO.write_strict("data/out/test.invalid", {
            kind = "invalid",
            data = {}
        })
    end)
    assert(not ok_throw)
    ok("strict write throws")
end

----------------------------------------------------------------
-- STREAM TESTS
----------------------------------------------------------------

banner("STREAM")

do
    local buffer = BufferSink.new()

    local i = 0
    local function iter()
        i = i + 1
        if i <= 3 then
            return "line_" .. i
        end
    end

    IO.stream(iter, buffer)

    assert(#buffer.lines == 3)
    ok("stream to buffer")
end

do
    local ok_throw = pcall(function()
        IO.stream(nil, {})
    end)
    assert(not ok_throw)
    ok("stream invalid iter throws")
end

----------------------------------------------------------------
-- READ BACK WRITTEN FILES
----------------------------------------------------------------

banner("ROUNDTRIP")

do
    local result = IO.read_strict("data/out/test.json")
    assert(result.kind == "json")
    assert(result.data.a == 1)
    ok("json roundtrip")
end

do
    local result = IO.read_strict("data/out/test.lua")
    assert(result.kind == "lua")
    assert(result.data.x == 10)
    ok("lua roundtrip")
end

print("\nALL IO SURFACE TESTS COMPLETED")
