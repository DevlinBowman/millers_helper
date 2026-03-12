-- system/execution/planner.lua

local TargetResolver = require("system.execution.target_resolver")

local Planner = {}

local function has_selector_value(v)
    return v ~= nil and v ~= false
end

local function resolve_job_resource_selector(opts)
    if has_selector_value(opts.job_resource_selector) then return opts.job_resource_selector end
    if has_selector_value(opts.selector) then return opts.selector end
    return nil
end

local function resolve_job_batch_selector(opts, slots)
    if has_selector_value(opts.job_batch_selector) then return opts.job_batch_selector end
    local slot = slots:get_selection("user", "job")
    if has_selector_value(slot) then return slot end
    return nil
end

local function resolve_vendor_selector(opts, slots)
    if has_selector_value(opts.vendor_selector) then return opts.vendor_selector end
    local slot = slots:get_selection("system", "vendor")
    if has_selector_value(slot) then return slot end
    return nil
end

local function resolve_strategy(service_name, data, opts)
    if type(opts.strategy) == "string" and opts.strategy ~= "" then return opts.strategy end
    if service_name == "compare" or service_name == "pricing" then
        local pricing_intent = data:intent():get("pricing") or {}
        if type(pricing_intent) == "table" and type(pricing_intent.basis) == "string" and pricing_intent.basis ~= "" then
            return pricing_intent.basis
        end
    end
    return nil
end

---@param app Surface
---@param service_name string
---@param opts table
---@return table
function Planner.build(app, service_name, opts)
    local data = app:data()
    local runtime = data:runtime()
    local slots = data:slots()
    local intent = data:intent()

    local job_resource_selector = resolve_job_resource_selector(opts)
    local job_batch_selector = resolve_job_batch_selector(opts, slots)
    local vendor_selector = resolve_vendor_selector(opts, slots)

    local job_env, job_batch, job_resolved =
        TargetResolver.resolve_job(runtime, job_resource_selector, job_batch_selector)

    local vendor_env, vendor_batches, vendor_resolved =
        TargetResolver.resolve_vendors(runtime, vendor_selector)

    local strategy =
        resolve_strategy(service_name, data, opts)

    return {
        kind = "execution",
        service = service_name,
        opts = opts,
        status = "env_ready",
        strategy = strategy,
        job_resource_selector = job_resource_selector,
        job_batch_selector = job_batch_selector,
        job_resolved_selector = job_resolved,
        vendor_resolved_selector = vendor_resolved,
        vendor_selector = vendor_selector,

        env = {
            job = job_env,
            vendor = vendor_env,
            vendors = vendor_batches,
            pricing_basis = strategy,
            opts = opts,
            intent = intent,
            slots = slots
        },

        target = job_batch,
        compat = nil,
        enrichment = nil,
        patches = {},
        result = nil
    }
end

return Planner
