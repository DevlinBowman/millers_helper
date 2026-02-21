-- services/compare_service.lua
--
-- Application service for compare.
-- Stateless. No IO. No file loading.
-- Wraps core.domain.compare.controller.

local CompareController = require("core.domain.compare.controller")

local CompareService = {}

----------------------------------------------------------------
-- validate_request
----------------------------------------------------------------

local function validate_request(req)
  if type(req) ~= "table" then
    return false, "request must be table"
  end

  if type(req.bundle) ~= "table" then
    return false, "request.bundle required"
  end

  if type(req.sources) ~= "table" then
    return false, "request.sources required"
  end

  return true
end

----------------------------------------------------------------
-- handle
----------------------------------------------------------------

function CompareService.handle(request)

  local ok, err = validate_request(request)
  if not ok then
    return {
      ok    = false,
      error = "[compare_service] " .. err,
    }
  end

  local bundle  = request.bundle
  local sources = request.sources
  local opts    = request.opts or {}

  local success, result_or_err = pcall(function()

    local controller_out =
      CompareController.compare(bundle, sources, opts)

    return controller_out
  end)

  if not success then
    return {
      ok    = false,
      error = "[compare_service] " .. tostring(result_or_err),
    }
  end

  return {
    ok     = true,
    result = result_or_err.result,
    model  = result_or_err.model,
  }
end

return CompareService
