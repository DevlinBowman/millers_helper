-- platform/io/query/controller.lua

local Pipeline  = require("platform.io.query.pipelines.inspect")
local Contract  = require("core.contract")
local Trace     = require("tools.trace.trace")
local Diagnostic = require("tools.diagnostic")

local Controller = {}

Controller.CONTRACT = {
    query = {
        in_ = {
            path = true,
        },
        out = {
            path   = true,
            exists = true,
            kind   = true,
            entries = false,
            files   = false,
            dirs    = false,
            size    = false,
            hash    = false,
        },
    }
}

function Controller.query(path)
    Trace.contract_enter("io.query")
    Trace.contract_in({ path = path })

    Contract.assert({ path = path }, Controller.CONTRACT.query.in_)

    Diagnostic.scope_enter("io.query")

    local result, err = Pipeline.run(path)

    if not result then
        Diagnostic.user_message(err or "query failed", "error")
        Diagnostic.scope_leave()
        Trace.contract_leave()
        return nil, err
    end

    Trace.contract_out(result, "io.query", "caller")
    Contract.assert(result, Controller.CONTRACT.query.out)

    Diagnostic.scope_leave()
    Trace.contract_leave()

    return result
end

function Controller.query_strict(path)
    local result, err = Controller.query(path)
    if not result then
        error(err, 2)
    end
    return result
end

return Controller
