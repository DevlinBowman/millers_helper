-- system/backend.lua
--
-- Minimal request execution bridge.
-- No CLI. No printing.

local Backend = {}

------------------------------------------------------------
-- execute(service, request)
--
-- service must expose:
--   handle(request) -> { ok, result?, error? }
------------------------------------------------------------

function Backend.execute(state, service, request)

  if type(service) ~= "table"
     or type(service.handle) ~= "function" then
    return {
      ok    = false,
      error = "invalid service (missing handle)"
    }
  end

  request = request or {}
  request.state = state

  local success, response = pcall(function()
    return service.handle(request)
  end)

  if not success then
    return {
      ok    = false,
      error = tostring(response)
    }
  end

  if type(response) ~= "table" then
    return {
      ok    = false,
      error = "service returned non-table response"
    }
  end

  if response.ok == nil then
    response.ok = true
  end

  return response
end

return Backend
