-- system/app/state/runtime.lua

---@class AppDataRuntime
---@field private __state table
---@field private __loader fun(scope:"system"|"user", role:string, index:integer): any
---@field private __resolve_index fun(scope:"system"|"user", role:string, id:string): integer|nil
local RuntimeNS = {}
RuntimeNS.__index = RuntimeNS

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---Create the runtime namespace responsible for managing loaded runtime envelopes.
---Initializes the runtime storage structure and binds loader and id-resolution helpers.
---
---The runtime namespace acts as the lazy-loading cache for domain runtime objects.
---Nothing is loaded until requested through `require`.
---
---@param state table Shared application state table
---@param loader fun(scope:"system"|"user", role:string, index:integer): any
---    Function responsible for constructing a runtime envelope when it is missing.
---@param resolve_index fun(scope:"system"|"user", role:string, id:string): integer|nil
---    Function used to translate resource ids into runtime index positions.
---@return AppDataRuntime
function RuntimeNS.new(state, loader, resolve_index)
    assert(type(state) == "table", "[data.runtime] state required")
    assert(type(loader) == "function", "[data.runtime] loader required")
    assert(type(resolve_index) == "function", "[data.runtime] resolve_index required")

    state.runtime = state.runtime or {}
    state.runtime.system = state.runtime.system or {}
    state.runtime.user = state.runtime.user or {}

    return setmetatable({
        __state         = state,
        __loader        = loader,
        __resolve_index = resolve_index,
    }, RuntimeNS)
end

------------------------------------------------------------
-- Internal Helpers
------------------------------------------------------------

---Ensure a runtime storage list exists for the given scope and role.
---
---Runtime objects are stored as:
---state.runtime[scope][role][index] = envelope
---
---This helper guarantees the container exists before read/write operations.
---Used internally by storage operations.
---
---@private
---@param scope "system"|"user"
---@param role string
---@return table list Runtime envelope list for the role
function RuntimeNS:_ensure_list(scope, role)
    assert(scope == "system" or scope == "user", "[data.runtime] invalid scope")
    assert(type(role) == "string" and role ~= "", "[data.runtime] role required")

    local rt = self.__state.runtime
    rt[scope] = rt[scope] or {}
    rt[scope][role] = rt[scope][role] or {}
    return rt[scope][role]
end

---Normalize a selector into a concrete runtime index.
---
---Selectors allow callers to reference runtime objects using:
---• numeric index
---• resource id string
---• nil (defaults to index 1)
---
---String ids are resolved through the runtime id registry via `__resolve_index`.
---
---@private
---@param scope "system"|"user"
---@param role string
---@param selector integer|string|nil
---@return integer index
function RuntimeNS:_coerce_index(scope, role, selector)

    if selector == nil then
        return 1
    end

    if type(selector) == "number" then
        assert(selector >= 1, "[data.runtime] index must be >= 1")
        return selector
    end

    if type(selector) == "string" then
        local idx = self.__resolve_index(scope, role, selector)
        assert(idx ~= nil,
            "[data.runtime] unknown id for "
            .. scope .. "." .. role .. ": " .. selector)
        return idx
    end

    error("[data.runtime] selector must be integer, string id, or nil", 2)
end

------------------------------------------------------------
-- Core Runtime Storage API
------------------------------------------------------------

---Store a runtime envelope at a specific index.
---
---This writes the envelope into the runtime cache without performing any loading.
---Primarily used internally after a runtime object is created or loaded.
---
---Example storage layout:
---state.runtime.user.job[1] = runtime_envelope
---
---@param scope "system"|"user"
---@param role string
---@param index integer
---@param envelope any Runtime envelope object
function RuntimeNS:set(scope, role, index, envelope)
    assert(type(index) == "number" and index >= 1,
        "[data.runtime] index must be >= 1")

    local list = self:_ensure_list(scope, role)
    list[index] = envelope
end

---Retrieve a runtime envelope from cache without loading it.
---
---Returns nil if the runtime object has not yet been loaded.
---Callers typically use `require` instead if lazy loading is desired.
---
---@param scope "system"|"user"
---@param role string
---@param index integer
---@return any|nil envelope
function RuntimeNS:get(scope, role, index)
    assert(type(index) == "number" and index >= 1,
        "[data.runtime] index must be >= 1")

    local bucket = self.__state.runtime[scope]
    local list = bucket and bucket[role]
    return list and list[index] or nil
end

---@param scope "system"|"user"
---@param role string
---@param index integer
---@return boolean
function RuntimeNS:exists(scope, role, index)
    return self:get(scope, role, index) ~= nil
end

---Remove a runtime envelope from the cache.
---
---This clears the cached runtime object but does not remove the
---underlying resource or descriptor from the system.
---
---The runtime object can be reloaded later through `require`.
---
---@param scope "system"|"user"
---@param role string
---@param index integer
function RuntimeNS:clear(scope, role, index)
    assert(type(index) == "number" and index >= 1,
        "[data.runtime] index must be >= 1")

    local bucket = self.__state.runtime[scope]
    local list = bucket and bucket[role]
    if list then
        list[index] = nil
    end
end

---Return the full runtime envelope list for a role.
---
---This exposes the raw runtime storage array for inspection
---or iteration by higher-level services.
---
---The list may contain nil entries if specific indices were cleared.
---
---@param scope "system"|"user"
---@param role string
---@return table
function RuntimeNS:all(scope, role)
    return self:_ensure_list(scope, role)
end

------------------------------------------------------------
-- Context Resolution Layer
------------------------------------------------------------

---Apply slot-selection context to a runtime envelope.
---
---If the runtime envelope contains multiple batches (`__batches`)
---this function resolves which batch should be visible based on
---the current slot selection stored in application state.
---
---The returned object is a proxy that exposes the selected batch
---through `batch()` while forwarding other fields to the envelope.
---
---@private
---@param scope "system"|"user"
---@param role string
---@param envelope any
---@return any context_wrapped_envelope
function RuntimeNS:_resolve_context(scope, role, envelope)

    local slots = self.__state.slots
    local selected =
        slots
        and slots.selection
        and slots.selection[scope]
        and slots.selection[scope][role]

    if type(selected) ~= "number" then
        print(string.format(
            "[RuntimeNS] %s.%s → default batch 1",
            scope, role
        ))
        return envelope
    end

    if type(envelope.__batches) ~= "table" then
        return envelope
    end

    local total = #envelope.__batches
    local effective = envelope.__batches[selected] and selected or 1

    print(string.format(
        "[RuntimeNS]ctx %s.%s → slot batch %d (effective %d of %d)",
        scope, role, selected, effective, total
    ))

    return setmetatable({}, {
        __index = function(_, key)
            if key == "batch" then
                return function()
                    return envelope.__batches[effective]
                end
            end
            return envelope[key]
        end
    })
end
------------------------------------------------------------
-- Public Require API
------------------------------------------------------------

---Require a runtime envelope, loading it if necessary.
---
---This is the primary entry point for runtime access.
---If the envelope is not present in cache it will be loaded
---using the configured loader function.
---
---The returned object is context-aware and respects the
---currently selected slot batch.
---
---@param scope "system"|"user"
---@param role string
---@param selector integer|string|nil Runtime index or id selector
---@return any envelope
function RuntimeNS:require(scope, role, selector)

    local index = self:_coerce_index(scope, role, selector)

    local envelope = self:get(scope, role, index)
    if not envelope then
        envelope = self.__loader(scope, role, index)
        self:set(scope, role, index, envelope)
    end

    -- Context-aware return
    return self:_resolve_context(scope, role, envelope)
end

------------------------------------------------------------
-- Bulk Helpers
------------------------------------------------------------

---Load multiple runtime envelopes using a list of selectors.
---
---Each selector may be:
---• index
---• id string
---
---Results are returned in the same order as the selector list.
---
---@param scope "system"|"user"
---@param role string
---@param selectors table
---@return table envelopes
function RuntimeNS:require_many(scope, role, selectors)
    assert(type(selectors) == "table",
        "[data.runtime] selectors table required")

    local out = {}
    for i = 1, #selectors do
        out[i] = self:require(scope, role, selectors[i])
    end
    return out
end

---Require runtime envelopes from index 1 to the specified count.
---
---This is used when the caller knows how many runtime resources exist
---and wants to ensure they are all loaded into runtime memory.
---
---@param scope "system"|"user"
---@param role string
---@param count integer
---@return table envelopes
function RuntimeNS:require_all_with_count(scope, role, count)
    assert(type(count) == "number" and count >= 0,
        "[data.runtime] count must be >= 0")

    local out = {}
    for i = 1, count do
        out[i] = self:require(scope, role, i)
    end
    return out
end

---Load runtime envelopes for resources already registered in state.
---
---This scans the resource registry (`state.resources`) and ensures
---runtime objects exist for each descriptor.
---
---Behavior:
---• If `role` is provided, only that role is loaded
---• If `role` is nil, the entire scope is loaded
---
---Runtime objects already present in cache are not reloaded.
---
---@param scope "system"|"user"
---@param role string|nil
---@return table loaded_counts Map of role -> number of resources
function RuntimeNS:pull(scope, role)

    assert(scope == "system" or scope == "user",
        "[data.runtime] invalid scope")

    local resources = self.__state.resources
    assert(type(resources) == "table",
        "[data.runtime] resources state missing")

    local bucket = resources[scope]
    assert(type(bucket) == "table",
        "[data.runtime] invalid resource scope")

    local loaded = {}

    ------------------------------------------------------------
    -- Pull specific role
    ------------------------------------------------------------

    local function pull_role(role_name, list)

        if type(list) ~= "table" then
            return
        end

        for i = 1, #list do
            if not self:exists(scope, role_name, i) then
                local envelope = self.__loader(scope, role_name, i)
                self:set(scope, role_name, i, envelope)
            end
        end

        loaded[role_name] = #list
    end

    ------------------------------------------------------------
    -- Single role
    ------------------------------------------------------------

    if role then
        pull_role(role, bucket[role])
        return loaded
    end

    ------------------------------------------------------------
    -- Entire scope
    ------------------------------------------------------------

    for role_name, list in pairs(bucket) do
        pull_role(role_name, list)
    end

    return loaded
end

---Return all runtime batches for a role.
---
---Each runtime envelope may contain one or more batches.
---This helper unwraps those envelopes and returns a flat list
---of all batches currently loaded in runtime memory.
---
---Behavior:
---• if envelope.__batches exists → append all batches
---• otherwise → treat envelope as a single batch
---
---@param scope "system"|"user"
---@param role string
---@return table batches
function RuntimeNS:batches(scope, role)

    local list = self:all(scope, role)

    local out = {}

    for i = 1, #list do
        local envelope = list[i]

        if envelope then
            local batches = envelope.__batches

            if type(batches) == "table" then
                for j = 1, #batches do
                    out[#out + 1] = batches[j]
                end
            else
                out[#out + 1] = envelope
            end
        end
    end

    return out
end

return RuntimeNS
