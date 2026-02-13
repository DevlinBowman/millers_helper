-- format/system/converter.lua
--
-- Conversion engine.
-- Pure transform orchestration.
-- No tracing.
-- No contracts.
-- No boundary logic.

local Registry = require("format.registry")
local Clean    = Registry.normalize.clean
local Shape    = Registry.validate.shape

local Converter = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function parse_edge(transform_key)
    return transform_key:match("^(.-)_to_(.+)$")
end

local function build_graph(transforms)
    local adjacency = {}
    local codecs = {}

    for key in pairs(transforms or {}) do
        local from_codec, to_codec = parse_edge(key)
        if from_codec and to_codec then
            adjacency[from_codec] = adjacency[from_codec] or {}
            adjacency[from_codec][to_codec] = key
            codecs[from_codec] = true
            codecs[to_codec] = true
        end
    end

    return adjacency, codecs
end

local function find_path(adjacency, from_codec, to_codec)
    local queue = { from_codec }
    local qh = 1

    local visited = { [from_codec] = true }
    local prev_codec = {}
    local prev_edge = {}

    while qh <= #queue do
        local cur = queue[qh]
        qh = qh + 1

        if cur == to_codec then break end

        local neighbors = adjacency[cur]
        if neighbors then
            for next_codec, edge_key in pairs(neighbors) do
                if not visited[next_codec] then
                    visited[next_codec] = true
                    prev_codec[next_codec] = cur
                    prev_edge[next_codec] = edge_key
                    queue[#queue + 1] = next_codec
                end
            end
        end
    end

    if not visited[to_codec] then
        return nil
    end

    local edges = {}
    local cur = to_codec

    while cur ~= from_codec do
        local edge = prev_edge[cur]
        if not edge then return nil end
        edges[#edges + 1] = edge
        cur = prev_codec[cur]
    end

    for i = 1, math.floor(#edges / 2) do
        edges[i], edges[#edges - i + 1] = edges[#edges - i + 1], edges[i]
    end

    return edges
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

---@param payload { codec:string, data:any }
---@param target_codec string
---@return { codec:string, data:any }|nil
---@return string|nil err
function Converter.run(payload, target_codec)

    if payload.codec == target_codec then
        return payload
    end

    -- validate input shape
    if Shape[payload.codec] and not Shape[payload.codec](payload.data) then
        return nil, "invalid data shape for codec '" .. payload.codec .. "'"
    end

    local adjacency, codecs = build_graph(Registry.transforms)

    if not adjacency[payload.codec] then
        return nil, "no transforms registered from codec '" .. payload.codec .. "'"
    end

    local edges = find_path(adjacency, payload.codec, target_codec)

    if not edges or #edges == 0 then
        return nil, "unsupported transform: " .. payload.codec .. "_to_" .. target_codec
    end

    -- do not mutate original payload
    local cur_data = Clean.apply(payload.codec, payload.data)

    for _, edge_key in ipairs(edges) do
        local transform = Registry.transforms[edge_key]
        if type(transform) ~= "table" or type(transform.run) ~= "function" then
            return nil, "invalid transform module: " .. edge_key
        end

        local result, err = transform.run(cur_data)
        if not result then
            return nil, err
        end

        cur_data = result
    end

    -- validate output shape
    if Shape[target_codec] and not Shape[target_codec](cur_data) then
        return nil, "transform chain produced invalid '" .. target_codec .. "' shape"
    end

    return {
        codec = target_codec,
        data  = cur_data,
    }
end

return Converter
