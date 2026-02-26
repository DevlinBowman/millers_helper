local DocBuild = require("core.domain._priced_doc.build")
local Document = require("core.domain._priced_doc.document")

local Build = {}

function Build.run(args)
    assert(type(args) == "table", "quote.build requires args table")
    assert(type(args.boards) == "table", "quote.build requires boards")

    local dto = DocBuild.run({
        id     = args.id,
        boards = args.boards,
        header = { document_type = "QUOTE" }
    })

    return Document.new(dto)
end

return Build
