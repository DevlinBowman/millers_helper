-- system/app/surface/resources.lua

return function(Surface)

    function Surface:set_resource(name, input, opts)
        local inputs = type(input) == "table" and input or { input }

        return self.state:set_resource(name, {
            inputs = inputs,
            opts   = opts or {}
        })
    end

    function Surface:get_resource(name)
        return self.state:get_resource(name)
    end

    function Surface:clear_resource(name)
        return self.state:clear_resource(name)
    end

end
