local Persist = require("platform.persist").controller

local VendorPackage = {}
VendorPackage.__index = VendorPackage

function VendorPackage.new(dto)
    assert(type(dto) == "table", "VendorPackage requires table")
    return setmetatable({ __data = dto }, VendorPackage)
end

------------------------------------------------------------
-- Accessors
------------------------------------------------------------

function VendorPackage:vendor()
    return self.__data.vendor
end

function VendorPackage:rows()
    return self.__data.rows or {}
end

function VendorPackage:meta()
    return self.__data.meta or {}
end

function VendorPackage:raw()
    return self.__data
end

------------------------------------------------------------
-- Persistence
------------------------------------------------------------

function VendorPackage:write(path, codec, opts)
    assert(type(path) == "string", "path required")
    return Persist.write(path, self.__data, codec, opts)
end

function VendorPackage:write_strict(path, codec, opts)
    assert(type(path) == "string", "path required")
    assert(type(codec) == "string", "codec required")

    if codec == "delimited" then
        -- delimited expects array of rows
        return Persist.write_strict(path, self:rows(), codec, opts)
    end

    -- structured codecs persist full package
    return Persist.write_strict(path, self.__data, codec, opts)
end

return VendorPackage
