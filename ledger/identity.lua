-- ledger/identity.lua
--
-- Computes identity for sparse records.
-- Safe to evolve over time.

local Identity = {}

local function norm(v)
    return tostring(v or ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
end

function Identity.compute(record)
    return table.concat({
        norm(record.date),
        norm(record.order),
        norm(record.base_h),
        norm(record.base_w),
        norm(record.l),
        norm(record.ct),
        norm(record.amount),
    }, "|")
end

return Identity
