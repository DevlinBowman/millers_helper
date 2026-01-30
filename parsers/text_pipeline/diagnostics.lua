-- parsers/text_pipeline/diagnostics.lua
--
-- Diagnostic extraction

local Usage = require("parsers.text_pipeline.token_usage")

local Diag = {}

----------------------------------------------------------------
-- Unused text (semantic)
----------------------------------------------------------------

function Diag.find_unused_groups(record)
    local unused, current = {}, nil

    for i, t in ipairs(record._tokens or {}) do
        local is_ws   = (t.lex == "ws")
        local entries = record._token_usage[i]
        local used    = Usage.is_semantically_touched(entries)

        if not used and not is_ws then
            if not current then
                current = { text = t.raw, from = t.index, to = t.index }
            else
                current.text = current.text .. t.raw
                current.to   = t.index
            end
        else
            if current then
                unused[#unused + 1] = current
                current = nil
            end
        end
    end

    if current then unused[#unused + 1] = current end
    return unused
end

----------------------------------------------------------------
-- Touched but not picked
----------------------------------------------------------------

function Diag.find_contested_groups(record)
    local groups, current = {}, nil

    for i, t in ipairs(record._tokens or {}) do
        local is_ws   = (t.lex == "ws")
        local entries = record._token_usage[i]

        local touched = Usage.is_semantically_touched(entries)
        local picked  = Usage.is_picked(entries)

        if touched and not picked and not is_ws then
            if not current then
                current = { text = t.raw, from = t.index, to = t.index, rules = {} }
            else
                current.text = current.text .. t.raw
                current.to   = t.index
            end

            for _, e in ipairs(entries or {}) do
                current.rules[e.rule] = true
            end
        else
            if current then
                local r = {}
                for k in pairs(current.rules) do r[#r + 1] = k end
                table.sort(r)
                current.rules = r
                groups[#groups + 1] = current
                current = nil
            end
        end
    end

    if current then
        local r = {}
        for k in pairs(current.rules) do r[#r + 1] = k end
        table.sort(r)
        current.rules = r
        groups[#groups + 1] = current
    end

    return groups
end

return Diag
