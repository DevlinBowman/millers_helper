-- io/registry.lua

local Registry = {}

Registry.fs    = require("io.helpers.fs")
Registry.read  = require("io.read.read")
Registry.write = require("io.write.write")

Registry.validate = {
    input = require("io.validate.input"),
}

Registry.codecs = {
    json      = require("io.codecs.json"),
    delimited = require("io.codecs.delimited"),
    text      = require("io.codecs.text"),
    lua       = require("io.codecs.lua")
}

Registry.sinks = {
    stdout = require("io.sinks.stdout"),
    file   = require("io.sinks.file"),
    buffer = require("io.sinks.buffer"),
}

return Registry
