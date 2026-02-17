-- tools/system_index/internal/format.lua

local Format = {}

local function sorted_keys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

function Format.render_snapshot(snapshot)
    local lines = {}

    table.insert(lines, "SYSTEM INDEX\n")

    local modules = snapshot.modules or {}
    local module_names = sorted_keys(modules)

    for _, module_name in ipairs(module_names) do
        local data = modules[module_name]

        table.insert(lines, "MODULE: " .. module_name)

        if data.controller_surface then
            table.insert(lines, "  controller:")
            local fn_names = sorted_keys(data.controller_surface)

            for _, fn in ipairs(fn_names) do
                table.insert(lines, "    - " .. fn)
            end
        end

        if data.contracts then
            table.insert(lines, "  contracts:")
            local contract_names = sorted_keys(data.contracts)

            for _, cname in ipairs(contract_names) do
                local spec = data.contracts[cname]

                table.insert(lines, "    " .. cname .. ":")

                if spec.in_ then
                    table.insert(lines,
                        "      in:  " ..
                        table.concat(sorted_keys(spec.in_), ", ")
                    )
                end

                if spec.out then
                    table.insert(lines,
                        "      out: " ..
                        table.concat(sorted_keys(spec.out), ", ")
                    )
                end
            end
        end

        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

function Format.render_diff(diff)
    local lines = {}

    table.insert(lines, "COVERAGE DIFF\n")

    table.insert(lines, "Missing Modules:")
    for _, name in ipairs(diff.missing or {}) do
        table.insert(lines, "  - " .. name)
    end

    table.insert(lines, "\nNew Modules:")
    for _, name in ipairs(diff.new or {}) do
        table.insert(lines, "  + " .. name)
    end

    return table.concat(lines, "\n")
end

return Format
