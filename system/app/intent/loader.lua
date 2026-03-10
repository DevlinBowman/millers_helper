-- system/app/intent/loader.lua

local IO = require("platform.io.controller")

local IntentLoader = {}

---@param store AppFSStore
---@return table
function IntentLoader.load(store)

    local root = store:preset_domain("intent")

    local inspection = root:inspect()

    if not inspection.exists() or not inspection.is_directory() then
        return {}
    end

    local presets = {}

    for _, file in ipairs(root:files()) do

        local name = file:match("([^/]+)%.json$")

        if name then

            local result =
                IO.read_strict(file)

            local data =
                result and result.data

            if type(data) ~= "table" then
                error("[intent.loader] preset must decode to table: " .. file)
            end

            presets[name] = data
        end
    end

    return presets
end

return IntentLoader
