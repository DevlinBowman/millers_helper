-- system/app/surface/inspect.lua

return function(Surface)

    function Surface:inspect()
        return {
            context   = self.state:context_table(),
            resources = self.state:resources_table(),
            results   = self.state.results,
        }
    end

end
