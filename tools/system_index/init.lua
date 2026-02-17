local Index = require("tools.system_index").controller

local snapshot = Index.build()

for module_name, data in pairs(snapshot.modules) do
    print("MODULE:", module_name)

    for fn_name in pairs(data.controller_surface or {}) do
        print("  •", fn_name)
    end
end
