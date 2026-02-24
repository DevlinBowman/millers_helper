-- platform/selector/internal/format_error.lua
--
-- Converts structured selector failure into human-readable message.

local Format = {}

local function build_path(path)
    if not path or #path == 0 then
        return "(root)"
    end

    local parts = {}

    for i, v in ipairs(path) do
        if type(v) == "number" then
            parts[#parts + 1] = "[" .. v .. "]"
        else
            if i == 1 then
                parts[#parts + 1] = v
            else
                parts[#parts + 1] = "." .. v
            end
        end
    end

    return table.concat(parts)
end

function Format.run(failure, opts)
    opts = opts or {}

    local label = opts.label or "root"

    if not failure then
        return "[SELECTOR] > unknown failure"
    end

    if failure.reason == "nil_root" then
        return string.format(
            "[SELECTOR] > %s is nil",
            label
        )
    end

    if failure.reason == "invalid_tokens" then
        return string.format(
            "[SELECTOR] > %s invalid tokens: %s",
            label,
            tostring(failure.message)
        )
    end

    local path_str = build_path(failure.path)

    if failure.reason == "missing_key" then
        return string.format(
            "[SELECTOR] > %s.%s missing key/index '%s'",
            label,
            path_str,
            tostring(failure.key)
        )
    end

    if failure.reason == "non_table_index" then
        return string.format(
            "[SELECTOR] > %s.%s attempted index on %s",
            label,
            path_str,
            failure.current_type
        )
    end

    return string.format(
        "[SELECTOR] > %s.%s failed (%s)",
        label,
        path_str,
        tostring(failure.reason)
    )
end

return Format
