local Selectors = {}

function Selectors.job(service, opts, slots)

    if opts.job_batch_selector then
        return opts.job_batch_selector
    end

    local service_slot =
        slots:get_selection("user", "job:" .. service)

    if service_slot then
        return service_slot
    end

    return slots:get_selection("user", "job")
end


function Selectors.vendor(service, opts, slots)

    if opts.vendor_selector then
        return opts.vendor_selector
    end

    local service_slot =
        slots:get_selection("system", "vendor:" .. service)

    if service_slot then
        return service_slot
    end

    if service == "compare" then
        return nil
    end

    return slots:get_selection("system", "vendor")
end

return Selectors
