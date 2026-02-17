-- tools/diagnostic/pipelines/resolve_group.lua
--
-- Summarize a finished diagnostic scope into a stable report shape.
-- No IO, no side effects.

local Resolve = {}

local function is_table(x) return type(x) == "table" end

--- @param scope table|nil
--- @return table report
function Resolve.run(scope)
    if not is_table(scope) then
        return {
            ok = false,
            error = "no diagnostic scope",
            report = {
                signals = {},
                decisions = {},
                messages = {},
                counts = {},
                events = {},
            }
        }
    end

    local report = {
        label        = scope.label,
        tags         = scope.tags,
        started_at   = scope.started_at,
        finished_at  = scope.finished_at,
        duration_cpu = scope.duration_cpu,

        signals      = scope.signals or {},
        decisions    = scope.decisions or {},
        messages     = scope.messages or {},
        counts       = scope.counts or {},
        events       = scope.events or {},
    }

    return { ok = true, report = report }
end

return Resolve
