function Compiler.compile(app, service, opts)

    local data     = app:data()
    local runtime  = data:runtime()
    local slots    = data:slots()
    local intent   = data:intent()

    ----------------------------------
    -- resolve selectors
    ----------------------------------

    local job_sel =
        slots:get_selection("user", "job:" .. service)
        or slots:get_selection("user", "job")

    local vendor_sel =
        slots:get_selection("system", "vendor:" .. service)
        or slots:get_selection("system", "vendor")

    ----------------------------------
    -- resolve job
    ----------------------------------

    local job_env =
        runtime:require("user","job", job_sel and job_sel.resource)

    local batches =
        job_env.__batches

    local batch_index =
        job_sel and job_sel.batch or 1

    local batch =
        batches[batch_index]

    ----------------------------------
    -- vendors
    ----------------------------------

    local vendor_batches

    if vendor_sel and vendor_sel.batch then

        local all =
            runtime:batches("system","vendor")

        vendor_batches = {
            all[vendor_sel.batch]
        }

    else

        vendor_batches =
            runtime:batches("system","vendor")

    end

    ----------------------------------
    -- build context
    ----------------------------------

    return {
        service = service,
        target  = batch,

        env = {
            job     = job_env,
            vendors = vendor_batches,
            intent  = intent:all(),
            opts    = opts
        }
    }
end
