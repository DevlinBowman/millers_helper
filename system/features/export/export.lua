-- system/features/export/export.lua
--
-- High-level export pipeline.
--
-- Responsibilities:
--   • Project domain groups to canonical objects
--   • Encode via format layer
--   • Write via IO
--
-- Default codec: "delimited"

local Project = require("pipelines.export.project")
local Format  = require("platform.format.controller")
local IO      = require("platform.io.controller")

local Trace    = require("tools.trace.trace")
local Contract = require("core.contract")

local Export = {}

----------------------------------------------------------------
-- Contract
----------------------------------------------------------------

Export.CONTRACT = {
    write_groups = {
        in_ = {
            path   = true,
            groups = true,
            codec  = false,
            opts   = false,
        },
        out = {
            path       = true,
            ext        = true,
            size_bytes = true,
            hash       = true,
            write_time = true,
        },
    },
}

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Export.write_groups(path, groups, codec, opts)

    Trace.contract_enter("pipelines.export.write_groups")
    Trace.contract_in(Export.CONTRACT.write_groups.in_)

    Contract.assert(
        { path = path, groups = groups, codec = codec, opts = opts },
        Export.CONTRACT.write_groups.in_
    )

    codec = codec or "delimited"
    opts  = opts  or {}

    ------------------------------------------------------------
    -- Project
    ------------------------------------------------------------

    local objects = Project.groups_to_objects(groups)

    ------------------------------------------------------------
    -- Encode
    ------------------------------------------------------------

    local encoded, encode_err = Format.encode(codec, objects)
    if not encoded then
        Trace.contract_leave()
        return nil, encode_err
    end

    ------------------------------------------------------------
    -- Write
    ------------------------------------------------------------

    local meta, write_err = IO.write(path, encoded)
    if not meta then
        Trace.contract_leave()
        return nil, write_err
    end

    Trace.contract_out(
        Export.CONTRACT.write_groups.out,
        "io.controller.write",
        "caller"
    )

    Contract.assert(meta, Export.CONTRACT.write_groups.out)

    Trace.contract_leave()
    return meta
end

----------------------------------------------------------------
-- Strict variant
----------------------------------------------------------------

function Export.write_groups_strict(path, groups, codec, opts)
    local meta, err = Export.write_groups(path, groups, codec, opts)
    if not meta then
        error(err, 2)
    end
    return meta
end

return Export
