-- scripts/fix_pipeline_headers.lua
-- Updates the first comment line to match the file's real location

local lfs = require("lfs")

local ROOT = "system/pipeline"

------------------------------------------------------------

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local data = f:read("*a")
    f:close()
    return data
end

local function write_file(path, data)
    local f = io.open(path, "w")
    assert(f, "failed writing: "..path)
    f:write(data)
    f:close()
end

------------------------------------------------------------
-- rewrite first comment line
------------------------------------------------------------

local function rewrite_header(path)

    local text = read_file(path)
    if not text then return end

    local first, rest =
        text:match("^(%-%-.-\n)(.*)")

    if not first then
        return
    end

    local correct =
        "-- " .. path:gsub("\\","/") .. "\n"

    if first ~= correct then
        print("fix:", path)
        text = correct .. rest
        write_file(path, text)
    end
end

------------------------------------------------------------
-- walk directory
------------------------------------------------------------

local function walk(dir)

    for entry in lfs.dir(dir) do
        if entry ~= "." and entry ~= ".." then

            local path = dir .. "/" .. entry
            local attr = lfs.attributes(path)

            if attr.mode == "directory" then
                walk(path)

            elseif entry:match("%.lua$") then
                rewrite_header(path)
            end
        end
    end
end

------------------------------------------------------------

walk(ROOT)

print("\npipeline headers updated")
