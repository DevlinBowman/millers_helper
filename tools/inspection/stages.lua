-- tools/inspection/stages.lua
--
-- Canonical inspection stop points (INGESTION V2)

local Stages = {
    READ         = "read",
    RECORDS      = "records",
    TEXT_PARSER  = "text_parser",
    INGEST       = "ingest",
}

return Stages
