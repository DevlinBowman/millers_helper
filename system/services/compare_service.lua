-- system/services/compare_service.lua
--
-- CompareService
-- ==============
--
-- Orchestration layer for price/source comparison.
--
-- Responsibilities:
--   • Resolve required runtimes via RuntimeHub (namespaced keys)
--   • Prefer user override vendors when present, else system vendor cache
--   • Extract canonical bundles
--   • Invoke Compare domain controller
--   • Store result in state.results (ephemeral)

local CompareDomain = require("core.domain.compare.controller")

local Storage     = require("system.infrastructure.storage.controller")
local FileGateway = require("system.infrastructure.file_gateway")

---@class CompareRequest
---@field state State
---@field hub RuntimeHub
---@field opts? { export?: boolean }

---@class CompareResponse
---@field ok boolean
---@field result? any
---@field error? string

local CompareService = {}

----------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------

---@param hub RuntimeHub
---@param name string
---@return boolean
local function spec_has_inputs(hub, name)
    if not hub or not hub.spec then
        return false
    end

    local spec = hub:spec(name)
    if not spec or type(spec) ~= "table" then
        return false
    end

    local inputs = spec.inputs
    if type(inputs) ~= "table" then
        return false
    end

    return (#inputs > 0) or (inputs.orders ~= nil) or (inputs.boards ~= nil)
end

---@param hub RuntimeHub
---@return string chosen_key
local function choose_vendor_key(hub)
    -- Prefer explicit user override if configured with inputs.
    if spec_has_inputs(hub, "user.vendors") then
        return "user.vendors"
    end

    -- Otherwise use system vendor cache.
    return "system.vendors"
end

---@param hub RuntimeHub
---@return any|nil runtime
---@return string|nil err
local function require_user_order_runtime(hub)
    return hub:require("user.order")
end

---@param hub RuntimeHub
---@return any|nil runtime
---@return string|nil err
local function require_vendor_runtime(hub)
    local key = choose_vendor_key(hub)
    local runtime, err = hub:require(key)
    if not runtime then
        return nil, (err or ("vendor runtime not available: " .. key))
    end
    return runtime
end

----------------------------------------------------------------
-- handle()
----------------------------------------------------------------
---@param req CompareRequest
---@return CompareResponse
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
    -- Resolve USER order runtime
    ------------------------------------------------------------

    local user_runtime, err = require_user_order_runtime(hub)
    if not user_runtime then
        return { ok = false, error = err or "user.order runtime not available" }
    end

    local user_batches = user_runtime:batches()
    if not user_batches or #user_batches == 0 then
        return { ok = false, error = "no user batch available" }
    end

    local order_bundle = user_batches[1]

    ------------------------------------------------------------
    -- Resolve VENDOR runtime (user override OR system cache)
    ------------------------------------------------------------

    local vendor_runtime, err2 = require_vendor_runtime(hub)
    if not vendor_runtime then
        return { ok = false, error = err2 or "vendor runtime not available" }
    end

    local vendor_batches = vendor_runtime:batches()
    if not vendor_batches or #vendor_batches == 0 then
        return { ok = false, error = "no vendor batches available" }
    end

    ------------------------------------------------------------
    -- Normalize vendor batches into compare sources
    ------------------------------------------------------------

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
    -- Domain comparison
    ------------------------------------------------------------

    local result = CompareDomain.compare(order_bundle, sources, {})

    ------------------------------------------------------------
    -- Store result (ephemeral session output)
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
