
# To get this fucking thing running you must preform the following ritual
- canopy/ MUST be inside of a parent dir called 'lua' for nvim to find it
- that lua folder must be inside the 'project_root' listed below

- the caller must contain the following code vvv
```lua
local project_root = "/Users/ven/Desktop/2026-lumber-app-v3"
if not string.find(vim.o.runtimepath, project_root, 1, true) then
    vim.opt.runtimepath:prepend(project_root)
end
local Canopy = require("canopy")
```

if you do these things you can get the project to find canopy so your caller can use it
