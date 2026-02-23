-- system/services/quote_service.lua
--
-- Quote service.
-- Resolves runtime exclusively via RuntimeHub (namespaced keys).
-- No direct state.resources coupling.

local QuoteDomain = require("core.domain.quote.controller")

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")

local QuoteService = {}

----------------------------------------------------------------
-- Internal: resolve canonical user order runtime
----------------------------------------------------------------
---@param hub RuntimeHub
---@return any|nil runtime
---@return string|nil err
local function require_user_order_runtime(hub)
    return hub:require("user.order")
end

function QuoteService.handle(req)

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
    -- Resolve USER order runtime
    ------------------------------------------------------------

    local runtime, err = require_user_order_runtime(hub)
    if not runtime then
        return { ok = false, error = err or "user.order runtime not available" }
    end

    local batches = runtime:batches()
    if not batches or #batches == 0 then
        return { ok = false, error = "no batches available" }
    end

    local batch = batches[1]

    if not batch.boards or #batch.boards == 0 then
        return { ok = false, error = "quote requires boards" }
    end

    ------------------------------------------------------------
    -- Build quote model
    ------------------------------------------------------------

    local model = QuoteDomain.run(batch.boards, { print = false })

    ------------------------------------------------------------
    -- Render
    ------------------------------------------------------------

    local rendered = QuoteDomain.render_text(model)
    local content  = table.concat(rendered.lines, "\n")

    ------------------------------------------------------------
    -- Optional print
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

        local doc_path  = Storage.export_doc("quotes", model.id)
        local meta_path = Storage.export_meta("quotes", model.id)

        local meta, write_err =
            FileGateway.write(doc_path, "raw", content)

        if not meta then
            return { ok = false, error = write_err }
        end

        local export_meta = {
            document_id  = model.id,
            type         = "quote",
            totals       = model.totals,
            generated_at = os.date("%Y-%m-%d %H:%M:%S"),
        }

        local meta2, write_err2 =
            FileGateway.write(meta_path, "json", export_meta)

        if not meta2 then
            return { ok = false, error = write_err2 }
        end
    end

    ------------------------------------------------------------
    -- Store result (ephemeral)
    ------------------------------------------------------------

    state:set_result("quote", model)

    return { ok = true, model = model }
end

return QuoteService
