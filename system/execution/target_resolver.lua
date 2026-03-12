-- system/execution/target_resolver.lua

local Resolver = {}

local function require_batch(envelope,label)
    assert(type(envelope)=="table","[execution] "..label.." envelope required")
    assert(type(envelope.batch)=="function","[execution] "..label.." envelope missing batch()")
    local batch = envelope:batch()
    assert(type(batch)=="table","[execution] "..label.." batch required")
    return batch
end

local function wrap_batch(envelope,batch_selector,label)
    if batch_selector==nil then return envelope end
    assert(type(batch_selector)=="number","[execution] "..label.." batch selector must be numeric")

    local batches = envelope.__batches
    assert(type(batches)=="table","[execution] "..label.." envelope has no __batches")

    local selected=batches[batch_selector]
    assert(type(selected)=="table","[execution] invalid "..label.." batch selector: "..tostring(batch_selector))

    return setmetatable({},{
        __index=function(_,k)
            if k=="batch" then return function() return selected end end
            return envelope[k]
        end
    })
end

function Resolver.resolve_job(runtime, resource_selector, batch_selector)
    local base = runtime:require("user","job",resource_selector)
    local env  = wrap_batch(base,batch_selector,"job")
    local batch=require_batch(env,"job")
    return env,batch
end

function Resolver.resolve_vendors(runtime,selector)
    if selector~=nil then
        local env = runtime:require("system","vendor",selector)
        local batch=require_batch(env,"vendor")
        return env,{batch}
    end
    local batches=runtime:batches("system","vendor")
    assert(type(batches)=="table","[execution] vendor batches required")
    return nil,batches
end

return Resolver
