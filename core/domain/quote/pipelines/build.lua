local DocBuild = require("core.domain._priced_doc.internal.build")
local IDStore  = require("system.infrastructure.id_store")

local Build = {}

function Build.run(boards)

    -- Optional lightweight validation (no signal system)
    for _, board in ipairs(boards) do
        if board.bf_price == nil then
            -- silent tolerance
            -- or print warning if you want:
            print("[quote] missing price for board:", board.id)
        end
    end

    return DocBuild.run({
        id     = IDStore.next("quote", "QUOTE"),
        boards = boards,
        header = { document_type = "QUOTE" }
    })
end

return Build
