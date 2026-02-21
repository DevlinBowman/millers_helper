local RuntimeDomain = require("core.domain.runtime.controller")
local QuoteDomain   = require("core.domain.quote.controller")

local Storage       = require("system.infrastructure.storage.controller")
local FileGateway   = require("system.infrastructure.file_gateway")

local QuoteService  = {}

function QuoteService.handle(req)

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
    local batch = runtime:batches()[1]

    if not batch then
        return { ok = false, error = "no batch available" }
    end

    ------------------------------------------------------------
    -- Build quote model
    ------------------------------------------------------------

    local model = QuoteDomain.run(batch.boards, { print = false })

    ------------------------------------------------------------
    -- Render
    ------------------------------------------------------------

    local rendered = QuoteDomain.render_text(model)
    local content = table.concat(rendered.lines, "\n")

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

        local doc_path  = Storage.export_doc("quotes", model.id)
        local meta_path = Storage.export_meta("quotes", model.id)

        local meta, err = FileGateway.write(doc_path, "raw", content)
        if not meta then
            return { ok = false, error = err }
        end

        local export_meta = {
            document_id = model.id,
            type        = "quote",
            source_path = order_path,
            totals      = model.totals,
            generated_at = os.date("%Y-%m-%d %H:%M:%S"),
        }

        local meta2, err2 =
            FileGateway.write(meta_path, "json", export_meta)

        if not meta2 then
            return { ok = false, error = err2 }
        end
    end

    ------------------------------------------------------------
    -- Update state
    ------------------------------------------------------------

    state.results = state.results or {}
    state.results.quote = model

    return { ok = true, model = model }
end

return QuoteService
