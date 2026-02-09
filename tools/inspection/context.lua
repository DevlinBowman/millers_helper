-- tools/inspection/context.lua
--
-- Shared execution context for inspection router/targets.
-- Contract:
--   ctx.path   : string
--   ctx.state  : table (targets mutate this)
--   ctx.fns.*  : optional helper functions (pure, callable by targets)

local Read       = require("io.read")
local Normalize  = require("io.normalize")
local ReaderV2   = require("ingestion.reader")
local AdapterV2  = require("ingestion.adapter")
local ParserCap  = require("parsers.text_pipeline.capture")
local TextParser = require("parsers.text_pipeline")

local Context = {}

---@param path string
---@return table
function Context.new(path)
    assert(type(path) == "string" and path ~= "", "Context.new(path): path required")

    local ctx = {
        path  = path,
        state = {},
        fns = {
            read_raw = function(p)
                return Read.read(p)
            end,

            records = function(p, opts)
                return ReaderV2.read(p, opts)
            end,

            ingest = function(p, opts)
                return AdapterV2.ingest(p, opts)
            end,

            parse_only = function(raw_lines, opts)
                opts = opts or {}
                local cap = ParserCap.new()
                TextParser.run(raw_lines, {
                    capture = cap,
                })
                return cap.lines
            end,

            normalize = function(raw)
                if raw.kind == "table" then
                    return Normalize.table(raw)
                elseif raw.kind == "json" then
                    return Normalize.json(raw)
                end
                return raw
            end,
        }
    }

    return ctx
end

return Context
