local Status = {}
Status.__index = Status

function Status.new(surface)
    local self = setmetatable({}, Status)
    self._surface = surface
    return self
end

------------------------------------------------------------
-- Internal helper
------------------------------------------------------------

local function resource_status(hub, name)
    local configured = hub:is_configured(name)
    local loaded     = hub:is_loaded(name)

    local batch_count = 0

    if loaded then
        local runtime = hub:get(name)
        if runtime and runtime.batches then
            local batch_list = runtime:batches()
            if type(batch_list) == "table" then
                batch_count = #batch_list
            end
        end
    end

    return {
        configured = configured,
        loaded     = loaded,
        batches    = batch_count,
    }
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

function Status:get()
    local hub   = self._surface.hub
    local state = self._surface.state

    return {
        user = {
            order   = resource_status(hub, "user.order"),
            vendors = resource_status(hub, "user.vendors"),
        },

        system = {
            vendors = resource_status(hub, "system.vendors"),
        },

        ledger = {
            ledger_id = state:get_context("active_ledger") or "default",
        },
    }
end

return Status
