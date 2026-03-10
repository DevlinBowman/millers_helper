-- system/runtime/mutator.lua
-- function: Mutator.apply

local Mutator = {}

local function apply_patch(object, patch)

    local changes = patch.changes or {}

    if changes.boards then
        for index, fields in pairs(changes.boards) do
            local board = object.boards[index]
            if board then
                for key, value in pairs(fields) do
                    board[key] = value
                end
            end
        end
    end

    for key, value in pairs(changes) do
        if key ~= "boards" then
            object[key] = value
        end
    end
end

function Mutator.apply(object, patches)

    for _, patch in ipairs(patches or {}) do
        apply_patch(object, patch)
    end
end

return Mutator
