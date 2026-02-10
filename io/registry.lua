-- io/registry.lua
--
-- Internal IO facade.
-- Stable surface for domain systems.
-- No orchestration. No policy. No IO branching.

local Registry = {}

-- Core primitives
Registry.fs        = require("io.helpers.fs")
Registry.read      = require("io.read.read")
Registry.write     = require("io.write.write")
Registry.normalize = require("io.normalize")

-- Codecs (explicit, addressable)
Registry.codecs = {
    json      = require("io.codecs.json"),
    delimited = require("io.codecs.delimited"),
    text      = require("io.codecs.text"),
}

-- Sinks (pluggable output targets)
Registry.sinks = {
    stdout = require("io.sinks.stdout"),
    file   = require("io.sinks.file"),
    buffer = require("io.sinks.buffer"),
}

return Registry
