-- system/app/state/runtime.lua

local RuntimeLoader = require("core.domain.runtime").controller

---@class AppDataRuntime
---@field private __runtime table
---@field private __resources AppDataResources
local RuntimeNS = {}
RuntimeNS.__index = RuntimeNS

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param runtime_state table
---@param resources AppDataResources
---@return AppDataRuntime
function RuntimeNS.new(runtime_state, resources)

    assert(type(runtime_state) == "table", "[data.runtime] runtime_state required")
    assert(type(resources) == "table", "[data.runtime] resources required")
    assert(type(resources.get) == "function", "[data.runtime] resources:get required")

    runtime_state.system = runtime_state.system or {}
    runtime_state.user   = runtime_state.user   or {}

    return setmetatable({
        __runtime   = runtime_state,
        __resources = resources,
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

    assert(scope == "system" or scope == "user",
        "[data.runtime] invalid scope")

    assert(type(role) == "string" and role ~= "",
        "[data.runtime] role required")

    local runtime_state = self.__runtime

    runtime_state[scope] = runtime_state[scope] or {}
    runtime_state[scope][role] = runtime_state[scope][role] or {}

    return runtime_state[scope][role]
end

---@private
---@param scope "system"|"user"
---@param role string
---@param id string
---@return integer|nil
function RuntimeNS:_resolve_index(scope, role, id)

    local list =
        self.__resources:get(scope, role)

    if type(list) ~= "table" then
        return nil
    end

    for index = 1, #list do
        local entry = list[index]

        if type(entry) == "table"
        and entry.id == id then
            return index
        end
    end

    return nil
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
        assert(selector >= 1,
            "[data.runtime] index must be >= 1")
        return selector
    end

    if type(selector) == "string" then

        local index =
            self:_resolve_index(scope, role, selector)

        assert(index ~= nil,
            "[data.runtime] unknown id for "
            .. scope .. "." .. role .. ": " .. selector)

        return index
    end

    error("[data.runtime] selector must be integer, string id, or nil", 2)
end

---@private
---@param entry table
---@return any
function RuntimeNS:_load_entry(entry)

    assert(type(entry) == "table", "[data.runtime] entry required")
    assert(type(entry.load_spec) == "table", "[data.runtime] load_spec missing")

    local spec = entry.load_spec

    if spec.type == "single" then

        assert(type(spec.path) == "string",
            "[data.runtime] single spec.path required")

        return RuntimeLoader.load_strict(spec.path)
    end

    if spec.type == "associate" then

        assert(type(spec.order_path) == "string",
            "[data.runtime] associate order_path required")

        assert(type(spec.boards_path) == "string",
            "[data.runtime] associate boards_path required")

        local order_runtime =
            RuntimeLoader.load_strict(spec.order_path)

        local board_runtime =
            RuntimeLoader.load_strict(spec.boards_path)

        return RuntimeLoader.associate(order_runtime, board_runtime)
    end

    error("[data.runtime] unknown load_spec type: " .. tostring(spec.type), 2)
end

------------------------------------------------------------
-- Core Runtime Storage API
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param index integer
---@param envelope any
function RuntimeNS:set(scope, role, index, envelope)

    assert(type(index) == "number" and index >= 1,
        "[data.runtime] index must be >= 1")

    local list =
        self:_ensure_list(scope, role)

    list[index] = envelope
end

---@param scope "system"|"user"
---@param role string
---@param index integer
---@return any|nil
function RuntimeNS:get(scope, role, index)

    assert(type(index) == "number" and index >= 1,
        "[data.runtime] index must be >= 1")

    local bucket = self.__runtime[scope]
    local list   = bucket and bucket[role]

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

    assert(type(index) == "number" and index >= 1,
        "[data.runtime] index must be >= 1")

    local bucket = self.__runtime[scope]
    local list   = bucket and bucket[role]

    if list then
        list[index] = nil
    end
end

---@param scope "system"|"user"
---@param role string
function RuntimeNS:clear_role(scope, role)

    assert(scope == "system" or scope == "user",
        "[data.runtime] invalid scope")

    assert(type(role) == "string" and role ~= "",
        "[data.runtime] role required")

    self.__runtime[scope][role] = {}
end

---@param scope "system"|"user"
---@param role string
---@return table
function RuntimeNS:all(scope, role)
    return self:_ensure_list(scope, role)
end

------------------------------------------------------------
-- Public Require API
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param selector integer|string|nil
---@return any
function RuntimeNS:require(scope, role, selector)

    local index =
        self:_coerce_index(scope, role, selector)

    local envelope =
        self:get(scope, role, index)

    if not envelope then

        local list =
            self.__resources:get(scope, role)

        list = assert(list,
            "[data.runtime] missing resource list: "
            .. scope .. "." .. role)

        local entry =
            list[index]

        entry = assert(entry,
            "[data.runtime] missing resource entry: "
            .. scope .. "." .. role
            .. "[" .. tostring(index) .. "]")

        envelope =
            self:_load_entry(entry)

        self:set(scope, role, index, envelope)
    end

    return envelope
end

------------------------------------------------------------
-- Bulk Helpers
------------------------------------------------------------

---@param scope "system"|"user"
---@param role string
---@param selectors table
---@return table
function RuntimeNS:require_many(scope, role, selectors)

    assert(type(selectors) == "table",
        "[data.runtime] selectors table required")

    local out = {}

    for i = 1, #selectors do
        out[i] = self:require(scope, role, selectors[i])
    end

    return out
end

---@param scope "system"|"user"
---@param role string
---@param count integer
---@return table
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

---@param scope "system"|"user"
---@param role string|nil
---@return table
function RuntimeNS:pull(scope, role)

    assert(scope == "system" or scope == "user",
        "[data.runtime] invalid scope")

    local bucket =
        (scope == "system")
        and self.__resources:system()
        or self.__resources:user()

    assert(type(bucket) == "table",
        "[data.runtime] invalid resource scope")

    local loaded = {}

    local function pull_role(role_name, list)

        if type(list) ~= "table" then
            return
        end

        for index = 1, #list do

            if not self:exists(scope, role_name, index) then
                self:require(scope, role_name, index)
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

---@param scope "system"|"user"
---@param role string
---@return table
function RuntimeNS:batches(scope, role)

    local list =
        self:all(scope, role)

    local out = {}

    for index = 1, #list do

        local envelope =
            list[index]

        if envelope then

            local batches =
                envelope.__batches

            if type(batches) == "table" then

                for batch_index = 1, #batches do
                    out[#out + 1] = batches[batch_index]
                end

            else
                out[#out + 1] = envelope
            end
        end
    end

    return out
end

return RuntimeNS
