-- system/app/data/runtime.lua

---@class AppDataRuntime
---@field private __state table
---@field private __loader fun(scope:"system"|"user", role:string, index:integer): any
---@field private __resolve_index fun(scope:"system"|"user", role:string, id:string): integer|nil
local RuntimeNS = {}
RuntimeNS.__index = RuntimeNS

---@param state table
---@param loader fun(scope:"system"|"user", role:string, index:integer): any
---@param resolve_index fun(scope:"system"|"user", role:string, id:string): integer|nil
---@return AppDataRuntime
function RuntimeNS.new(state, loader, resolve_index)
    assert(type(state) == "table", "[data.runtime] state required")
    assert(type(loader) == "function", "[data.runtime] loader required")
    assert(type(resolve_index) == "function", "[data.runtime] resolve_index required")

    state.runtime = state.runtime or {}
    state.runtime.system = state.runtime.system or {}
    state.runtime.user = state.runtime.user or {}

    ---@type AppDataRuntime
    return setmetatable({
        __state         = state,
        __loader        = loader,
        __resolve_index = resolve_index,
    }, RuntimeNS)
end

---@private
---@param scope "system"|"user"
---@param role string
---@return table
function RuntimeNS:_ensure_list(scope, role)
    assert(scope == "system" or scope == "user", "[data.runtime] invalid scope")
    assert(type(role) == "string" and role ~= "", "[data.runtime] role required")

    local rt = self.__state.runtime
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
        local idx = self.__resolve_index(scope, role, selector)
        assert(idx ~= nil, "[data.runtime] unknown id for " .. scope .. "." .. role .. ": " .. selector)
        return idx
    end

    error("[data.runtime] selector must be integer index, string id, or nil", 2)
end

---@param scope "system"|"user"
---@param role string
---@param index integer
---@param envelope any
function RuntimeNS:set(scope, role, index, envelope)
    assert(type(index) == "number" and index >= 1, "[data.runtime] index must be >= 1")
    local list = self:_ensure_list(scope, role)
    list[index] = envelope
end

---@param scope "system"|"user"
---@param role string
---@param index integer
---@return any|nil
function RuntimeNS:get(scope, role, index)
    assert(type(index) == "number" and index >= 1, "[data.runtime] index must be >= 1")
    local rt = self.__state.runtime
    local bucket = rt and rt[scope]
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

---@param scope "system"|"user"
---@param role string
---@param index integer
function RuntimeNS:clear(scope, role, index)
    assert(type(index) == "number" and index >= 1, "[data.runtime] index must be >= 1")
    local rt = self.__state.runtime
    local bucket = rt and rt[scope]
    local list = bucket and bucket[role]
    if list then
        list[index] = nil
    end
end

---Return runtime list for a given scope+role (may be sparse).
---@param scope "system"|"user"
---@param role string
---@return table
function RuntimeNS:all(scope, role)
    return self:_ensure_list(scope, role)
end

---Lazy-load runtime envelope aligned to resources[scope][role][index].
---selector can be:
---  • nil       => index 1
---  • integer   => index
---  • string    => entry.id (resolved to index)
---@param scope "system"|"user"
---@param role string
---@param selector integer|string|nil
---@return any
function RuntimeNS:require(scope, role, selector)
    local index = self:_coerce_index(scope, role, selector)

    local cached = self:get(scope, role, index)
    if cached ~= nil then
        return cached
    end

    local loaded = self.__loader(scope, role, index)
    self:set(scope, role, index, loaded)
    return loaded
end

---Load multiple runtime envelopes in one call (order preserved).
---selectors is an array of (integer|string|nil).
---@param scope "system"|"user"
---@param role string
---@param selectors table
---@return table
function RuntimeNS:require_many(scope, role, selectors)
    assert(type(selectors) == "table", "[data.runtime] selectors table required")

    local out = {}
    for i = 1, #selectors do
        out[i] = self:require(scope, role, selectors[i])
    end
    return out
end


---Load first `count` entries for (scope, role).
---@param scope "system"|"user"
---@param role string
---@param count integer
---@return table
function RuntimeNS:require_all_with_count(scope, role, count)
    assert(type(count) == "number" and count >= 0, "[data.runtime] count must be number >= 0")

    local out = {}
    for i = 1, count do
        out[i] = self:require(scope, role, i)
    end
    return out
end

return RuntimeNS
