-- core/domain/enrichment/planner.lua

local Planner = {}

local function collect_pricing_targets(requests)

    local boards = {}

    for _,r in ipairs(requests) do

        if r.service == "pricing" then

            local path = r.path

            if path[1] == "boards" and type(path[2]) == "number" then
                boards[path[2]] = true
            end

        end

    end

    return boards
end

function Planner.compile(batch, requests)

    local tasks = {}

    ------------------------------------------------
    -- pricing task
    ------------------------------------------------

    local boards = collect_pricing_targets(requests)

    if next(boards) then

        local list = {}

        for i,_ in pairs(boards) do
            list[#list+1] = i
        end

        tasks[#tasks+1] = {
            service = "pricing",
            boards  = list
        }

    end

    ------------------------------------------------
    -- allocations task
    ------------------------------------------------

    for _,r in ipairs(requests) do
        if r.service == "allocations" then

            tasks[#tasks+1] = {
                service = "allocations"
            }

            break
        end
    end

    return tasks
end

return Planner
