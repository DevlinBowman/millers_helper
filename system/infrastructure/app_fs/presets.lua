local IO = require("platform.io.controller")
local AppFS = require("system.infrastructure.app_fs.controller")
local Helpers = require("system.app.fs.helpers")

local Presets = {}

local helpers = Helpers.new()


function Presets.write(domain, name, tbl)
    local root = AppFS.system_presets():path()
    local dir  = helpers:join(root, domain)
    local file = helpers:child(dir, name .. ".json")

    IO.write_strict(file, {
        codec = "json",
        data  = tbl
    })

    return file
end

function Presets.read(domain, name)

    local root = AppFS.system_presets():path()
    local dir  = helpers:join(root, domain)

    local file = helpers:child(dir, name .. ".json")

    local result =
        IO.read_strict(file)

    return result.data
end

function Presets.list(domain)

    local root = AppFS.system_presets()
    local dir = helpers:join(root, domain)
    local res = require("system.infrastructure.app_fs.result").new(dir)

    local inspection = res:inspect()

    if not inspection.exists() or not inspection.is_directory() then
        return {}
    end

    local names = {}

    for _, file in ipairs(res:files()) do
        local name = file:match("([^/]+)%.json$")
        if name then
            names[#names + 1] = name
        end
    end

    table.sort(names)

    return names
end

return Presets
