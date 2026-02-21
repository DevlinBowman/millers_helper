-- interface/tui/term.lua
--
-- Global terminal rules:
--  - raw mode is always bracketed
--  - cleanup guaranteed on exit/error/suspend
--  - Ctrl+Z restores terminal before stopping process

local Quit = require("interface.quit")

local Term = {}

function Term.clear()
    io.write("\27[2J\27[H")
end

function Term.raw_on()
    os.execute("stty -echo -icanon min 1 time 0")
end

function Term.raw_off()
    os.execute("stty echo icanon")
end

function Term.cleanup()
    Term.raw_off()
    Term.clear()
end

-- attempt to suspend current process safely (best-effort)
local function suspend_self()
    -- restore terminal first
    Term.raw_off()

    -- Send TSTP to the current process id via /bin/sh without subshell pid confusion:
    -- We rely on 'kill -TSTP 0' meaning "process group" in many shells.
    -- This is best-effort; if it fails, user still gets terminal back.
    os.execute("kill -TSTP 0")

    -- on resume, re-enter raw if caller wants; caller will redraw
end

function Term.read_key()
    local ch = io.read(1)

    if ch == nil then
        return { kind = "none" }
    end

    -- Ctrl+C
    if ch == "\003" then
        return { kind = "quit" }
    end

    -- Ctrl+Z
    if ch == "\026" then
        return { kind = "suspend" }
    end

    if ch == "\27" then
        local n1 = io.read(1)
        local n2 = io.read(1)
        if n1 == "[" then
            if n2 == "A" then return { kind = "up" } end
            if n2 == "B" then return { kind = "down" } end
            if n2 == "C" then return { kind = "right" } end
            if n2 == "D" then return { kind = "left" } end
        end
        return { kind = "esc" }
    end

    if ch == "\r" or ch == "\n" then
        return { kind = "enter" }
    end

    return { kind = "char", ch = ch }
end

function Term.with_raw(fn)
    Term.raw_on()
    local ok, result_or_err = pcall(fn)
    Term.cleanup()
    if not ok then error(result_or_err, 0) end
    return result_or_err
end

function Term.handle_global_key(key)
    if key.kind == "quit" then
        Term.cleanup()
        Quit.now(0)
    end

    if key.kind == "suspend" then
        suspend_self()
        return true
    end

    return false
end

return Term
