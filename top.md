```lua

state = {
f    sources = { 
        path as order only or "",
        path as boards only or "",
        path as orders+boards or "",
        path as vendor or "",
        path as ledger or "",
        path as ... or ""
    },
    data = {
        user = {
            batches = Load(user source(s)) or nil
        },
        vendor = {
            batches = Load(vendor source(s)) or nil
        },
        ledger = {
            Load(ledger source) or nil
        },
    },
    runtime = {
        session = init(session) from bootsteap or last session
        presets = { domain = init(domain_preset) ... } or nil
        },
    }

}

```

run = build(state)
ctx = whatever the caller needs
domain.thing(ctx)

and so on


data/
  app/
    default/
      ledgers/
        default/
          ledger.json
          exports_log.json
          txn/
      sessions/
        last_session.json
      system/
        runtime_ids/
        presets/default/
        caches/vendor/
      exports/
      clients/


desired application runtime hierarchy

app
    state
        resources
            user
            system

    runtime

    service
        system load and assign methods
        domain methods

```lua
AppRuntime = {
    context = {},

    resource_specs = {
        ["user.order"]     = { inputs = {...}, opts = {...} },
        ["user.vendors"]   = { inputs = {...}, opts = {...} },
        ["system.vendors"] = { inputs = {...}, opts = {...} },
    },

    runtime = {
        ["user.order"]     = RuntimeObject,
        ["user.vendors"]   = RuntimeObject,
    },

    results = {
        compare = {...},
        invoice = {...},
        quote   = {...},
    }
}
```

```lua
AppRuntime = {

    context = {},        -- session KV (active ledger, etc.)

    resources = {
        system = {
            vendors = {
                paths = {
                    "/app/data/app/default/system/caches/vendor/a.csv",
                    "/app/data/app/default/system/caches/vendor/b.csv",
                },
                category = "board",
            },

            ledgers = {
                path = "/app/data/app/default/ledgers",
            },
        },

        user = {
            order = {
                path = "/Users/ven/Desktop/order.txt",
                category = "order",
            },

            vendors = {
                paths = {
                    "/Users/ven/Desktop/vendor_override.csv"
                },
                category = "board",
            }
        }
    },

    runtime = {
        ["system.vendors"] = RuntimeObject,
        ["user.order"]     = RuntimeObject,
    },

    results = {
        compare = {...},
        invoice = {...},
    }
}
```

```lua
app = AppRuntime:

app:fs()
    ::ensure_instance_layout()
    ::inspect()

    ::vendor_store()
    ::ledger_store()
    ::

```
