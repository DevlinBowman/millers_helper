-- infrastructure/resource_loader.lua
--
-- File → runtime → bundle adapter.
-- Infrastructure only.

local RuntimeDomain = require("core.domain.runtime.controller")

local ResourceLoader = {}

function ResourceLoader.load_bundle(path, opts)
  local runtime = RuntimeDomain.load(path, opts or {})
  local batches = runtime:batches()

  if not batches or #batches == 0 then
    return nil, "no batches returned"
  end

  return batches[1]
end

return ResourceLoader
