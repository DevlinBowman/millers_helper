-- system/app/surface/status.lua

return function(Surface)

    function Surface:status()

        local hub   = self.hub
        local state = self.state

        local function resource_status(name)
            local configured = hub:is_configured(name)
            local loaded     = hub:is_loaded(name)

            local batch_count = 0

            if loaded then
                local runtime = hub:get(name)
                if runtime then
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

        return {
            user    = resource_status("user"),
            vendors = resource_status("vendors"),
            ledger  = {
                ledger_id = state:get_context("active_ledger") or "default",
            },
        }
    end

end
