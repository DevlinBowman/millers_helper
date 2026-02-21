-- system/services/compare_service.lua

local RuntimeDomain = require("core.domain.runtime.controller")
local CompareDomain = require("core.domain.compare.controller")

local CompareService = {}

function CompareService.handle(req)

  local state = req.state
  if not state then
    return { ok = false, error = "missing state" }
  end

  local order_path  = state:get_loadable("order")
  local vendor_path = state:get_loadable("vendor")

  if not order_path then
    return { ok = false, error = "missing loadable: order" }
  end

  if not vendor_path then
    return { ok = false, error = "missing loadable: vendor" }
  end

  local order_runtime  = RuntimeDomain.load(order_path)
  local vendor_runtime = RuntimeDomain.load(vendor_path)

  local order_bundle  = order_runtime:batches()[1]
  local vendor_bundle = vendor_runtime:batches()[1]

  local result = CompareDomain.compare(
    order_bundle,
    {
      { name = vendor_path, boards = vendor_bundle.boards }
    },
    {}
  )

  return {
    ok     = true,
    result = result
  }
end

return CompareService
