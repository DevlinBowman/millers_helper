-- ingestion/adapter/readfile.lua

local Pipeline = require("ingestion.pipeline")

local Adapter = {}

function Adapter.ingest(path, opts)
    local result, err = Pipeline.run_file(path, opts)
    if not result then return nil, err end
    return result
end

return Adapter
