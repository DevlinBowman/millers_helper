local IO     = require("platform.io.controller")
local Format = require("platform.format.controller")
local Trace  = require("tools.trace.trace")

Trace.set(false)

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

local INPUT_FILE = "data/test_inputs/test_lumber.json"

-- All codecs the system should support
local CODECS = {
    "json",
    "lua",
    "delimited",
    "lines",
}

-- Codecs allowed to identity-encode
local IDENTITY_CODECS = {
    json = true,
    lua  = true,
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function assert_ok(val, err)
    if not val then
        error(err or "unexpected failure", 2)
    end
end

local function assert_eq(a, b, msg)
    if a ~= b then
        error(msg or (tostring(a) .. " ~= " .. tostring(b)), 2)
    end
end

local function print_section(title)
    print("\n=== " .. title .. " ===")
end

----------------------------------------------------------------
-- Begin
----------------------------------------------------------------

print_section("READ")

local raw, read_err = IO.read(INPUT_FILE)
assert_ok(raw, read_err)

assert(type(raw.codec) == "string", "raw.codec must be string")
assert(raw.data ~= nil, "raw.data required")

print("read ok (" .. raw.codec .. ")")

----------------------------------------------------------------
-- DECODE
----------------------------------------------------------------

print_section("DECODE")

local decoded, decode_err = Format.decode(raw.codec, raw.data)
assert_ok(decoded, decode_err)

assert_eq(decoded.codec, "objects", "decode must return codec='objects'")
assert(type(decoded.data) == "table", "decoded.data must be table")

print("decode ok")

----------------------------------------------------------------
-- ENCODE PERMUTATIONS
----------------------------------------------------------------

print_section("ENCODE PERMUTATIONS")

for _, target in ipairs(CODECS) do

    print("encoding to " .. target)

    local encoded, err = Format.encode(target, decoded.data)

    if not encoded then
        error("encode failed for codec '" .. target .. "': " .. tostring(err))
    end

    assert_eq(encoded.codec, target, "encode must preserve target codec")
    assert(encoded.data ~= nil, "encoded.data required")

    print("  encode ok")

    ----------------------------------------------------------------
    -- WRITE
    ----------------------------------------------------------------

    local ext_map = {
        json      = "json",
        lua       = "lua",
        delimited = "csv",
        lines     = "txt",
    }

    local out_path = "data/out/permutation_" .. target .. "." .. ext_map[target]

    local meta, write_err = IO.write(out_path, encoded)
    assert_ok(meta, write_err)

    assert(type(meta.size_bytes) == "number", "write meta invalid")

    print("  write ok")
end

----------------------------------------------------------------
-- UNKNOWN CODEC GUARD
----------------------------------------------------------------

print_section("UNKNOWN CODEC GUARD")

local bad_encoded, bad_err = Format.encode("bogus_codec", decoded.data)

if bad_encoded then
    error("unknown codec should not encode")
end

print("unknown encode rejected correctly")

----------------------------------------------------------------
-- WRITE UNKNOWN CODEC GUARD
----------------------------------------------------------------

local bogus_payload = {
    codec = "bogus_codec",
    data  = decoded.data,
}

local meta, err = IO.write("data/out/bogus.xyz", bogus_payload)

if meta then
    error("unknown write codec should not succeed")
end

print("unknown write rejected correctly")

----------------------------------------------------------------
-- DONE
----------------------------------------------------------------

print("\nALL PERMUTATION TESTS PASSED\n")
