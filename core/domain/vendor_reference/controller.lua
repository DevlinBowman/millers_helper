local Trace         = require("tools.trace.trace")
local Registry      = require("core.domain.vendor_reference.registry")

local Update        = require("core.domain.vendor_reference.pipelines.update")
local Result        = require("core.domain.vendor_reference.result")

local Controller    = {}

Controller.CONTRACT = {
    update = {
        in_ = {
            vendor_batch    = true, -- RuntimeBatch
            existing_vendor = false,
            opts            = false,
        },
        out = {
            result = true,
        },
    },
}

local function assert_table(x, name)
    if type(x) ~= "table" then
        error(name .. " must be table, got " .. type(x))
    end
end

----------------------------------------------------------------
-- UPDATE ENTRY (Batch-Based)
----------------------------------------------------------------
-- vendor_batch : RuntimeBatch (canonical)
-- existing_vendor : vendor package | nil
-- opts : overwrite policy

function Controller.update(vendor_name, vendor_batch, existing_vendor, opts)
    Trace.contract_enter("core.domain.vendor_reference.controller.update")

    assert(type(vendor_name) == "string" and vendor_name ~= "",
        "[vendor_reference] vendor_name required")

    assert(type(vendor_batch) == "table",
        "[vendor_reference] vendor_batch required")

    assert(type(vendor_batch.boards) == "table",
        "[vendor_reference] vendor_batch.boards required")

    if existing_vendor ~= nil then
        assert(type(existing_vendor) == "table",
            "[vendor_reference] existing_vendor must be table")
    end

    local normalized =
        Registry.vendor.normalize_name(vendor_name)

    if not normalized then
        Trace.contract_leave()
        error("[vendor_reference] invalid vendor_name")
    end

    local dto = Update.run({
        vendor_name     = normalized,
        incoming_rows   = vendor_batch.boards,
        existing_vendor = existing_vendor,
        opts            = opts or {},
    })

    Trace.contract_leave()
    return Result.new(dto)
end

return Controller
