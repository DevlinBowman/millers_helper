#!/usr/bin/env bash
set -euo pipefail

mkdir -p system/capability/materializers

cat > system/capability/registry.lua <<'EOF'
-- system/capability/registry.lua

local Registry = {}

Registry.materializers = {
    board_prices = "system.capability.materializers.pricing",
}

---@param capability string
---@return string|nil
function Registry.get_materializer(capability)
    assert(type(capability) == "string" and capability ~= "",
        "[capability.registry] capability required")
    return Registry.materializers[capability]
end

---@param capability string
---@param module_path string
function Registry.register(capability, module_path)
    assert(type(capability) == "string" and capability ~= "",
        "[capability.registry] capability required")
    assert(type(module_path) == "string" and module_path ~= "",
        "[capability.registry] module_path required")

    Registry.materializers[capability] = module_path
end

return Registry
EOF

cat > system/capability/patch_validator.lua <<'EOF'
-- system/capability/patch_validator.lua

local PatchValidator = {}

local function assert_patch_shape(patch)
    assert(type(patch) == "table", "[capability.patch_validator] patch must be table")

    assert(type(patch.capability) == "string" and patch.capability ~= "",
        "[capability.patch_validator] patch.capability required")

    assert(type(patch.changes) == "table",
        "[capability.patch_validator] patch.changes required")

    local board_changes = patch.changes.boards
    if board_changes ~= nil then
        assert(type(board_changes) == "table",
            "[capability.patch_validator] patch.changes.boards must be table")

        for board_index, fields in pairs(board_changes) do
            assert(type(board_index) == "number" and board_index >= 1,
                "[capability.patch_validator] board index must be integer >= 1")

            assert(type(fields) == "table",
                "[capability.patch_validator] board field map must be table")

            for field_name, _ in pairs(fields) do
                assert(type(field_name) == "string" and field_name ~= "",
                    "[capability.patch_validator] board field name must be non-empty string")
            end
        end
    end

    for field_name, _ in pairs(patch.changes) do
        assert(type(field_name) == "string" and field_name ~= "",
            "[capability.patch_validator] change field name must be non-empty string")
    end
end

---@param patch table
---@return boolean
function PatchValidator.validate_patch(patch)
    assert_patch_shape(patch)
    return true
end

---@param patches table
---@return boolean
function PatchValidator.validate_list(patches)
    assert(type(patches) == "table",
        "[capability.patch_validator] patch list must be table")

    for index = 1, #patches do
        PatchValidator.validate_patch(patches[index])
    end

    return true
end

return PatchValidator
EOF

cat > system/capability/materializer.lua <<'EOF'
-- system/capability/materializer.lua

local Registry = require("system.capability.registry")

local Materializer = {}

---@param capability string
---@param target table
---@param service_result table
---@return table|nil
function Materializer.materialize(capability, target, service_result)
    assert(type(capability) == "string" and capability ~= "",
        "[capability.materializer] capability required")
    assert(type(target) == "table",
        "[capability.materializer] target required")
    assert(type(service_result) == "table",
        "[capability.materializer] service_result required")

    local module_path = Registry.get_materializer(capability)
    if not module_path then
        return nil
    end

    local materializer = require(module_path)

    assert(type(materializer) == "table",
        "[capability.materializer] materializer module must return table")

    assert(type(materializer.materialize) == "function",
        "[capability.materializer] materializer.materialize() required")

    return materializer.materialize(target, service_result, capability)
end

return Materializer
EOF

cat > system/capability/materializers/pricing.lua <<'EOF'
-- system/capability/materializers/pricing.lua

local PricingMaterializer = {}

local function as_number(value)
    if type(value) == "number" then
        return value
    end
    return nil
end

local function resolve_quantity(board)
    return as_number(board.qty)
        or as_number(board.quantity)
        or as_number(board.count)
        or 1
end

local function resolve_length_feet(board)
    return as_number(board.l)
        or as_number(board.length)
        or as_number(board.length_ft)
        or as_number(board.feet)
end

local function resolve_board_feet(board)
    local direct =
        as_number(board.bf)
        or as_number(board.board_feet)
        or as_number(board.boardfeet)

    if direct and direct > 0 then
        return direct
    end

    local height_in =
        as_number(board.h)
        or as_number(board.height)
        or as_number(board.base_h)

    local width_in =
        as_number(board.w)
        or as_number(board.width)
        or as_number(board.base_w)

    local length_ft = resolve_length_feet(board)

    if height_in and width_in and length_ft then
        return (height_in * width_in * length_ft) / 12
    end

    return nil
end

---@param target table
---@param service_result table
---@param capability string
---@return table|nil
function PricingMaterializer.materialize(target, service_result, capability)
    assert(type(target) == "table", "[pricing.materializer] target required")
    assert(type(service_result) == "table", "[pricing.materializer] service_result required")

    local domain_result = service_result.result
    if not domain_result then
        return nil
    end

    assert(type(domain_result.model) == "function",
        "[pricing.materializer] pricing result missing model()")

    local model = domain_result:model()
    assert(type(model) == "table" and type(model.raw) == "function",
        "[pricing.materializer] pricing result model missing raw()")

    local raw_model = model:raw()
    local per_board = raw_model.per_board or {}

    local patch = {
        capability = capability or "board_prices",
        changes = {
            boards = {}
        }
    }

    for board_index, row in ipairs(per_board) do
        local target_board = target.boards and target.boards[board_index]
        local recommended_price_per_bf =
            row and row.recommended_price_per_bf

        if target_board and type(recommended_price_per_bf) == "number" then
            local unit_board_feet = resolve_board_feet(target_board)
            local length_feet = resolve_length_feet(target_board)
            local quantity = resolve_quantity(target_board)

            local each_price =
                unit_board_feet and (recommended_price_per_bf * unit_board_feet) or nil

            local lineal_foot_price =
                (each_price and length_feet and length_feet > 0)
                and (each_price / length_feet)
                or nil

            local batch_price =
                (each_price and quantity)
                and (each_price * quantity)
                or nil

            patch.changes.boards[board_index] = {
                bf_price    = recommended_price_per_bf,
                ea_price    = each_price,
                lf_price    = lineal_foot_price,
                batch_price = batch_price,
            }
        end
    end

    if next(patch.changes.boards) == nil then
        return nil
    end

    return patch
end

return PricingMaterializer
EOF

cat > system/enrichment/controller.lua <<'EOF'
-- system/enrichment/controller.lua
--
-- System orchestration layer responsible for resolving
-- missing capabilities required by services.

local Mutator          = require("system.runtime.mutator")
local BuiltinProviders = require("system.enrichment.providers")
local Materializer     = require("system.capability.materializer")
local PatchValidator   = require("system.capability.patch_validator")

local Enrichment = {}

------------------------------------------------------------
-- Provider Registry
------------------------------------------------------------

local providers = {}

---@param capability string
---@param fn function
function Enrichment.register(capability, fn)
    assert(type(capability) == "string" and capability ~= "",
        "[enrichment] capability required")
    assert(type(fn) == "function",
        "[enrichment] provider function required")

    providers[capability] = fn
end

local function register_builtin_providers()
    for capability, fn in pairs(BuiltinProviders or {}) do
        Enrichment.register(capability, fn)
    end
end

register_builtin_providers()

------------------------------------------------------------
-- Resolve Missing Capabilities
------------------------------------------------------------

---@param app Surface
---@param selector integer|string|nil
---@param request table
---@return table
function Enrichment.resolve(app, selector, request)

    assert(type(app) == "table", "[enrichment] app required")
    assert(type(request) == "table", "[enrichment] request required")

    local missing = request.missing or {}
    local env = request.env
    local target = request.target

    assert(type(env) == "table", "[enrichment] request.env required")
    assert(type(target) == "table", "[enrichment] request.target required")

    local patches = {}
    local unresolved = {}
    local results = {}

    for _, capability in ipairs(missing) do
        local provider = providers[capability]

        if not provider then
            unresolved[#unresolved + 1] = {
                capability = capability,
                reason = "no_provider"
            }
        else
            local provider_result = provider(app, selector, env)

            if not provider_result or provider_result.ok ~= true then
                unresolved[#unresolved + 1] = {
                    capability = capability,
                    reason = "provider_failed"
                }
            else
                results[capability] = provider_result

                local patch = Materializer.materialize(
                    capability,
                    target,
                    provider_result
                )

                if patch then
                    PatchValidator.validate_patch(patch)
                    patches[#patches + 1] = patch
                end
            end
        end
    end

    if #patches > 0 then
        Mutator.apply(target, patches)
    end

    return {
        ok = (#unresolved == 0),
        unresolved = unresolved,
        patches = patches,
        results = results,
    }
end

return Enrichment
EOF

cat > system/enrichment/providers.lua <<'EOF'
-- system/enrichment/providers.lua

local Providers = {}

------------------------------------------------------------
-- board_prices provider
------------------------------------------------------------

Providers.board_prices = function(app, selector, env)

    local Interpreter = require("system.app.intent.interpreter")

    local runtime = app:data():runtime()
    local intent  = app:data():intent():all()

    local ctx = Interpreter.build("pricing", runtime, intent) or {}
    local opts = {}

    for key, value in pairs(env.opts or {}) do
        opts[key] = value
    end

    for key, value in pairs(ctx) do
        opts[key] = value
    end

    return app:services():pricing():resolve(selector, opts)
end

------------------------------------------------------------
-- vendor_prices provider
------------------------------------------------------------

Providers.vendor_prices = function(_, _, env)
    local vendors = env.vendors or {}

    for _, batch in ipairs(vendors) do
        for _, board in ipairs(batch.boards or {}) do
            if type(board.bf_price) == "number" and board.bf_price > 0 then
                return {
                    ok = true,
                    capability = "vendor_prices"
                }
            end
        end
    end

    return nil
end

return Providers
EOF

cat > system/app/services/pricing.lua <<'EOF'
-- system/app/services/pricing.lua

local PricingDomain  = require("core.domain.pricing").controller
local Contracts      = require("core.domain.pricing.contracts")
local Compatibility  = require("system.compatibility.controller")
local Mutator        = require("system.runtime.mutator")

---@class AppPricingService
local Pricing = {}
Pricing.__index = Pricing

function Pricing.new(app)
    return setmetatable({
        __app = app
    }, Pricing)
end

------------------------------------------------------------
-- Internal Helpers
------------------------------------------------------------

---@param selector integer|string|nil
---@return table
function Pricing:_load_user_batch(selector)
    local runtime = self.__app:data():runtime()
    local envelope = runtime:require("user", "job", selector)

    assert(type(envelope.batch) == "function",
        "[pricing.service] runtime job missing batch()")

    return envelope:batch()
end

---@param selector integer|string|nil
---@param vendor_selector any
---@return table|nil
function Pricing:_resolve_vendor_env(selector, vendor_selector)
    if type(vendor_selector) == "table" and vendor_selector.kind == "vendor" then
        return vendor_selector
    end

    local runtime = self.__app:data():runtime()
    local resources = self.__app:data():resources()

    local vendor_list = resources:get("system", "vendor") or {}
    if #vendor_list == 0 then
        return nil
    end

    local index

    if vendor_selector == nil then
        index = 1
    elseif type(vendor_selector) == "number" then
        index = vendor_selector
    elseif type(vendor_selector) == "string" then
        for i, entry in ipairs(vendor_list) do
            if entry.id == vendor_selector then
                index = i
                break
            end
        end
    end

    if not index then
        return nil
    end

    local rt = runtime:require("system", "vendor", index)
    if type(rt.batch) ~= "function" then
        return nil
    end

    local batch = rt:batch()

    return {
        kind  = "vendor",
        items = batch.boards,
        meta  = {
            name = batch.id or vendor_selector or vendor_list[index].id
        }
    }
end

------------------------------------------------------------
-- Resolve Only (no mutation)
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Pricing:resolve(selector, opts)
    opts = opts or {}

    local batch = self:_load_user_batch(selector)

    local basis = opts.pricing_basis or opts.basis
    if not basis then
        if batch.order
            and batch.order.use == "sale"
            and type(batch.order.value) == "number"
            and batch.order.value > 0
        then
            basis = "reverse_order_value"
        else
            basis = "vendor_anchor"
        end
    end

    local domain_opts = {
        allocations        = opts.allocations,
        compare            = opts.compare,
        percentage         = opts.percentage,
        profile            = opts.profile,
        target_total_value = opts.target_total_value,
    }

    domain_opts.vendor = self:_resolve_vendor_env(selector, opts.vendor)

    local env = Contracts.build_env(batch, basis, domain_opts)
    local compat = Compatibility.check("pricing", basis, env)

    if not compat.ok then
        return {
            ok = false,
            error = "compatibility_mismatch",
            missing = compat.missing,
            strategy = basis,
        }
    end

    local result = PricingDomain.run(batch, basis, domain_opts)

    return {
        ok = true,
        strategy = basis,
        result = result,
        provided = { "board_prices" }
    }
end

------------------------------------------------------------
-- Run + Apply
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Pricing:run(selector, opts)
    local resolved = self:resolve(selector, opts)

    if not resolved.ok then
        return resolved
    end

    return resolved
end

return Pricing
EOF

cat > system/app/services/compare.lua <<'EOF'
-- system/app/services/compare.lua

local CompareDomain = require("core.domain.compare").controller
local Contracts     = require("core.domain.compare.contracts")

local Compatibility = require("system.compatibility.controller")
local Enrichment    = require("system.enrichment.controller")

---@class AppCompareService
---@field private __app Surface
local Compare = {}
Compare.__index = Compare

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param app Surface
---@return AppCompareService
function Compare.new(app)
    return setmetatable({
        __app = app
    }, Compare)
end

------------------------------------------------------------
-- Internal: Load user batch
------------------------------------------------------------

---@param selector integer|string|nil
---@return table
function Compare:_load_user_batch(selector)
    local runtime = self.__app:data():runtime()
    local user_runtime = runtime:require("user", "job", selector)

    assert(type(user_runtime) == "table",
        "[compare.service] runtime user job envelope missing")

    assert(type(user_runtime.batch) == "function",
        "[compare.service] runtime job missing batch()")

    local batch = user_runtime:batch()

    assert(type(batch) == "table",
        "[compare.service] runtime job batch missing")

    assert(type(batch.boards) == "table",
        "[compare.service] runtime job batch missing boards")

    return batch
end

------------------------------------------------------------
-- Internal: Load vendor batches
------------------------------------------------------------

---@return table
function Compare:_load_vendor_batches()
    local data = self.__app:data()
    local runtime = data:runtime()

    local vendor_descriptors = data:resources():get("system", "vendor") or {}
    local vendor_batches = {}

    for index = 1, #vendor_descriptors do
        local vendor_runtime = runtime:require("system", "vendor", index)

        assert(type(vendor_runtime) == "table",
            "[compare.service] runtime system vendor envelope missing at index " .. tostring(index))

        assert(type(vendor_runtime.batch) == "function",
            "[compare.service] runtime vendor missing batch() at index " .. tostring(index))

        local batch = vendor_runtime:batch()

        assert(type(batch) == "table",
            "[compare.service] runtime vendor batch missing at index " .. tostring(index))

        vendor_batches[#vendor_batches + 1] = batch
    end

    return vendor_batches
end

------------------------------------------------------------
-- Internal: Build compare environment
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return table
function Compare:_build_env(selector, opts)
    local user_batch = self:_load_user_batch(selector)
    local vendor_batches = self:_load_vendor_batches()

    local env = Contracts.build_env(user_batch, vendor_batches, opts or {})

    assert(type(env) == "table",
        "[compare.service] contracts.build_env() must return table")

    return env
end

------------------------------------------------------------
-- Internal: Compatibility check
------------------------------------------------------------

---@param env table
---@return table
function Compare:_check_compatibility(env)
    return Compatibility.check("compare", "default", env)
end

------------------------------------------------------------
-- Internal: Resolve missing capabilities
------------------------------------------------------------

---@param selector integer|string|nil
---@param env table
---@param opts table
---@param compat table
---@return table
function Compare:_resolve_missing(selector, env, opts, compat)
    return Enrichment.resolve(self.__app, selector, {
        service  = "compare",
        strategy = "default",
        missing  = compat.missing or {},
        env      = env,
        opts     = opts or {},
        target   = env.job,
    })
end

------------------------------------------------------------
-- Internal: Domain execution
------------------------------------------------------------

---@param env table
---@param opts table|nil
---@return CompareResult
function Compare:_run_domain(env, opts)
    return CompareDomain.run_strict(
        env.job,
        env.vendors,
        opts
    )
end

------------------------------------------------------------
-- Public: Run Compare
------------------------------------------------------------

---@param selector integer|string|nil
---@param opts table|nil
---@return CompareResult|table
function Compare:run(selector, opts)
    opts = opts or {}

    --------------------------------------------------------
    -- 1. Build current compare context from system runtime
    --------------------------------------------------------

    local env = self:_build_env(selector, opts)

    --------------------------------------------------------
    -- 2. Validate compatibility once at service boundary
    --------------------------------------------------------

    local compatibility_result = self:_check_compatibility(env)

    --------------------------------------------------------
    -- 3. If missing capabilities exist, let system enrichment
    --    resolve them and mutate runtime through system-owned
    --    mutation authority
    --------------------------------------------------------

    if not compatibility_result.ok then
        local enrichment_result =
            self:_resolve_missing(selector, env, opts, compatibility_result)

        if not enrichment_result.ok then
            return {
                ok         = false,
                error      = "compatibility_mismatch",
                service    = "compare",
                strategy   = "default",
                missing    = compatibility_result.missing or {},
                enrichment = enrichment_result,
            }
        end

        ----------------------------------------------------
        -- 4. Rebuild env from runtime after enrichment
        ----------------------------------------------------

        env = self:_build_env(selector, opts)
        compatibility_result = self:_check_compatibility(env)

        if not compatibility_result.ok then
            return {
                ok       = false,
                error    = "compatibility_mismatch_after_enrichment",
                service  = "compare",
                strategy = "default",
                missing  = compatibility_result.missing or {},
            }
        end
    end

    --------------------------------------------------------
    -- 5. Run pure domain compare once context is compatible
    --------------------------------------------------------

    return self:_run_domain(env, opts)
end

return Compare
EOF

echo "phase 1 capability pipeline update complete"
