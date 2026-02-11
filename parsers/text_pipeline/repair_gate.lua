-- parsers/text_pipeline/repair_gate.lua
--
-- Structural repair eligibility logic
-- EXACT CONTRACT:
--   • Repair ONLY if required dims are missing
--   • Stable spans are HARD barriers

-- #TODO: There exists no validation layer to stop totally bad text data from getting here
local Stable = require("parsers.text_pipeline.stable_spans")

local Gate = {}

local function missing_required_dims(resolved)
    return not (resolved and resolved.h and resolved.w and resolved.l)
end

function Gate.needs_repair(record)
    if not missing_required_dims(record._resolved) then
        return false
    end

    local stable = record._stable_spans or {}

    -- 1. Numeric tokens not covered by picked claims
    do
        local covered = {}
        for _, p in ipairs(record._picked or {}) do
            if p.span then
                covered[#covered + 1] = p.span
            end
        end

        for _, t in ipairs(record._tokens or {}) do
            if t.traits and t.traits.numeric then
                if not Stable.token_is_stable(t, stable) then
                    local used = false
                    for _, s in ipairs(covered) do
                        if t.index >= s.from and t.index <= s.to then
                            used = true
                            break
                        end
                    end
                    if not used then
                        return true
                    end
                end
            end
        end
    end

    -- 2. Adjacent numeric chunks without stable barrier
    local chunks = record._chunks or {}
    for i = 1, #chunks - 1 do
        local a, b = chunks[i], chunks[i + 1]

        if (a.has_num or a.has_unit or a.has_infix)
            and (b.has_num or b.has_unit or b.has_infix)
            and not Stable.chunk_overlaps(a, stable)
            and not Stable.chunk_overlaps(b, stable)
        then
            return true
        end
    end

    return false
end

return Gate
