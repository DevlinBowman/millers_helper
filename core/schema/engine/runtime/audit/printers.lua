-- core/schema/engine/runtime/audit/printers.lua

local Walker = require("core.schema.engine.runtime.walker")
local State  = require("core.schema.engine.runtime.state")

local Printers = {}

------------------------------------------------------------
-- Print report
------------------------------------------------------------

function Printers.print(report)

    if not report then
        print("nil report")
        return
    end

    local struct = report.structure_ok and "✓" or "✗"
    local valid  = report.validation_ok and "✓" or "✗"

    print(report.domain .. " [structure:" .. struct .. " validation:" .. valid .. "]")

    if report.missing_fields then
        for _, f in ipairs(report.missing_fields) do
            print("  missing:", f)
        end
    end

    if report.extra_fields then
        for _, f in ipairs(report.extra_fields) do
            print("  extra:", f)
        end
    end

    if report.validation_errors then
        for _, e in ipairs(report.validation_errors) do
            print("  error:", e)
        end
    end

end

------------------------------------------------------------
-- Tree view
------------------------------------------------------------

function Printers.tree(domain, obj)

    Walker.walk(domain, obj, function(d, f, v, depth)

        local prefix = string.rep("  ", depth)

        if v == nil and f.required then
            print(prefix .. f.name .. " ✗")
            return
        end

        if v == nil then
            print(prefix .. f.name .. " ○")
            return
        end

        if not f.reference then
            print(prefix .. f.name .. " = " .. tostring(v))
            return
        end

        if State.values[f.reference] then
            print(prefix .. f.name .. " = " .. tostring(v))
            return
        end

        print(prefix .. f.name)

    end)

end

------------------------------------------------------------
-- Table view
------------------------------------------------------------

function Printers.table(domain, obj)

    local Walker = require("core.schema.engine.runtime.walker")
    local State  = require("core.schema.engine.runtime.state")

    ------------------------------------------------
    -- helpers
    ------------------------------------------------

    local function pad(s, n)
        s = tostring(s or "")
        if #s >= n then return s end
        return s .. string.rep(" ", n - #s)
    end

    ------------------------------------------------
    -- column widths
    ------------------------------------------------

    local W_FIELD = 18
    local W_STATE = 10
    local W_VALUE = 20

    ------------------------------------------------
    -- state
    ------------------------------------------------

    local current_domain = nil

    ------------------------------------------------
    -- walker
    ------------------------------------------------

    Walker.walk(domain, obj, function(d, f, v)

        ------------------------------------------------
        -- domain header
        ------------------------------------------------

        if d ~= current_domain then

            current_domain = d

            print("")
            print(d)
            print(
                "  " ..
                pad("FIELD", W_FIELD) ..
                pad("STATE", W_STATE) ..
                "VALUE"
            )
            print(
                "  " ..
                pad("-----", W_FIELD) ..
                pad("-----", W_STATE) ..
                "-----"
            )

        end

        ------------------------------------------------
        -- required missing
        ------------------------------------------------

        if v == nil and f.required then

            print(
                "  " ..
                pad(f.name, W_FIELD) ..
                pad("required", W_STATE) ..
                "✗ missing"
            )

            return
        end

        ------------------------------------------------
        -- optional missing
        ------------------------------------------------

        if v == nil then

            print(
                "  " ..
                pad(f.name, W_FIELD) ..
                pad("optional", W_STATE) ..
                "○"
            )

            return
        end

        ------------------------------------------------
        -- object reference
        ------------------------------------------------

        if f.reference and State.fields[f.reference] then

            print(
                "  " ..
                pad(f.name, W_FIELD) ..
                pad("object", W_STATE) ..
                "→ " .. f.reference
            )

            return
        end

        ------------------------------------------------
        -- enum / value reference
        ------------------------------------------------

        if f.reference and State.values[f.reference] then

            print(
                "  " ..
                pad(f.name, W_FIELD) ..
                pad("value", W_STATE) ..
                tostring(v)
            )

            return
        end

        ------------------------------------------------
        -- primitive
        ------------------------------------------------

        print(
            "  " ..
            pad(f.name, W_FIELD) ..
            pad("value", W_STATE) ..
            tostring(v)
        )

    end)

end

return Printers
