-- system/state.lua
--
-- Minimal persistent state container.
-- No domain logic. No IO.

local State = {}
State.__index = State

local function ensure_table(x)
  if type(x) == "table" then return x end
  return {}
end

function State.new(initial)
  local self = setmetatable({}, State)

  initial = ensure_table(initial)

  self.context   = ensure_table(initial.context)
  self.loadables = ensure_table(initial.loadables)
  self.results   = ensure_table(initial.results)

  return self
end

------------------------------------------------------------
-- Loadable management
------------------------------------------------------------

function State:set_loadable(key, value)
  if type(key) ~= "string" or key == "" then
    return false, "invalid loadable key"
  end
  self.loadables[key] = value
  return true
end

function State:get_loadable(key)
  return self.loadables[key]
end

function State:clear_loadable(key)
  self.loadables[key] = nil
end

------------------------------------------------------------
-- Context
------------------------------------------------------------

function State:set_context(key, value)
  if type(key) ~= "string" or key == "" then
    return false, "invalid context key"
  end
  self.context[key] = value
  return true
end

function State:get_context(key)
  return self.context[key]
end

------------------------------------------------------------
-- Snapshot (persistable only)
------------------------------------------------------------

function State:to_persistable()
  return {
    version   = 1,
    context   = self.context,
    loadables = self.loadables,
  }
end

return State
