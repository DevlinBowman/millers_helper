-- file_handler/init.lua
local FS        = require("file_handler.fs")
local Text      = require("file_handler.readers.text")
local Delimited = require("file_handler.readers.delimited")
local Json      = require("file_handler.readers.json")
local TextW      = require("file_handler.writers.text")
local DelimitedW = require("file_handler.writers.delimited")
local JsonW      = require("file_handler.writers.json")
local Normalize = require("file_handler.normalize")

local Reader    = {}

local DISPATCH  = {
    txt  = Text.read,
    md   = Text.read,
    csv  = function(p) return Delimited.read(p, ",") end,
    tsv  = function(p) return Delimited.read(p, "\t") end,
    json = Json.read,
}

function Reader.assert_kind(result, expected_kind)
    if not result or result.kind ~= expected_kind then
        return nil, string.format(
            "expected kind '%s', got '%s'",
            expected_kind,
            result and result.kind or "nil"
        )
    end
    return true
end

function Reader.read(path, opts)
    opts = opts or {}

    if not FS.file_exists(path) then
        return nil, "file does not exist: " .. tostring(path)
    end

    local ext = FS.get_extension(path)
    if not ext then
        return nil, "file has no extension"
    end

    local reader = DISPATCH[ext:lower()]
    if not reader then
        return nil, "unsupported file type: " .. tostring(ext)
    end

    local result, err = reader(path)
    if not result then
        return nil, err
    end
    -- for _, l in pairs(result.data) do print(_,l) end

    -- ----------------------------
    -- Metadata enrichment (unchanged)
    -- ----------------------------
    local now = os.time()

    local item_count = 0
    if result.kind == "lines" then
        item_count = #result.data
    elseif result.kind == "table" then
        item_count = #result.data.rows
    elseif result.kind == "json" then
        item_count = type(result.data) == "table" and (#result.data > 0 and #result.data or 1) or 1
    end

    result.meta = {
        path             = path,
        filename         = FS.get_filename(path),
        ext              = ext:lower(),
        size_bytes       = FS.file_size(path),
        hash             = FS.file_hash(path),
        read_time_epoch  = now,
        read_time_iso    = os.date("%Y-%m-%d %H:%M:%S", now),
        item_count       = item_count,
    }

    -- ----------------------------
    -- Optional normalization
    -- ----------------------------
    if opts.normalize then
        if result.kind == "lines" then
            print('TEXT_FILE')
            return
        elseif result.kind == "table" then
            local norm = Normalize.table(result)
            norm.meta = result.meta
            return norm
        elseif result.kind == "json" then
            local norm, nerr = Normalize.json(result)
            if not norm then return nil, nerr end
            norm.meta = result.meta
            return norm
        else
            return nil, "cannot normalize kind: " .. result.kind
        end
    end

    return result
end


local WRITE_DISPATCH = {
    lines = TextW.write,
    table = function(p, d, ext)
        local sep = (ext == "tsv") and "\t" or ","
        return DelimitedW.write(p, d, sep)
    end,
    json  = JsonW.write,
}

function Reader.write(path, kind, data)
    assert(type(path) == "string", "path required")
    assert(type(kind) == "string", "kind required")

    local ext = FS.get_extension(path)
    if not ext then
        return nil, "output file must have extension"
    end

    FS.ensure_parent_dir(path)

    local writer = WRITE_DISPATCH[kind]
    if not writer then
        return nil, "unsupported write kind: " .. kind
    end

    local ok, err = writer(path, data, ext:lower())
    if not ok then
        return nil, err
    end

    return {
        path       = path,
        ext        = ext:lower(),
        size_bytes = FS.file_size(path),
        hash       = FS.file_hash(path),
        write_time = os.date("%Y-%m-%d %H:%M:%S"),
    }
end
return Reader
