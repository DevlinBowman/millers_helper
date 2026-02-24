-- platform/selector/controller.lua
--
-- Boundary layer for structural selection.

local Pipeline   = require("platform.selector.pipelines.resolve")
local Contract   = require("core.contract")
local Trace      = require("tools.trace.trace")
local Diagnostic = require("tools.diagnostic")

local Controller = {}

Controller.CONTRACT = {
    get = {
        in_ = {
            root   = true,
            tokens = true,
        },
        out = {
            value = false,
        },
    },

    exists = {
        in_ = {
            root   = true,
            tokens = true,
        },
        out = {
            exists = true,
        },
    },
}

----------------------------------------------------------------
-- GET (RELAXED)
----------------------------------------------------------------

function Controller.get(root, tokens, ...)
    Trace.contract_enter("selector.get")
    Trace.contract_in({ root = root, tokens = tokens })

    Contract.assert(
        { root = root, tokens = tokens },
        Controller.CONTRACT.get.in_
    )

    Diagnostic.scope_enter("selector.get")

    local value, failure = Pipeline.get(root, tokens, ...)

    local result

    if value == nil then
        result = {
            ok    = false,
            value = nil,
            error = failure,
        }
    else
        result = {
            ok    = true,
            value = value,
            error = nil,
        }
    end

    Trace.contract_out(result, "selector.get", "caller")

    Diagnostic.scope_leave()
    Trace.contract_leave()

    return result
end

----------------------------------------------------------------
-- GET STRICT
----------------------------------------------------------------

function Controller.get_strict(root, tokens, ...)
    local result = Controller.get(root, tokens, ...)
    if not result.ok then
        error(result.error, 2)
    end
    return result.value
end

----------------------------------------------------------------
-- EXISTS
----------------------------------------------------------------

function Controller.exists(root, tokens, ...)
    Trace.contract_enter("selector.exists")
    Trace.contract_in({ root = root, tokens = tokens })

    Contract.assert(
        { root = root, tokens = tokens },
        Controller.CONTRACT.exists.in_
    )

    Diagnostic.scope_enter("selector.exists")

    local ok, err = Pipeline.exists(root, tokens, ...)

    if not ok and err then
        Diagnostic.user_message(err, "error")
    end

    Trace.contract_out({ exists = ok }, "selector.exists", "caller")

    Diagnostic.scope_leave()
    Trace.contract_leave()

    return ok, err
end

----------------------------------------------------------------
-- EXISTS STRICT
----------------------------------------------------------------

function Controller.exists_strict(root, tokens)
    local ok = Controller.exists(root, tokens)
    if not ok then
        error("selector path does not exist", 2)
    end
    return true
end

function Controller.format_error(failure, opts)
    return require("platform.selector.registry")
        .format_error.run(failure, opts)
end

return Controller
