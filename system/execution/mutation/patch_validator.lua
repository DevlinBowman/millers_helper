local PatchValidator = {}

local function assert_patch_shape(patch)

    assert(type(patch) == "table",
        "[execution.patch_validator] patch must be table")

    assert(type(patch.capability) == "string" and patch.capability ~= "",
        "[execution.patch_validator] patch.capability required")

    assert(type(patch.changes) == "table",
        "[execution.patch_validator] patch.changes required")

    local board_changes =
        patch.changes.boards

    if board_changes ~= nil then

        assert(type(board_changes) == "table",
            "[execution.patch_validator] patch.changes.boards must be table")

        for board_index, fields in pairs(board_changes) do

            assert(type(board_index) == "number" and board_index >= 1,
                "[execution.patch_validator] board index must be integer >= 1")

            assert(type(fields) == "table",
                "[execution.patch_validator] board field map must be table")

        end
    end
end

function PatchValidator.validate_patch(patch)

    assert_patch_shape(patch)
    return true
end

function PatchValidator.validate_list(patches)

    assert(type(patches) == "table",
        "[execution.patch_validator] patch list must be table")

    for i = 1, #patches do
        PatchValidator.validate_patch(patches[i])
    end

    return true
end

return PatchValidator
