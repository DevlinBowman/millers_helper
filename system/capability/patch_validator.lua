-- system/capability/patch_validator.lua

local PatchValidator = {}

local function assert_patch_shape(patch)
    assert(type(patch) == "table", "[capability.patch_validator] patch must be table")

    assert(type(patch.capability) == "string" and patch.capability ~= "",
        "[capability.patch_validator] patch.capability required")

    assert(type(patch.changes) == "table",
        "[capability.patch_validator] patch.changes required")

    local board_changes = patch.changes.boards
    if board_changes ~= nil then
        assert(type(board_changes) == "table",
            "[capability.patch_validator] patch.changes.boards must be table")

        for board_index, fields in pairs(board_changes) do
            assert(type(board_index) == "number" and board_index >= 1,
                "[capability.patch_validator] board index must be integer >= 1")

            assert(type(fields) == "table",
                "[capability.patch_validator] board field map must be table")

            for field_name, _ in pairs(fields) do
                assert(type(field_name) == "string" and field_name ~= "",
                    "[capability.patch_validator] board field name must be non-empty string")
            end
        end
    end

    for field_name, _ in pairs(patch.changes) do
        assert(type(field_name) == "string" and field_name ~= "",
            "[capability.patch_validator] change field name must be non-empty string")
    end
end

---@param patch table
---@return boolean
function PatchValidator.validate_patch(patch)
    assert_patch_shape(patch)
    return true
end

---@param patches table
---@return boolean
function PatchValidator.validate_list(patches)
    assert(type(patches) == "table",
        "[capability.patch_validator] patch list must be table")

    for index = 1, #patches do
        PatchValidator.validate_patch(patches[index])
    end

    return true
end

return PatchValidator
