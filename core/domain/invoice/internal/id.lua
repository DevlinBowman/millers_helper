local IDStore = require("core.domain._priced_doc.internal.id_store")

local ID = {}

function ID.new()
    return IDStore.next("invoice", "INV")
end

return ID
