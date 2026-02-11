-- format/unwrap.lua
--
-- Extracts write-ready data from known envelopes.
-- Pure projection. No validation.

local M = {}

function M.run(value)
    if type(value) == "table"
        and value.kind
        and value.data
    then
        return value.data
    end

    return value
end

return M
