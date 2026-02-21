-- format/transforms/lines_to_objects.lua
--
-- Transport transform:
--   lines -> canonical objects
--
-- Parser is used here as a structural extractor.
-- Format layer owns transport normalization.

local Shape   = require("platform.format.validate.shape")
local Parsers = require("platform.parsers").controller

local M = {}

function M.run(lines)
    if not Shape.lines(lines) then
        return nil, "invalid lines shape"
    end

    -- Delegate structural extraction to parser
    local parsed, err = Parsers.parse_text(lines)
    if not parsed then
        return nil, err or "text parser failed"
    end

    -- Validate parser output (semantic / structural gate)
    local ParserGate = require("platform.format.validate.parser_gate")
    local ok, gate_err = ParserGate.validate(parsed)
    if not ok then
        return nil, gate_err
    end

    if type(parsed.data) ~= "table" then
        return nil, "parser did not return object array"
    end

    return parsed.data
end

return M
