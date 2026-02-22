-- system/services/invoice_service.lua
--
-- InvoiceService
-- ==============
--
-- Orchestration layer for invoice generation.
--
-- Responsibilities:
--   • Resolve required runtime via RuntimeHub
--   • Extract canonical batch
--   • Invoke Invoice domain controller
--   • Render invoice text
--   • Optionally export artifacts
--   • Store model in state.results (ephemeral)
--
-- It explicitly does NOT:
--   • Access state.resources directly
--   • Load RuntimeDomain directly
--   • Perform invoice business rules
--   • Mutate ledger registry
--
-- Flow:
--   Surface → InvoiceService.handle()
--   → hub:require("user")
--   → InvoiceDomain.run(...)
--   → InvoiceDomain.render_text(...)
--   → Optional export
--   → state:set_result("invoice", model)

local InvoiceDomain = require("core.domain.invoice.controller")

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")

---@class InvoiceRequest
---@field state State
---@field hub RuntimeHub
---@field opts? { export?: boolean, print?: boolean }

---@class InvoiceResponse
---@field ok boolean
---@field model? any
---@field error? string

---@class InvoiceService
local InvoiceService = {}

----------------------------------------------------------------
-- handle()
----------------------------------------------------------------
-- Generates and optionally exports an invoice.
--
-- Failure model:
--   • Never throws
--   • Returns { ok=false, error=... }
--
---@param req InvoiceRequest
---@return InvoiceResponse
function InvoiceService.handle(req)

    if not req or type(req) ~= "table" then
        return { ok = false, error = "invalid request" }
    end

    local state = req.state
    local hub   = req.hub
    local opts  = req.opts or {}

    if not state then
        return { ok = false, error = "missing state" }
    end

    if not hub then
        return { ok = false, error = "missing runtime hub" }
    end

    ------------------------------------------------------------
    -- Resolve USER runtime
    --
    -- Invoice operates on a canonical order batch.
    ------------------------------------------------------------

    local runtime, err = hub:require("user")
    if not runtime then
        return { ok = false, error = err or "user runtime not available" }
    end

    local batches = runtime:batches()
    if not batches or #batches == 0 then
        return { ok = false, error = "no batch available" }
    end

    -- Invoice currently assumes first batch is canonical
    local batch = batches[1]

    if not batch.transaction_id then
        return { ok = false, error = "invoice requires transaction_id" }
    end

    ------------------------------------------------------------
    -- Build invoice model (Domain layer)
    ------------------------------------------------------------

    -- Domain controller handles validation + totals
    local model = InvoiceDomain.run(batch, { print = false })

    ------------------------------------------------------------
    -- Render invoice text
    ------------------------------------------------------------

    local rendered = InvoiceDomain.render_text(model)
    local content  = table.concat(rendered.lines, "\n")

    ------------------------------------------------------------
    -- Optional print to stdout
    ------------------------------------------------------------

    if opts.print ~= false then
        for _, line in ipairs(rendered.lines) do
            print(line)
        end
    end

    ------------------------------------------------------------
    -- Optional export
    ------------------------------------------------------------

    if opts.export == true then

        -- Canonical export identifiers
        local doc_path  = Storage.export_doc("invoices", model.id)
        local meta_path = Storage.export_meta("invoices", model.id)

        --------------------------------------------------------
        -- Write invoice text file
        --------------------------------------------------------

        local meta, write_err =
            FileGateway.write(doc_path, "raw", content)

        if not meta then
            return { ok = false, error = write_err }
        end

        --------------------------------------------------------
        -- Write invoice metadata
        --------------------------------------------------------

        local export_meta = {
            document_id  = model.id,
            type         = "invoice",
            txn_id       = batch.transaction_id,
            client_id    = batch.order and batch.order.client,
            totals       = model.totals,
            generated_at = os.date("%Y-%m-%d %H:%M:%S"),
        }

        local meta2, write_err2 =
            FileGateway.write(meta_path, "json", export_meta)

        if not meta2 then
            return { ok = false, error = write_err2 }
        end

        --------------------------------------------------------
        -- Optional: attach invoice to ledger txn folder
        --
        -- This does NOT update ledger registry.
        -- It only writes a file into the txn directory.
        --------------------------------------------------------

        local ledger_id =
            state:get_context("active_ledger") or "default"

        local txn_dir =
            Storage.ledger_txn_dir(
                ledger_id,
                batch.transaction_id
            )

        local ledger_copy =
            txn_dir .. "/attachments/" .. model.id .. ".txt"

        FileGateway.write(ledger_copy, "raw", content)
    end

    ------------------------------------------------------------
    -- Store result in ephemeral session state
    ------------------------------------------------------------

    state:set_result("invoice", model)

    return { ok = true, model = model }
end

return InvoiceService
