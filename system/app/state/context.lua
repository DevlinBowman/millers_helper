---@class AppDataContext
---@field private __ctx table
local Context = {}
Context.__index = Context

------------------------------------------------------------
-- Constructor
------------------------------------------------------------

---@param ctx_state table
---@return AppDataContext
function Context.new(ctx_state)

    assert(type(ctx_state) == "table", "[data.context] ctx_state required")

    ctx_state.active = ctx_state.active or nil
    ctx_state.store  = ctx_state.store  or {}

    return setmetatable({
        __ctx = ctx_state
    }, Context)
end

------------------------------------------------------------
-- create context
------------------------------------------------------------

function Context:create(id, data)

    assert(type(id) == "string" and id ~= "",
        "[data.context] id required")

    self.__ctx.store[id] = data or {}
    self.__ctx.active = id

    return self.__ctx.store[id]
end

------------------------------------------------------------
-- get context
------------------------------------------------------------

function Context:get(id)

    id = id or self.__ctx.active
    if not id then
        return nil
    end

    return self.__ctx.store[id]
end

------------------------------------------------------------
-- clear context
------------------------------------------------------------

function Context:clear(id)

    id = id or self.__ctx.active
    if not id then
        return
    end

    self.__ctx.store[id] = nil

    if self.__ctx.active == id then
        self.__ctx.active = nil
    end
end

------------------------------------------------------------
-- list contexts
------------------------------------------------------------

function Context:list()
    return self.__ctx.store
end

return Context
