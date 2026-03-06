-- core/domain/enrichment/executor.lua

local Services = require("core.domain.enrichment.services")

local Executor = {}

function Executor.run(object, tasks, opts)
    opts = opts or {}

    local patches = {}
    local skipped = {}

    for _, task in ipairs(tasks or {}) do
        local service = Services.get(task.service)

        if not service then
            skipped[#skipped + 1] = {
                service = task.service,
                scope   = task.scope,
                reason  = "service_not_registered",
            }
            goto continue
        end

        if type(service.resolve) ~= "function" then
            skipped[#skipped + 1] = {
                service = task.service,
                scope   = task.scope,
                reason  = "service_missing_resolve",
            }
            goto continue
        end

        local patch = service.resolve(object, task, opts)

        if patch then
            patches[#patches + 1] = patch
        else
            skipped[#skipped + 1] = {
                service = task.service,
                scope   = task.scope,
                reason  = "service_returned_nil_patch",
            }
        end

        ::continue::
    end

    return {
        patches = patches,
        skipped = skipped,
    }
end

return Executor
