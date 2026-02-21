local FS = require("platform.io.registry").fs

local Attachments = {}

local ROOT = "data/transactions"

local function copy_file(src, dest)
    local fh_in  = assert(io.open(src, "rb"))
    local fh_out = assert(io.open(dest, "wb"))
    fh_out:write(fh_in:read("*a"))
    fh_in:close()
    fh_out:close()
end

function Attachments.add(transaction_id, source_path)
    assert(type(transaction_id) == "string", "transaction_id required")
    assert(type(source_path) == "string", "source_path required")

    local filename = FS.get_filename(source_path)
    assert(filename, "invalid attachment path")

    local dest =
        ROOT .. "/" .. transaction_id .. "/attachments/" .. filename

    FS.ensure_parent_dir(dest)
    copy_file(source_path, dest)

    return dest
end

return Attachments
