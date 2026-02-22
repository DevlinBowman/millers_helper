-- system/services/compare_service.lua
--
-- Compare service.
-- Resolves runtimes exclusively via RuntimeHub.
-- No direct domain loading.
-- No direct state.resource access.

local CompareDomain = require("core.domain.compare.controller")

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")

local CompareService = {}

function CompareService.handle(req)

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
    ------------------------------------------------------------

    local user_runtime, err = hub:require("user")
    if not user_runtime then
        return { ok = false, error = err or "user runtime not available" }
    end

    local user_batches = user_runtime:batches()
    if not user_batches or #user_batches == 0 then
        return { ok = false, error = "no user batch available" }
    end

    local order_bundle = user_batches[1]

    ------------------------------------------------------------
    -- Resolve VENDOR runtime
    ------------------------------------------------------------

    local vendor_runtime, err2 = hub:require("vendors")
    if not vendor_runtime then
        return { ok = false, error = err2 or "vendor runtime not available" }
    end

    local vendor_batches = vendor_runtime:batches()
    if not vendor_batches or #vendor_batches == 0 then
        return { ok = false, error = "no vendor batches available" }
    end

    local sources = {}

    for i, batch in ipairs(vendor_batches) do
        sources[#sources + 1] = {
            name   = "vendor-" .. tostring(i),
            boards = batch.boards or {},
        }
    end

    if #sources == 0 then
        return { ok = false, error = "no valid vendor sources loaded" }
    end

    ------------------------------------------------------------
    -- Compare
    ------------------------------------------------------------

    local result =
        CompareDomain.compare(order_bundle, sources, {})

    ------------------------------------------------------------
    -- Store result (ephemeral)
    ------------------------------------------------------------

    state:set_result("compare", result)

    ------------------------------------------------------------
    -- Optional export
    ------------------------------------------------------------

    if opts.export == true then

        local compare_id = "COMPARE-" .. os.time()

        local doc_path  = Storage.export_doc("compare", compare_id)
        local meta_path = Storage.export_meta("compare", compare_id)

        FileGateway.write(doc_path, "json", result)

        FileGateway.write(meta_path, "json", {
            compare_id   = compare_id,
            generated_at = os.date("%Y-%m-%d %H:%M:%S"),
        })
    end

    return { ok = true, result = result }
end

return CompareService
