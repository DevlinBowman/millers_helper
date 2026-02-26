-- core/domain/vendor_reference/registry.lua
--
-- Flat capability map (no orchestration, no validation, no trace)

local Signals   = require("core.domain.vendor_reference.internal.signals")
local Vendor    = require("core.domain.vendor_reference.internal.vendor")
local Key       = require("core.domain.vendor_reference.internal.key")
local Envelope  = require("core.domain.vendor_reference.internal.envelope")
local Reconcile = require("core.domain.vendor_reference.internal.reconcile")

local Schema    = require("core.domain.vendor_reference.internal.schema")
local Merge     = require("core.domain.vendor_reference.internal.merge")

local Package   = require("core.domain.vendor_reference.internal.package")

return {
    signals   = Signals,
    vendor    = Vendor,
    key       = Key,
    envelope  = Envelope,
    reconcile = Reconcile,

    schema    = Schema,
    merge     = Merge,

    package   = Package,
}
