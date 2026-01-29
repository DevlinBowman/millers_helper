-- file_handler/readers/json.lua
local Json = {}

local function error_at(pos, msg)
    error(string.format("JSON error at %d: %s", pos, msg), 2)
end

local function parse(src)
    local pos = 1

    local function ws()
        while src:sub(pos,pos):match("[%s]") do pos = pos + 1 end
    end

    local function str()
        pos = pos + 1
        local out = {}
        while true do
            local c = src:sub(pos,pos)
            if c == "" then error_at(pos,"unterminated string") end
            if c == '"' then pos = pos + 1; return table.concat(out) end
            if c == "\\" then
                local esc = src:sub(pos+1,pos+1)
                local map = {
                    ['"']='"', ['\\']='\\', ['/']='/',
                    ['b']='\b', ['f']='\f',
                    ['n']='\n', ['r']='\r', ['t']='\t',
                }
                if not map[esc] then error_at(pos,"bad escape") end
                out[#out+1] = map[esc]
                pos = pos + 2
            else
                out[#out+1] = c
                pos = pos + 1
            end
        end
    end

    local function num()
        local s = pos
        while src:sub(pos,pos):match("[%d%+%-%eE%.]") do pos = pos + 1 end
        local n = tonumber(src:sub(s,pos-1))
        if not n then error_at(s,"invalid number") end
        return n
    end

    local val

    local function arr()
        pos = pos + 1
        local t = {}
        ws()
        if src:sub(pos,pos) == "]" then pos = pos + 1; return t end
        while true do
            t[#t+1] = val()
            ws()
            local c = src:sub(pos,pos)
            if c == "]" then pos = pos + 1; return t end
            if c ~= "," then error_at(pos,"expected ','") end
            pos = pos + 1
            ws()
        end
    end

    local function obj()
        pos = pos + 1
        local t = {}
        ws()
        if src:sub(pos,pos) == "}" then pos = pos + 1; return t end
        while true do
            if src:sub(pos,pos) ~= '"' then error_at(pos,"key must be string") end
            local k = str()
            ws()
            if src:sub(pos,pos) ~= ":" then error_at(pos,"expected ':'") end
            pos = pos + 1
            ws()
            t[k] = val()
            ws()
            local c = src:sub(pos,pos)
            if c == "}" then pos = pos + 1; return t end
            if c ~= "," then error_at(pos,"expected ','") end
            pos = pos + 1
            ws()
        end
    end

    function val()
        ws()
        local c = src:sub(pos,pos)
        if c == '"' then return str() end
        if c == "{" then return obj() end
        if c == "[" then return arr() end
        if c:match("[%d%-]") then return num() end
        if src:sub(pos,pos+3) == "true" then pos = pos + 4; return true end
        if src:sub(pos,pos+4) == "false" then pos = pos + 5; return false end
        if src:sub(pos,pos+3) == "null" then pos = pos + 4; return nil end
        error_at(pos,"unexpected token")
    end

    local r = val()
    ws()
    if pos <= #src then error_at(pos,"trailing data") end
    return r
end

function Json.read(path)
    local fh, err = io.open(path,"r")
    if not fh then return nil, err end
    local src = fh:read("*a")
    fh:close()

    local ok, value = pcall(parse, src)
    if not ok then return nil, value end

    return {
        kind = "json",
        data = value,
    }
end

return Json
