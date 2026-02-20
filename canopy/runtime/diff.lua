local Diff = {}

local function compare_tables(old, new, path, changes)
    path = path or {}
    changes = changes or {}

    for k, v in pairs(new) do
        local current_path = { unpack(path) }
        table.insert(current_path, k)

        if type(v) == "table" and type(old[k]) == "table" then
            compare_tables(old[k], v, current_path, changes)
        else
            if old[k] ~= v then
                table.insert(changes, {
                    path = table.concat(current_path, "."),
                    old = old[k],
                    new = v,
                })
            end
        end
    end

    return changes
end

function Diff.compute(old_model, new_model)
    return compare_tables(old_model or {}, new_model or {})
end

return Diff
