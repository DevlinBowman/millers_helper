-- system/runtime_hub.lua
--
-- Master loader control panel.
-- Top-level access to runtime domain.
--
-- Responsibilities:
--   • Store load specifications (persisted)
--   • Cache RuntimeView objects (non-persisted)
--   • Provide safe require() semantics
--
-- No CLI.
-- No printing.
-- No services.

local RuntimeController = require("core.domain.runtime.controller")

local RuntimeHub = {}
RuntimeHub.__index = RuntimeHub

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

function RuntimeHub.new(initial_specs)
    local self = setmetatable({}, RuntimeHub)

    self._specs  = initial_specs or {}  -- persistable
    self._cache  = {}                  -- runtime objects (not persisted)

    return self
end

------------------------------------------------------------
-- Spec Management (Persisted)
------------------------------------------------------------

function RuntimeHub:set(name, input, opts)
    if type(name) ~= "string" or name == "" then
        return false, "invalid name"
    end

    self._specs[name] = {
        input = input,
        opts  = opts or {}
    }

    -- clear stale cache
    self._cache[name] = nil

    return true
end

function RuntimeHub:clear(name)
    self._specs[name] = nil
    self._cache[name] = nil
end

function RuntimeHub:spec(name)
    return self._specs[name]
end

function RuntimeHub:specs()
    return self._specs
end

------------------------------------------------------------
-- Loading
------------------------------------------------------------

function RuntimeHub:load(name)
    local spec = self._specs[name]

    if not spec then
        return nil, "missing spec: " .. tostring(name)
    end

    local runtime = RuntimeController.load(
        spec.input,
        spec.opts
    )

    self._cache[name] = runtime

    return runtime
end

------------------------------------------------------------
-- Access (Lazy + Safe)
------------------------------------------------------------

function RuntimeHub:get(name)
    if self._cache[name] then
        return self._cache[name]
    end

    return self:load(name)
end

function RuntimeHub:require(name)
    local runtime, err = self:get(name)
    if not runtime then
        return nil, err
    end
    return runtime
end

------------------------------------------------------------
-- Introspection
------------------------------------------------------------

function RuntimeHub:is_loaded(name)
    return self._cache[name] ~= nil
end

function RuntimeHub:is_configured(name)
    return self._specs[name] ~= nil
end

return RuntimeHub
