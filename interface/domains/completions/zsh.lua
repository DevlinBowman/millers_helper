local M = {}

M.help = {
    summary = "Print zsh completion script",
    usage   = "completions zsh",
}

function M.run(ctx, controller)
    return controller:zsh()
end

return M
