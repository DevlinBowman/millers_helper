notes for remembering

canonical "Load" lives @ core/domain/runtime/controller.lua

``` lua
core.domain.runtime.controller
-- has been routed through
local runtime, err = state._hub:require("user")
```

system/app/surface.lua
    - owns state
    - owns hub

system/app/runtime_hub.lua
    - owns specs
    - owns runtime cache
    - is the only system entry to runtime domain


core/domain/runtime/controller.lua
    - is the only runtime domain entry

core/domain/runtime/pipelines/load.lua
    - pure loader routing



✔ Only RuntimeHub calls RuntimeController.load

✔ Services never call RuntimeController directly

✔ Surface never calls RuntimeController directly

✔ Runtime domain never touches system state

🎯 Next Required Refactor

The system is now at the point where we must:

Refactor one service (QuoteService) to:
	•	Use state._hub:require("user")
	•	Stop reading state.resources.order_path
	•	Stop calling RuntimeDomain.load()

After that, everything else will follow cleanly.
