-- tools/diagnostic/controller.lua
--
-- Controller-style helpers for scoping and export control.
--
-- Keeps the decision of "what escapes" at the boundary layer.

local Diagnostic = require("tools.diagnostic.diagnostic")

local Controller = {}

local function is_table(x) return type(x) == "table" end

--- Run a function inside a diagnostic scope and always close scope.
--- Returns:
---   ok, result, diag_scope
--- On error:
---   ok=false, err, diag_scope
---
--- @param label string
--- @param fn function
--- @param opts table|nil passed to Diagnostic.scope_enter
function Controller.with_scope(label, fn, opts)
    assert(type(label) == "string", "Diagnostic.with_scope(): label string required")
    assert(type(fn) == "function", "Diagnostic.with_scope(): fn function required")
    if opts ~= nil then
        assert(is_table(opts), "Diagnostic.with_scope(): opts must be table|nil")
    end

    Diagnostic.scope_enter(label, opts)

    local ok, result_or_err = pcall(fn)

    local scope = Diagnostic.scope_leave()

    if ok then
        return true, result_or_err, scope
    end

    return false, result_or_err, scope
end

--- Export helper:
--- Given canonical data and a diagnostic scope, return a sealed envelope
--- optionally attaching diagnostics only if requested.
---
--- @param data any (canonical output)
--- @param diag_scope table|nil (from scope_leave)
--- @param opts table|nil { include_diagnostics=boolean }
function Controller.export(data, diag_scope, opts)
    opts = opts or {}
    if opts ~= nil then
        assert(is_table(opts), "Diagnostic.export(): opts must be table|nil")
    end

    local include = opts.include_diagnostics == true

    if include then
        return {
            data        = data,
            diagnostics = diag_scope or {},
        }
    end

    return {
        data = data,
    }
end

return Controller
