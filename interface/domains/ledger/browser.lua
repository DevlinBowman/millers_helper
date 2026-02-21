-- interface/domains/ledger/browser.lua
--
-- Browser view. NO direct stty here. Uses Term policy from TUI.

local Format = require("interface.domains.ledger.format")

local M = {}

function M.run(env, path, all_txns)
    local Term = env.term

    if not all_txns or #all_txns == 0 then
        print("ledger empty")
        return
    end

    local filtered = all_txns
    local selected = 1
    local filter_query = ""

    local function apply_filter(query)
        if not query or query == "" then
            filtered = all_txns
            return
        end

        query = query:lower()
        filtered = {}

        for _, t in ipairs(all_txns) do
            local id   = tostring(t.transaction_id or ""):lower()
            local type = tostring(t.type or ""):lower()
            local date = tostring(t.date or ""):lower()

            if id:find(query, 1, true)
            or type:find(query, 1, true)
            or date:find(query, 1, true)
            then
                filtered[#filtered + 1] = t
            end
        end
    end

    local function render()
        Term.clear()
        print("=== LEDGER BROWSER ===")
        print("↑/↓ j/k move | Enter open | / filter | c clear | q quit | Ctrl+Z suspend")
        print("filter:", filter_query)
        print("")

        for i, t in ipairs(filtered) do
            local cursor = (i == selected) and ">" or " "
            print(string.format(
                "%s%03d | %-13s | %-10s | %-8s | %s",
                cursor,
                i,
                tostring(t.transaction_id),
                tostring(t.date),
                tostring(t.type),
                Format.money(t.value)
            ))
        end

        print("")
        print("shown:", #filtered, "of", #all_txns)
    end

    return Term.with_raw(function()
        while true do
            render()
            local key = Term.read_key()

            if Term.handle_global_key(key) then
                -- suspend handled; redraw on resume
            end

            if key.kind == "char" then
                local ch = key.ch

                if ch == "q" then
                    Term.cleanup()
                    require("interface.quit").now()
                elseif ch == "j" then
                    selected = math.min(#filtered, selected + 1)
                elseif ch == "k" then
                    selected = math.max(1, selected - 1)
                elseif ch == "c" then
                    filter_query = ""
                    apply_filter("")
                    selected = 1
                elseif ch == "/" then
                    Term.raw_off()
                    io.write("\nfilter> ")
                    local input = io.read()
                    Term.raw_on()
                    filter_query = input or ""
                    apply_filter(filter_query)
                    selected = 1
                end

            elseif key.kind == "up" then
                selected = math.max(1, selected - 1)
            elseif key.kind == "down" then
                selected = math.min(#filtered, selected + 1)
            elseif key.kind == "enter" then
                local row = filtered[selected]
                if row then
                    Term.cleanup()
                    env.open(row.transaction_id)
                    io.write("\npress any key...")
                    Term.raw_on()
                    io.read(1)
                end
            end
        end
    end)
end

return M
