-- interface/shells/cli/parser.lua

local Parser = {}

local function set_flag(flags, key, value)
    flags[key] = value
end

function Parser.parse(argv)
    local domain = argv[1]
    local action = argv[2]

    local positionals = {}
    local flags = {}

    local i = 3
    while i <= #argv do
        local arg = argv[i]

        if arg == "--list" then
            set_flag(flags, "list", true)

        elseif arg == "--vendor-list" then
            set_flag(flags, "vendor_list", true)

        elseif arg == "--nevermind" then
            set_flag(flags, "nevermind", true)

        elseif arg == "--index" then
            set_flag(flags, "index", argv[i + 1])
            i = i + 1

        elseif arg == "--vendor-index" then
            set_flag(flags, "vendor_index", argv[i + 1])
            i = i + 1

        elseif arg == "--vendor-name" then
            set_flag(flags, "vendor_name", argv[i + 1])
            i = i + 1

        else
            positionals[#positionals + 1] = arg
        end

        i = i + 1
    end

    return {
        domain      = domain,
        action      = action,
        positionals = positionals,
        flags       = flags,
        raw         = argv,
    }
end

return Parser
