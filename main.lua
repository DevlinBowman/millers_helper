local I         = require('inspector')
local Adapter   = require("ingestion.adapter.readfile")
local Writer    = require("file_handler")
local Serialize = require("core.board.serialize")

-- local result = assert(Adapter.ingest("tests/data_format/old_sheet.csv"))
-- assert(result.kind == "boards")
-- I.print(result)


local data = assert(Adapter.ingest("tests/data_format/input.txt"))
local inspect_opts = { ignore_keys = '_tokens'}
I.print(data, inspect_opts)


-- local table_data = Serialize.boards_to_table(result.data)

-- Writer.write("boards.csv", "table", table_data)
