-- core/domain/invoice/internal/input.lua

local Input = {}

function Input.build(capture, source_id)
    assert(type(capture) == "table", "capture required")

    if source_id then
        for _, src in ipairs(capture.sources or {}) do
            if src.source_id == source_id then
                return { boards = src.boards.data }
            end
        end
        error("source not found: " .. tostring(source_id))
    end

    local boards = {}

    for _, src in ipairs(capture.sources or {}) do
        for _, b in ipairs(src.boards.data or {}) do
            boards[#boards + 1] = b
        end
    end

    return { boards = boards }
end

return Input
