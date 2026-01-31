-- ingestion/adapter/readfile.lua

local Pipeline = require("ingestion.pipeline")

local Adapter = {}

function Adapter.ingest(path, opts, debug_opts)
    opts = opts or {}
    debug_opts = debug_opts or {}

    local result, err = Pipeline.run_file(path, opts, debug_opts)
    if not result then
        return nil, err
    end

    return result
end

return Adapter
