---@class AppDataContext
---@field private __state table
local Context = {}
Context.__index = Context

function Context.new(state)

    state.ctx = state.ctx or { active = nil, store = {} }

    return setmetatable({
        __state = state
    }, Context)
end

------------------------------------------------------------
-- create context
------------------------------------------------------------

function Context:create(id, data)

    assert(type(id) == "string" and id ~= "",
        "[data.context] id required")

    self.__state.ctx.store[id] = data or {}
    self.__state.ctx.active = id

    return self.__state.ctx.store[id]
end

------------------------------------------------------------
-- get context
------------------------------------------------------------

function Context:get(id)

    id = id or self.__state.ctx.active
    if not id then return nil end

    return self.__state.ctx.store[id]
end

------------------------------------------------------------
-- clear context
------------------------------------------------------------

function Context:clear(id)

    id = id or self.__state.ctx.active
    if not id then return end

    self.__state.ctx.store[id] = nil

    if self.__state.ctx.active == id then
        self.__state.ctx.active = nil
    end
end

------------------------------------------------------------
-- list contexts
------------------------------------------------------------

function Context:list()
    return self.__state.ctx.store
end

return Context
