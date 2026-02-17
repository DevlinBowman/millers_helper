-- tools/system_index/internal/scanner.lua
--
-- Pure runtime module scanner.
-- Discovers arc-spec compliant modules from package.loaded.

local Scanner = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function is_table(value)
    return type(value) == "table"
end

local function is_function(value)
    return type(value) == "function"
end

local function is_arc_module(module)
    if not is_table(module) then
        return false
    end

    if not is_table(module.controller) then
        return false
    end

    if not is_table(module.registry) then
        return false
    end

    return true
end

local function extract_controller_surface(controller)
    local surface = {}

    for key, value in pairs(controller) do
        if is_function(value) then
            surface[key] = {
                type = "function",
            }
        end
    end

    return surface
end

local function extract_contracts(controller)
    if not is_table(controller.CONTRACT) then
        return nil
    end

    local contracts = {}

    for name, spec in pairs(controller.CONTRACT) do
        contracts[name] = {
            in_  = spec.in_  or {},
            out  = spec.out  or {},
        }
    end

    return contracts
end

----------------------------------------------------------------
-- Public
----------------------------------------------------------------

--- Scan loaded modules for arc-spec compliance.
--- @return table<string, table>
function Scanner.scan_loaded_modules()
    local discovered = {}

    for module_name, module in pairs(package.loaded) do
        if is_arc_module(module) then
            discovered[module_name] = {
                controller_surface = extract_controller_surface(module.controller),
                contracts          = extract_contracts(module.controller),
            }
        end
    end

    return discovered
end

return Scanner
