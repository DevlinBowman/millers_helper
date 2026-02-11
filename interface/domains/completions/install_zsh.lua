local M = {}

M.help = {
    summary = "Install zsh completion automatically",
    usage   = "completions install-zsh",
}

function M.run(ctx, controller)
    return controller:install_zsh()
end

return M
