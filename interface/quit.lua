-- interface/quit.lua
local M = {}

function M.now(code)
    io.write("\n")
    os.exit(code or 0)
end

return M
