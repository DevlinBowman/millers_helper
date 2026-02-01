-- tests/_helpers.lua
--
-- Shared helpers for test assertions.
-- Intentionally tiny and explicit.

local H = {}

function H.assert_ok(ok, err)
    if not ok then
        error(err or "assert_ok failed")
    end
end

function H.assert_kind(obj, kind, label)
    if type(obj) ~= "table" or obj.kind ~= kind then
        error((label or "value") .. " expected kind='" .. kind .. "'")
    end
end

function H.assert_table(t, label)
    if type(t) ~= "table" then
        error((label or "value") .. " expected table")
    end
end

function H.assert_nonempty(arr, label)
    if type(arr) ~= "table" or #arr == 0 then
        error((label or "array") .. " expected non-empty table")
    end
end

return H
