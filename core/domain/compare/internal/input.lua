local Input = {}

----------------------------------------------------------------
-- Canonical Batch Adapter
----------------------------------------------------------------

--- user batch is one item, vendor_batches must be supplied as a table of individual batches
---@param user_batch table
---@param vendor_batches table[]
---@param opts table|nil
---@return table
function Input.from_batches(user_batch, vendor_batches, opts)
    assert(type(user_batch) == "table", "[compare] user_batch required")
    assert(type(user_batch.boards) == "table", "[compare] user_batch.boards required")

    assert(type(vendor_batches) == "table", "[compare] vendor_batches required")

    local sources = {}

    for i, vb in ipairs(vendor_batches) do
        assert(type(vb) == "table", "[compare] vendor batch must be table")
        assert(type(vb.boards) == "table", "[compare] vendor batch.boards required")

        local name =
            (vb.meta and vb.meta.io and vb.meta.io.source_path)
            or ("vendor_" .. i)

        sources[#sources + 1] = {
            name   = name,
            boards = vb.boards,
        }
    end

    return {
        order   = user_batch,
        sources = sources,
        opts    = opts or {},
    }
end

return Input
