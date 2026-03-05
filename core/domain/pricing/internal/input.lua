-- core/domain/pricing/internal/input.lua

local Input = {}

function Input.extract_boards(source)

    if type(source) ~= "table" then
        error("[pricing.domain] invalid source")
    end

    -- RuntimeResult
    if type(source.boards) == "function" then
        return source:boards()
    end

    -- RuntimeBatch
    if source.boards then
        return source.boards
    end

    -- raw list
    return source
end

return Input
