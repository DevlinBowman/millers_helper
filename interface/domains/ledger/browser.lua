local Format = require("interface.domains.ledger.format")

local M = {}

------------------------------------------------------------
-- Terminal Helpers
------------------------------------------------------------

local function term_raw_on()
    os.execute("stty -echo -icanon min 1 time 0")
end

local function term_raw_off()
    os.execute("stty echo icanon")
end

local function clear()
    io.write("\27[2J\27[H")
end

------------------------------------------------------------
-- Browser Entry
------------------------------------------------------------

function M.run(controller, path, all_txns)

    if not all_txns or #all_txns == 0 then
        print("ledger empty")
        return
    end

    local filtered = all_txns
    local selected = 1
    local filter_query = ""

    ------------------------------------------------------------
    -- Filtering
    ------------------------------------------------------------

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
                table.insert(filtered, t)
            end
        end
    end

    ------------------------------------------------------------
    -- Render
    ------------------------------------------------------------

    local function render()

        clear()

        print("=== LEDGER BROWSER ===")
        print("↑/↓ j/k move | Enter open | / filter | c clear | q quit")
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

    ------------------------------------------------------------
    -- Raw Mode Loop
    ------------------------------------------------------------

term_raw_on()

local function cleanup()
    term_raw_off()
    io.write("\27[2J\27[H")
end

local ok, err = pcall(function()

        while true do

            render()
            local ch = io.read(1)

            if ch == "q" then
                term_raw_off()
                require("interface.quit").now()
            end

            if ch == "j" then
                selected = math.min(#filtered, selected + 1)

            elseif ch == "k" then
                selected = math.max(1, selected - 1)

            elseif ch == "/" then
                term_raw_off()
                io.write("\nfilter> ")
                local input = io.read()
                term_raw_on()

                filter_query = input or ""
                apply_filter(filter_query)
                selected = 1

            elseif ch == "c" then
                filter_query = ""
                apply_filter("")
                selected = 1

            elseif ch == "\27" then
                io.read(1)
                local dir = io.read(1)

                if dir == "A" then
                    selected = math.max(1, selected - 1)
                elseif dir == "B" then
                    selected = math.min(#filtered, selected + 1)
                end

            elseif ch == "\r" or ch == "\n" then
                if filtered[selected] then
                    cleanup()
                    controller:open({
                        positionals = { filtered[selected].transaction_id },
                        flags = { ledger = path }
                    })
                    io.write("\npress any key...")
                    term_raw_on()
                    io.read(1)
                end
            end
        end
    end)

    term_raw_off()
    clear()

    if not ok then error(err, 0) end
end

return M
