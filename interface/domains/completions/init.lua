local Registry   = require("interface.registry")
local Controller = require("interface.domains.completions.controller")

Registry.register_domain("completions", {
    controller = Controller,
})

Registry.register("completions", "zsh",
    require("interface.domains.completions.zsh"))

Registry.register("completions", "install-zsh",
    require("interface.domains.completions.install_zsh"))
