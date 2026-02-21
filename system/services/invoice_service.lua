local RuntimeDomain  = require("core.domain.runtime.controller")
local InvoiceDomain  = require("core.domain.invoice.controller")

local Storage        = require("system.infrastructure.storage.controller")
local FileGateway    = require("system.infrastructure.file_gateway")

local InvoiceService = {}

function InvoiceService.handle(req)

    local state = req.state
    if not state then
        return { ok = false, error = "missing state" }
    end

    local order_path =
        state.resources
        and state.resources.order_path

    if not order_path then
        return { ok = false, error = "missing resource: order_path" }
    end

    ------------------------------------------------------------
    -- Load runtime bundle
    ------------------------------------------------------------

    local runtime = RuntimeDomain.load(order_path)
    local batch   = runtime:batches()[1]

    if not batch then
        return { ok = false, error = "no batch available" }
    end

    if not batch.transaction_id then
        return { ok = false, error = "invoice requires transaction_id" }
    end

    ------------------------------------------------------------
    -- Build invoice model
    ------------------------------------------------------------

    local model = InvoiceDomain.run(batch, { print = false })

    ------------------------------------------------------------
    -- Render
    ------------------------------------------------------------

    local rendered = InvoiceDomain.render_text(model)
    local content  = table.concat(rendered.lines, "\n")

    ------------------------------------------------------------
    -- Optional print
    ------------------------------------------------------------

    if not (req.opts and req.opts.print == false) then
        for _, line in ipairs(rendered.lines) do
            print(line)
        end
    end

    ------------------------------------------------------------
    -- Export via Storage Schema
    ------------------------------------------------------------

    if req.opts and req.opts.export == true then

        local doc_path  = Storage.export_doc("invoices", model.id)
        local meta_path = Storage.export_meta("invoices", model.id)

        --------------------------------------------------------
        -- Write invoice text
        --------------------------------------------------------

        local meta, err =
            FileGateway.write(doc_path, "raw", content)

        if not meta then
            return { ok = false, error = err }
        end

        --------------------------------------------------------
        -- Write invoice meta
        --------------------------------------------------------

        local export_meta = {
            document_id  = model.id,
            type         = "invoice",
            txn_id       = batch.transaction_id,
            client_id    = batch.order and batch.order.client,
            source_path  = order_path,
            totals       = model.totals,
            generated_at = os.date("%Y-%m-%d %H:%M:%S"),
        }

        local meta2, err2 =
            FileGateway.write(meta_path, "json", export_meta)

        if not meta2 then
            return { ok = false, error = err2 }
        end

        --------------------------------------------------------
        -- Optional: attach to ledger txn folder
        --------------------------------------------------------

        if batch.transaction_id then
            local txn_dir =
                Storage.ledger_txn_dir(
                    state.context and state.context.active_ledger or "main",
                    batch.transaction_id
                )

            local ledger_copy =
                txn_dir .. "/attachments/" .. model.id .. ".txt"

            FileGateway.write(ledger_copy, "raw", content)
        end
    end

    ------------------------------------------------------------
    -- Update state
    ------------------------------------------------------------

    state.results = state.results or {}
    state.results.invoice = model

    return { ok = true, model = model }
end

return InvoiceService
