local Registry = require("core.model.fmt.registry")

local Controller = {}

Controller.CONTRACT = {
    format = {
        in_  = { object = true, preset = true },
        out  = { line = true },
    }
}

--- Format an object using a named preset.
--- @param object table
--- @param preset string
--- @param opts table|nil
--- @return string
function Controller.format(object, preset, opts)
    assert(type(object) == "table", "Fmt.format(): object table required")
    assert(type(preset) == "string", "Fmt.format(): preset name required")

    local preset_def = Registry.presets[preset]
    assert(preset_def, "Fmt.format(): unknown preset '" .. preset .. "'")

    return Registry.engine.run(object, preset_def, opts or {})
end

return Controller
