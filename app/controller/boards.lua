-- app/controller/boards.lua
--
-- Boards application controller.
--
-- Orchestrates ingestion + core systems.
-- NO CLI
-- NO ctx
-- NO sinks
-- NO printing

local Capture        = require("ingestion.board_capture")

local CompareInput   = require("core.compare.input")
local Compare        = require("core.compare")
local CompareFormat  = require("core.compare.formats.text")

local InvoiceInput   = require("core.invoice.input")
local InvoiceModel   = require("core.invoice.model")
local InvoiceFormat  = require("core.invoice.formats.text")

local Boards = {}

----------------------------------------------------------------
-- Compare
----------------------------------------------------------------

--- Compare an order against vendor offers.
--- @param order_path string
--- @param offer_paths string[]
--- @param opts table|nil
--- @return table formatted_output
function Boards.compare(order_path, offer_paths, opts)
    opts = opts or {}

    local order_capture = Capture.load(order_path)
    assert(#order_capture.sources == 1, "order must contain exactly one source")

    local order_source   = order_capture.sources[1]
    local offers_capture = Capture.load(offer_paths)

    local input = CompareInput.build_input(
        offers_capture,
        {
            id     = order_path,
            boards = order_source.boards.data,
        }
    )

    local model = Compare.run(input)

    -- output SHAPE selection (not delivery)
    if opts.format == "json" then
        return {
            kind = "json",
            data = model,
        }
    end

    -- default
    return CompareFormat.format(model)
end

----------------------------------------------------------------
-- Invoice
----------------------------------------------------------------

--- Generate an invoice from a single board source.
--- @param path string
--- @param opts table|nil
--- @return table formatted_output
function Boards.invoice(path, opts)
    opts = opts or {}

    local capture = Capture.load(path)
    assert(#capture.sources == 1, "invoice requires exactly one source")

    local input = InvoiceInput.build(capture)
    local model = InvoiceModel.build(input)

    if opts.format == "json" then
        return {
            kind = "json",
            data = model,
        }
    end

    -- default: text
    return InvoiceFormat.format(model)
end


----------------------------------------------------------------
-- Load (raw capture)
----------------------------------------------------------------

function Boards.load(paths)
    return Capture.load(paths)
end

return Boards
