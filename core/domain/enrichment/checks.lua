local Checks = {}

function Checks.is_empty(value)

    if value == nil then
        return true
    end

    if type(value) == "table" and next(value) == nil then
        return true
    end

    if type(value) == "string" and value == "" then
        return true
    end

    return false
end


function Checks.is_nil(value)
    return value == nil
end


function Checks.is_zero(value)

    if type(value) == "number" and value == 0 then
        return true
    end

    return false
end


function Checks.is_incomplete(value)

    if Checks.is_nil(value) then
        return true
    end

    if Checks.is_empty(value) then
        return true
    end

    if Checks.is_zero(value) then
        return true
    end

    return false
end

return Checks
