local Query   = require("core.ledger.boundary.query") -- still shimmed
local Inspect = require("core.ledger.view.inspect")

return {
  query   = Query,
  inspect = Inspect,
}
