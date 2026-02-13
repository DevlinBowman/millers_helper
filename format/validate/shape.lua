-- format/validate/shape.lua
--
-- Structural shape validation only.

local Shape = {}

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------

local function is_array(t)
    if type(t) ~= "table" then return false end
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" then return false end
        if k > n then n = k end
    end
    return n == #t
end

local function is_string_array(t)
    if not is_array(t) then return false end
    for _, v in ipairs(t) do
        if type(v) ~= "string" then
            return false
        end
    end
    return true
end

----------------------------------------------------------------
-- lines
----------------------------------------------------------------

function Shape.lines(v)
    return is_string_array(v)
end

----------------------------------------------------------------
-- table (csv logical form)
----------------------------------------------------------------

function Shape.table(v)
    if type(v) ~= "table" then return false end
    if not is_string_array(v.header) then return false end
    if not is_array(v.rows) then return false end

    local width = #v.header
    for _, row in ipairs(v.rows) do
        if not is_string_array(row) then
            return false
        end
        if #row ~= width then
            return false
        end
    end

    return true
end

----------------------------------------------------------------
-- object_array
----------------------------------------------------------------

function Shape.object_array(v)
    if not is_array(v) then return false end
    for _, obj in ipairs(v) do
        if type(obj) ~= "table" then
            return false
        end
    end
    return true
end

----------------------------------------------------------------
-- object
----------------------------------------------------------------

function Shape.object(v)
    return type(v) == "table" and not is_array(v)
end

return Shape
