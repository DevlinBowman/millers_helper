local M = {}

M.help = {
    summary = "Load via runtime loader and commit to ledger",
    usage   = "runtime ledger <file> [--force]",
    options = {
        { "-f, --force", "Force re-ingest" },
    },
}

function M.run(ctx, controller)
    return controller:ledger(ctx)
end

return M
