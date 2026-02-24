-- platform/selector/internal/walk.lua
--
-- Deterministic structural traversal.
-- Precise failure diagnostics.


local Walk = {}

function Walk.run(root, tokens)
    if root == nil then
        return nil, {
            step = 0,
            reason = "nil_root",
            key = nil,
            current_type = "nil",
            path = {},
        }
    end

    local current = root
    local path_trace = {}

    for i, key in ipairs(tokens) do
        path_trace[#path_trace + 1] = key

        if type(current) ~= "table" then
            return nil, {
                step = i,
                reason = "non_table_index",
                key = key,
                current_type = type(current),
                path = path_trace,
            }
        end

        if current[key] == nil then
            return nil, {
                step = i,
                reason = "missing_key",
                key = key,
                current_type = "table",
                path = path_trace,
            }
        end

        current = current[key]
    end

    return current
end

return Walk
