-- io/codecs/delimited.lua
--
-- Delimited text codec (CSV / TSV).
-- Owns both read and write behavior.
-- Fails fast on IO or format errors.
--
-- Contract:
--   • read(path)  -> { codec = "table", data = DelimitedTable } | throws
--   • write(path, data) -> true | throws

---@class DelimitedTable
---@field header string[]
---@field rows   string[][]

---@class DelimitedReadResult
---@field codec "table"
---@field data  DelimitedTable

local Delimited = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

---@param line string
---@param sep string
---@return string[]
local function split(line, sep)
    local out = {}
    local pattern = string.format("([^%s]+)", sep)

    for field in line:gmatch(pattern) do
        out[#out + 1] = field
    end

    return out
end

---@param fields string[]
---@param sep string
---@return string
local function join(fields, sep)
    return table.concat(fields, sep)
end

----------------------------------------------------------------
-- Read
----------------------------------------------------------------

---@param path string
---@return DelimitedReadResult
function Delimited.read(path)
    local ext = path:match("^.+%.([^/\\]+)$")
    if not ext then
        error("input file must have extension")
    end

    local sep = (ext:lower() == "tsv") and "\t" or ","

    local fh, err = io.open(path, "r")
    if not fh then
        error(err)
    end

    local header
    local rows = {}

    for line in fh:lines() do
        if not header then
            header = split(line, sep)
        else
            rows[#rows + 1] = split(line, sep)
        end
    end

    fh:close()

    if not header then
        error("missing header row")
    end

    for i, row in ipairs(rows) do
        if #row ~= #header then
            error(string.format(
                "row %d has %d fields (expected %d)",
                i, #row, #header
            ))
        end
    end

    return {
        codec = "delimited",
        data  = {
            header = header,
            rows   = rows,
        },
    }
end

----------------------------------------------------------------
-- Write
----------------------------------------------------------------

---@param path string
---@param data DelimitedTable
---@param opts? { sep?: string }
---@return true
function Delimited.write(path, data, opts)
    assert(type(data) == "table", "data required")
    assert(type(data.header) == "table", "missing header")
    assert(type(data.rows) == "table", "missing rows")

    opts = opts or {}
    local sep = opts.sep or ","

    local fh, err = io.open(path, "w")
    if not fh then
        error(err)
    end

    fh:write(join(data.header, sep), "\n")

    for _, row in ipairs(data.rows) do
        fh:write(join(row, sep), "\n")
    end

    fh:close()
    return true
end

return Delimited
