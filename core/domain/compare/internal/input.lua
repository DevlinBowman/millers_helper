-- core/domain/compare/internal/input.lua
--
-- Adapter: ingestion bundle → compare input
-- Supports multiple vendor sources.
-- Uses canonical runtime board shape directly.
-- No rebuilding. No grouping. No mutation.

local M = {}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- @param bundle table { order=table, boards=table[] }
--- @param sources table[] { { name=string, boards=table[] } }
--- @param opts table|nil
--- @return table compare_input
function M.from_bundle(bundle, sources, opts)
    opts = opts or {}

    assert(type(bundle) == "table", "bundle required")
    assert(type(bundle.order) == "table", "bundle.order required")
    assert(type(bundle.boards) == "table", "bundle.boards required")

    assert(type(sources) == "table", "sources table required")

    local normalized_sources = {}

    for i, src in ipairs(sources) do
        assert(type(src) == "table", "sources[" .. i .. "] must be table")
        assert(type(src.name) == "string", "sources[" .. i .. "].name required")
        assert(type(src.boards) == "table", "sources[" .. i .. "].boards required")

        normalized_sources[#normalized_sources + 1] = {
            name   = src.name,
            boards = src.boards,
        }
    end

    return {
        order = {
            id     = bundle.order.order_number or bundle.order.id,
            boards = bundle.boards,
        },
        sources = normalized_sources
    }
end

return M
