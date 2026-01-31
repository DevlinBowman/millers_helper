-- app/run.lua
--
-- Central execution controller for ingestion + inspection

local Inspector = require("tools.inspection.inspector")
local Capture   = require("tools.inspection.capture")
local Stages    = require("tools.inspection.stages")

local Adapter   = require("ingestion.adapter.readfile")

local Run = {}

---@param config table
---@return table
function Run.execute(config)
    assert(type(config) == "table", "run config required")
    assert(config.input, "config.input required")

    local result = {}

    ----------------------------------------------------------------
    -- INSPECTION
    ----------------------------------------------------------------
    if config.mode == "inspect" or config.mode == "both" then
        local cap = nil

        if config.inspect and config.inspect.capture then
            cap = Capture.new()
        end

        local state = Inspector.run(config.input, {
            stop_at = config.inspect and config.inspect.stop_at,
            capture = cap,
        })

        result.inspect = {
            state   = state,
            capture = cap,
        }

        if config.mode == "inspect" then
            return result
        end
    end

    ----------------------------------------------------------------
    -- INGESTION (production path)
    ----------------------------------------------------------------
    if config.mode == "ingest" or config.mode == "both" then
        local boards = Adapter.ingest(config.input)
        result.ingest = boards
    end

    return result
end

return Run
