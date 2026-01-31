-- tools/inspection/context.lua
--
-- Shared execution context for inspection router/targets.
-- Contract:
--   ctx.path   : string
--   ctx.state  : table (targets mutate this)
--   ctx.fns.*  : optional helper functions (pure, callable by targets)

local Read      = require("file_handler")
local FromLines = require("ingestion.normalization.from_lines")
local Normalize = require("file_handler.normalize")
local BoardRec  = require("ingestion.normalization.reconcile_board")
local Hydrate   = require("ingestion.hydrate.board")
local Adapter   = require("ingestion.adapter.readfile")
local ParserCap = require("parsers.text_pipeline.capture")

local Context = {}

---@param path string
---@return table
function Context.new(path)
    assert(type(path) == "string" and path ~= "", "Context.new(path): path required")

    local ctx = {
        path  = path,
        state = {},

        -- Optional helpers (not required by Targets, but nice to have)
        fns = {
            read = function(p)
                return Read.read(p)
            end,

            from_lines = function(raw)
                local cap = ParserCap.new()
                local records = FromLines.run(raw, { capture = cap })
                return {
                    records = records,
                    parser  = cap.lines,
                }
            end,

            parse_only = function(raw)
                local cap = ParserCap.new()
                FromLines.run(raw, { capture = cap })
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

            reconcile = function(records)
                return BoardRec.run(records)
            end,

            hydrate = function(specs)
                return Hydrate.boards(specs)
            end,

            ingest = function(p)
                return Adapter.ingest(p)
            end,
        }
    }

    return ctx
end

return Context
