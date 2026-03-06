-- core/schema/engine/runtime/reference_index.lua

local State = require("core.schema.engine.runtime.state")

local ReferenceIndex = {}

function ReferenceIndex.build()

    local index = {}

    local domains = State.values or {}

    for domain_name,_ in pairs(domains) do

        local parts = {}

        for part in string.gmatch(domain_name, "[^.]+") do
            parts[#parts+1] = part
        end

        local ref = parts[#parts]

        if ref then
            index[ref] = domain_name
        end

    end

    State.reference_index = index

end

return ReferenceIndex
