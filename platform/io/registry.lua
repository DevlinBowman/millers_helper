-- io/registry.lua

local Registry = {}

Registry.fs    = require("platform.io.helpers.fs")
Registry.read  = require("platform.io.read.read")
Registry.write = require("platform.io.pipelines.write")

Registry.validate = {
    input = require("platform.io.validate.input"),
}

Registry.codecs = {
    json      = require("platform.io.codecs.json"),
    delimited = require("platform.io.codecs.delimited"),
    text      = require("platform.io.codecs.text"),
    lua       = require("platform.io.codecs.lua")
}

Registry.sinks = {
    stdout = require("platform.io.sinks.stdout"),
    file   = require("platform.io.sinks.file"),
    buffer = require("platform.io.sinks.buffer"),
}

return Registry
