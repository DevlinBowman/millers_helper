-- system/app/state/runtime.lua

---@class AppDataRuntime
---@field private __runtime table
---@field private __state table
---@field private __loader fun(scope:"system"|"user", role:string, index:integer): any
---@field private __resolve_index fun(scope:"system"|"user", role:string, id:string): integer|nil
local RuntimeNS = {}
RuntimeNS.__index = RuntimeNS

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param state table Shared application state table
---@param loader fun(scope:"system"|"user", role:string, index:integer): any
---@param resolve_index fun(scope:"system"|"user", role:string, id:string): integer|nil
---@return AppDataRuntime
function RuntimeNS.new(state, loader, resolve_index, read_resources)

    assert(type(state) == "table", "[data.runtime] state required")
    assert(type(loader) == "function", "[data.runtime] loader required")
    assert(type(resolve_index) == "function", "[data.runtime] resolve_index required")
    assert(type(read_resources) == "function", "[data.runtime] read_resources required")

    state.runtime = state.runtime or {}
    state.runtime.system = state.runtime.system or {}
    state.runtime.user = state.runtime.user or {}

    return setmetatable({
        __runtime        = state.runtime,
        __loader         = loader,
        __resolve_index  = resolve_index,
        __read_resources = read_resources,
    }, RuntimeNS)
end

------------------------------------------------------------
-- Internal Helpers
------------------------------------------------------------

---@private
---@param scope "system"|"user"
---@param role string
---@return table
function RuntimeNS:_ensure_list(scope, role)
    assert(scope == "system" or scope == "user", "[data.runtime] invalid scope")
    assert(type(role) == "string" and role ~= "", "[data.runtime] role required")

    local rt = self.__runtime

    rt[scope] = rt[scope] or {}
    rt[scope][role] = rt[scope][role] or {}

    return rt[scope][role]
end

---@private
---@param scope "system"|"user"
---@param role string
---@param selector integer|string|nil
---@return integer
function RuntimeNS:_coerce_index(scope, role, selector)
    if selector == nil then
        return 1
    end

    if type(selector) == "number" then
        assert(selector >= 1, "[data.runtime] index must be >= 1")
        return selector
    end

    if type(selector) == "string" then
        local idx =
            self.__resolve_index(scope, role, selector)

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

function RuntimeNS:set(scope, role, index, envelope)
    assert(type(index) == "number" and index >= 1,
        "[data.runtime] index must be >= 1")

    local list = self:_ensure_list(scope, role)

    list[index] = envelope
end

function RuntimeNS:get(scope, role, index)
    assert(type(index) == "number" and index >= 1,
        "[data.runtime] index must be >= 1")

    local bucket = self.__runtime[scope]
    local list = bucket and bucket[role]

    return list and list[index] or nil
end

function RuntimeNS:exists(scope, role, index)
    return self:get(scope, role, index) ~= nil
end

function RuntimeNS:clear(scope, role, index)
    assert(type(index) == "number" and index >= 1,
        "[data.runtime] index must be >= 1")

    local bucket = self.__runtime[scope]
    local list = bucket and bucket[role]

    if list then
        list[index] = nil
    end
end

function RuntimeNS:all(scope, role)
    return self:_ensure_list(scope, role)
end

------------------------------------------------------------
-- Public Require API
------------------------------------------------------------

function RuntimeNS:require(scope, role, selector)
    local index = self:_coerce_index(scope, role, selector)

    local envelope =
        self:get(scope, role, index)

    if not envelope then
        envelope =
            self.__loader(scope, role, index)

        self:set(scope, role, index, envelope)
    end

    return envelope
end

------------------------------------------------------------
-- Bulk Helpers
------------------------------------------------------------

function RuntimeNS:require_many(scope, role, selectors)
    assert(type(selectors) == "table",
        "[data.runtime] selectors table required")

    local out = {}

    for i = 1, #selectors do
        out[i] = self:require(scope, role, selectors[i])
    end

    return out
end

function RuntimeNS:require_all_with_count(scope, role, count)
    assert(type(count) == "number" and count >= 0,
        "[data.runtime] count must be >= 0")

    local out = {}

    for i = 1, count do
        out[i] = self:require(scope, role, i)
    end

    return out
end

------------------------------------------------------------
-- Resource → Runtime Loader
------------------------------------------------------------
---


function RuntimeNS:pull(scope, role)
    assert(scope == "system" or scope == "user",
        "[data.runtime] invalid scope")

    local resources = self.__read_resources()

    assert(type(resources) == "table",
        "[data.runtime] resources unavailable")

    local bucket =
        resources[scope]

    assert(type(bucket) == "table",
        "[data.runtime] invalid resource scope")

    local loaded = {}

    local function pull_role(role_name, list)
        if type(list) ~= "table" then
            return
        end

        for i = 1, #list do
            if not self:exists(scope, role_name, i) then
                local envelope =
                    self.__loader(scope, role_name, i)

                self:set(scope, role_name, i, envelope)
            end
        end

        loaded[role_name] = #list
    end

    if role then
        pull_role(role, bucket[role])
        return loaded
    end

    for role_name, list in pairs(bucket) do
        pull_role(role_name, list)
    end

    return loaded
end

------------------------------------------------------------
-- Batch Extraction
------------------------------------------------------------

function RuntimeNS:batches(scope, role)
    local list =
        self:all(scope, role)

    local out = {}

    for i = 1, #list do
        local envelope = list[i]

        if envelope then
            local batches =
                envelope.__batches

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
