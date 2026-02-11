-- interface/domains/completions/controller.lua

local Controller = {}
Controller.__index = Controller

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

function Controller.new()
    return setmetatable({}, Controller)
end

----------------------------------------------------------------
-- Zsh script generator
----------------------------------------------------------------

local function build_zsh_script()
    return table.concat({
        "#compdef bd",
        "",
        "_bd_complete() {",
        "  local state",
        "",
        "  _arguments -C \\",
        "    '1:domain:->domain' \\",
        "    '2:action:->action' \\",
        "    '*::arg:->args'",
        "",
        "  case $state in",
        "",
        "    domain)",
        "      compadd -- ${(@f)$(bd __complete \"${words[CURRENT]}\")}",
        "      ;;",
        "",
        "    action)",
        "      compadd -- ${(@f)$(bd __complete ${words[2]} \"${words[CURRENT]}\")}",
        "      ;;",
        "",
        "    args)",
        "      local -a completions",
        "",
        "      completions=(\"${(@f)$(bd __complete ${words[2]} ${words[3]} ${words[@]:4} \"${words[CURRENT]}\")}\")",
        "",
        "      if (( ${#completions[@]} > 0 )); then",
        "        compadd -Q -- $completions",
        "      else",
        "        _files",
        "      fi",
        "      ;;",
        "  esac",
        "}",
        "",
        "compdef _bd_complete bd",
        "",
    }, "\n")
end

----------------------------------------------------------------
-- Print script
----------------------------------------------------------------

function Controller:zsh()
    io.stdout:write(build_zsh_script())
end

----------------------------------------------------------------
-- Install script
----------------------------------------------------------------

function Controller:install_zsh()
    local home = os.getenv("HOME")
    if not home then
        error("HOME not set")
    end

    local zdot = os.getenv("ZDOTDIR") or home
    local dir  = zdot .. "/completions"

    assert(os.execute(string.format("mkdir -p %q", dir)))

    local path = dir .. "/_bd"
    local tmp  = path .. ".tmp"

    local file = assert(io.open(tmp, "w"))
    file:write(build_zsh_script())
    file:close()

    assert(os.rename(tmp, path))

    print("Installed zsh completion to " .. path)
    print("Restart your shell or run: compinit")
end

return Controller
