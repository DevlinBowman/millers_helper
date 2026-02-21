-- orchestrator/actions/run_compare.lua
--
-- Orchestrator action: run_compare
--
-- Coordinates:
--   - resource loading (infrastructure)
--   - service invocation (services.compare_service)
--   - state mutation
--
-- No CLI. No printing.

local ResourceLoader = require("infrastructure.resource_loader")
local CompareService = require("services.compare_service")

local Action = {}

Action.id = "run_compare"

----------------------------------------------------------------
-- can_run(state)
----------------------------------------------------------------

function Action.can_run(state)

  if type(state) ~= "table" then
    return false, "state required"
  end

  if not state.resources then
    return false, "no resources"
  end

  if type(state.resources.order_path) ~= "string"
     or state.resources.order_path == "" then
    return false, "order_path missing"
  end

  if type(state.resources.vendor_paths) ~= "table"
     or #state.resources.vendor_paths == 0 then
    return false, "vendor_paths missing"
  end

  return true
end

----------------------------------------------------------------
-- run(state, params)
----------------------------------------------------------------

function Action.run(state, params)

  params = params or {}

  ------------------------------------------------------------
  -- Validate
  ------------------------------------------------------------

  local ok, err = Action.can_run(state)
  if not ok then
    return state, {
      ok    = false,
      error = "[run_compare] " .. tostring(err),
    }
  end

  ------------------------------------------------------------
  -- Load primary bundle
  ------------------------------------------------------------

  local bundle, load_err =
    ResourceLoader.load_bundle(state.resources.order_path)

  if not bundle then
    return state, {
      ok    = false,
      error = "[run_compare] order load failed: " .. tostring(load_err),
    }
  end

  ------------------------------------------------------------
  -- Load vendor bundles
  ------------------------------------------------------------

  local sources = {}

  for _, vpath in ipairs(state.resources.vendor_paths) do

    local vbundle, verr =
      ResourceLoader.load_bundle(vpath)

    if not vbundle then
      return state, {
        ok    = false,
        error = "[run_compare] vendor load failed: " .. tostring(verr),
      }
    end

    table.insert(sources, {
      name   = vpath,
      boards = vbundle.boards or {},
    })
  end

  ------------------------------------------------------------
  -- Call Service
  ------------------------------------------------------------

  local service_out = CompareService.handle({
    bundle  = bundle,
    sources = sources,
    opts    = params.opts or {},
  })

  if not service_out.ok then
    return state, service_out
  end

  ------------------------------------------------------------
  -- Mutate State (controlled)
  ------------------------------------------------------------

  state.results = state.results or {}
  state.results.compare = service_out

  return state, service_out
end

return Action
