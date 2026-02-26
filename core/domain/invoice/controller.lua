-- core/domain/invoice/controller.lua
--
-- Invoice Domain Controller
--
-- Provides:
--   run_raw(batch)    -> InvoiceDTO
--   run(batch)        -> InvoiceResult
--   run_strict(batch) -> InvoiceResult (throws)
--
-- Responsibility:
--   • Validate input
--   • Call pipeline
--   • Wrap DTO in Result
--   • Enforce strict policy

local Registry = require("core.domain.invoice.registry")
local Result   = require("core.domain.invoice.result")

local Controller = {}

----------------------------------------------------------------
-- RAW ENTRY (Structure Layer)
----------------------------------------------------------------

---@param batch table
---@param opts table|nil { id?:string }
---@return table|nil, string|nil
function Controller.run_raw(batch, opts)
    Registry.schema.validate(batch)

    opts = opts or {}

    return Registry.pipeline.run({
        id             = opts.id,
        boards         = batch.boards,
        order          = batch.order,
        transaction_id = batch.transaction_id,
    })
end

----------------------------------------------------------------
-- FAÇADE ENTRY (Meaning Layer)
----------------------------------------------------------------

---@param batch table
---@param opts table|nil
---@return InvoiceResult|nil, string|nil
function Controller.run(batch, opts)
    local dto, err = Controller.run_raw(batch, opts)
    if not dto then
        return nil, err
    end

    return Result.new(dto)
end

----------------------------------------------------------------
-- STRICT ENTRY (Policy Layer)
----------------------------------------------------------------

---@param batch table
---@param opts table|nil
---@return InvoiceResult
function Controller.run_strict(batch, opts)
    local result = Controller.run(batch, opts)
    return result:require_priced()
end

return Controller
