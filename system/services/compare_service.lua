local RuntimeDomain = require("core.domain.runtime.controller")
local CompareDomain = require("core.domain.compare.controller")

local Storage       = require("system.infrastructure.storage.controller")
local FileGateway   = require("system.infrastructure.file_gateway")

local CompareService = {}

function CompareService.handle(req)

    local state = req.state
    if not state then
        return { ok = false, error = "missing state" }
    end

    ------------------------------------------------------------
    -- Resolve order path
    ------------------------------------------------------------

    local order_path =
        state.resources
        and state.resources.order_path

    if not order_path then
        return { ok = false, error = "missing resource: order_path" }
    end

    ------------------------------------------------------------
    -- Resolve vendor paths
    ------------------------------------------------------------

    local vendor_paths =
        state.resources
        and state.resources.vendor_paths

    -- Default to vendor cache if not explicitly set
    if not vendor_paths or #vendor_paths == 0 then

        local cache_root = Storage.vendor_cache_root()

        -- read cache directory listing via gateway
        local files, err = FileGateway.list(cache_root)

        if not files or #files == 0 then
            return {
                ok = false,
                error = "no vendor_paths and vendor cache empty"
            }
        end

        vendor_paths = {}
        for _, f in ipairs(files) do
            table.insert(vendor_paths, cache_root .. "/" .. f)
        end
    end

    ------------------------------------------------------------
    -- Load order runtime
    ------------------------------------------------------------

    local order_runtime = RuntimeDomain.load(order_path)
    local order_bundle  = order_runtime:batches()[1]

    if not order_bundle then
        return { ok = false, error = "no order batch available" }
    end

    ------------------------------------------------------------
    -- Load vendor runtimes
    ------------------------------------------------------------

    local sources = {}

    for _, vpath in ipairs(vendor_paths) do

        local v_runtime = RuntimeDomain.load(vpath)
        local v_bundle  = v_runtime:batches()[1]

        if v_bundle then
            table.insert(sources, {
                name   = vpath,
                boards = v_bundle.boards or {},
            })
        end
    end

    if #sources == 0 then
        return { ok = false, error = "no valid vendor sources loaded" }
    end

    ------------------------------------------------------------
    -- Compare
    ------------------------------------------------------------

    local result =
        CompareDomain.compare(order_bundle, sources, {})

    ------------------------------------------------------------
    -- Store result in state
    ------------------------------------------------------------

    state.results = state.results or {}
    state.results.compare = result

    ------------------------------------------------------------
    -- Optional export
    ------------------------------------------------------------

    if req.opts and req.opts.export == true then

        local compare_id =
            "COMPARE-" .. os.time()

        local doc_path =
            Storage.export_doc("compare", compare_id)

        local meta_path =
            Storage.export_meta("compare", compare_id)

        FileGateway.write(
            doc_path,
            "json",
            result
        )

        FileGateway.write(
            meta_path,
            "json",
            {
                compare_id  = compare_id,
                order_path  = order_path,
                vendor_paths = vendor_paths,
                generated_at = os.date("%Y-%m-%d %H:%M:%S"),
            }
        )
    end

    return { ok = true, result = result }
end

return CompareService
