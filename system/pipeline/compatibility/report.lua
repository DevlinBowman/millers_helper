-- system/pipeline/compatibility/report.lua

local Report = {}

---@param result table
---@return string
function Report.render(result)
    assert(type(result) == "table", "[compatibility.report] result required")

    if result.ok then
        return "context compatible"
    end

    local out = { "missing capabilities:" }

    for _, cap in ipairs(result.missing or {}) do
        out[#out + 1] = " - " .. tostring(cap)
    end

    return table.concat(out, "\n")
end

---@param result table
function Report.print(result)
    print(Report.render(result))
end

return Report
