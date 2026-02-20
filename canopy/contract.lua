-- canopy/contract.lua
--
-- Canopy Host Integration Contract (v1)
--
-- This file defines and enforces the required shape
-- for Specs and NodeSpecs passed into Canopy.
--
-- Canopy never depends on host code.
-- Host must satisfy this contract.

local Contract = {}

Contract.VERSION = "1.0.0"

----------------------------------------------------------------
-- Utility
----------------------------------------------------------------

local function type_error(path, expected, got)
    error(
        string.format(
            "Canopy Spec Contract violation at '%s': expected %s, got %s",
            path,
            expected,
            type(got)
        ),
        3
    )
end

local function assert_type(path, value, expected)
    if type(value) ~= expected then
        type_error(path, expected, value)
    end
end

----------------------------------------------------------------
-- NodeSpec validation
----------------------------------------------------------------

local function validate_node(node, path)

    assert_type(path, node, "table")

    if type(node.id) ~= "string" then
        type_error(path .. ".id", "string", node.id)
    end

    if type(node.label) ~= "string" then
        type_error(path .. ".label", "string", node.label)
    end

    -- Optional interaction types
    if node.action ~= nil then
        assert_type(path .. ".action", node.action, "function")
    end

    if node.next ~= nil then
        assert_type(path .. ".next", node.next, "function")
    end

    if node.resolve ~= nil then
        assert_type(path .. ".resolve", node.resolve, "function")
    end

    if node.edit ~= nil then
        assert_type(path .. ".edit", node.edit, "function")
    end

    if node.children ~= nil then
        assert_type(path .. ".children", node.children, "table")
        for i, child in ipairs(node.children) do
            validate_node(child, path .. ".children[" .. i .. "]")
        end
    end
end

----------------------------------------------------------------
-- Spec validation
----------------------------------------------------------------

function Contract.validate_spec(spec)

    assert_type("spec", spec, "table")

    if type(spec.id) ~= "string" then
        type_error("spec.id", "string", spec.id)
    end

    if type(spec.title) ~= "string" then
        type_error("spec.title", "string", spec.title)
    end

    if type(spec.nodes) ~= "table" then
        type_error("spec.nodes", "table", spec.nodes)
    end

    for i, node in ipairs(spec.nodes) do
        validate_node(node, "spec.nodes[" .. i .. "]")
    end

    return true
end

return Contract
