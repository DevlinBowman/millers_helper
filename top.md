```lua

state = {
    sources = { 
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
# entry point

## backend.lua
./system/backend.lua is the canonical application entry point. it is responsible for all runtime startup.
it is responsible for;
- fs initialization
    - state initialization
    - 

run with;

```lua
app = Backend.run(<instance>)
```

# application runtime


# fs()
## core methods
```aside from the canonical 'store' access functions, fs() supplies dev introspection under util()```
-- fs()
--
-- Filesystem capability root.
-- Provides:
--   • store() → canonical, domain-significant locations (AppFSResult)
--   • util()  → lifecycle + introspection helpers (tables / structured metadata)

fs()

-- namespaced roots
fs():store()  -- canonical locations you “play with” (paths + traversal)
fs():util()   -- dev/lifecycle helpers (ensure, inspect, schema, graph)

----------------------------------------------------------------
-- util() methods (dev + lifecycle)
----------------------------------------------------------------

fs():util():ensure_app_dirs()      -- ensures the instance layout exists (creates missing dirs)
fs():util():inspect_schema()       -- returns Registry.locations (logical map, no IO)
fs():util():inspect_graph()        -- returns resolved existence/kind per location (IO ok)
fs():util():app_root()             -- returns Storage.app_root() (string)
fs():util():fs_root()              -- returns project data/app root (string) if you expose it

----------------------------------------------------------------
-- store() methods (canonical stores → AppFSResult)
-- These return AppFSResult so you can do :files(), :dirs(), :entries(), :inspect(), :path()
----------------------------------------------------------------

-- primary domain stores
fs():store():ledger()              -- ./data/app/<session>/ledger/
fs():store():clients()             -- ./data/app/<session>/clients/
fs():store():vendor()              -- ./data/app/<session>/vendor/ (or system/caches/vendor if that’s canonical)

-- user stores (persisted, user-facing)
fs():store():user()                -- ./data/app/<session>/user/
fs():store():user():imports()      -- ./data/app/<session>/user/imports/
fs():store():user():exports()      -- ./data/app/<session>/user/exports/
fs():store():user():vault()        -- optional: ./data/app/<session>/user/vault/ (curated persisted inputs)

-- system stores (system-owned)
fs():store():system()              -- ./data/app/<session>/system/
fs():store():system():sessions()   -- ./data/app/<session>/system/sessions/
fs():store():system():runtime_ids()-- ./data/app/<session>/system/runtime_ids/
fs():store():system():presets()    -- ./data/app/<session>/system/presets/

-- ephemeral staging (system-owned, runtime-only)
fs():store():staged()              -- ./data/app/<session>/system/staged/ (or system/staging/)
fs():store():staged():imports()    -- optional: ./data/app/<session>/system/staged/imports/

----------------------------------------------------------------
-- presets (domain-scoped under system/presets)
----------------------------------------------------------------

fs():store():system():presets()                -- preset root
fs():store():system():presets():domain(name)   -- ./system/presets/<domain>/ (returns AppFSResult)

-- example usage:
-- fs():store():system():presets():domain("ledger"):files()


## fs root


``` everything in the aff fs lives here```
./data/app/ << @ app:fs_root()

## stores
file strores live behind the fs().store namespace


## ledger domain
```everything relative to a given ledger lives here```
./data/app/<session>/ledger/ << @ :store():ledger()

```individual ledger files serve as a transaction index, and themselves contain references to 'txn' files```
[files:: <filename>.ledger.lua] << @ store():ledger():files()

```these dirs contain dirs only per txn and are handled by the ledger domain```
./data/app/<session>/ledger/txn/

```these dirs exist as 1 per txn and contain the actual records that the ledger points too ```
```files are created by the ledger domain```
./data/app/<session>/ledger/txn/data/

```thses files store the actual 'job' data for a given 'txn'```
[files:: [<id>_job|order|boards|alloc|other].lua]

```these dirs exist as 1 per txn and contain the associated records that the ledger points too ```
```files are created by the ledger domain```
./data/app/<session>/ledger/txn/attachemnts/

```these files contain attachments associeted with a given 'txn'. usually related to 'exports'```
[files:: [quote|invoice|compare|other].*] 


## client domain [still pre-dev]
```similar to the ledger, the top level 'client_store' maintains a source or truth index```
./data/app/<session>/client/ << @ fs:store():client()

```the data in this file points to individulal client files```
[files:: <filename>.client_index.lua] << @ fs:client_store:files()

```client data are stored as individual files and stored in info```
./data/app/<session>/client/info/

```the files that contain the actual client data```
[files:: <client_id>.lua]


## vendor domain
```the primary location for 'cached' vendor files```
./data/app/<session>/vendor/ << @ fs():store():vendor()

```vendor files are stored and read as human readable csv files```
[files:: <filename>.csv] << @ fs():store():vendor():files()

## user files

```location for imported and exported 'job' related files. no files here only dirs```
```this dir is the save point for stable downloaded or locally supplied files```
./data/app/<session>/user/ << @ fs:():store():user()

```location for files loaded into the system from outside of the app```
./data/app/<session>/user/imports/ << @ fs():store():user():imports()

```note: these files contain user supplied uploads to be loaded at runtime which have been designated to persist across runtimes```
[files :: <rawfilename>.*] << @ fs():store()user():imports():files()

```location of files exported from the system```
./data/app/<session>/user/exports/ << @ fs():store():user():exports()

```each exported file consists of the file istelf which represents the true export and a json metadata file that preserves record of its provenance```
[files :: <file_id>.* && file_id.meta.json] << @ fs():store():user():exports():files()

## system files

```the top level system dir contains all of the application background spec```
./data/app/<session>/system/ << @ fs():store():system()

### staging
```this is the location that user supplied files are store ephemerally for a runtime instance```
```if something had been uploaded, or a path has been supplied to a local file, that file can be stably stored here for runtime access```
./data/app/<session>/system/staged/ << @fs():store():staged()

### session snapshot persistance

```system sessions contains any stored instance state snapshot files```
./data/app/<session>/system/sessions/

```system session files are runtime stat snapshots containing all app:inputs() and app()resources and are used to persist preveous runtime states (not including loaded data()```
[files :: <session_id.json>] << @ fs():store():system():sessions():files()

### counters

```runtime_ids contains counter files for simple process specific enumeration```
./data/app/<session>/system/runtime_ids/ << @ fs():store():system():runtime_ids()

```simple action-wise counter files for cleanly separating individual actions from oneanother```
[files :: <target_type>.counter.json] <<@ fs():store():system():runtime_ids():files()

### config presets

```domain preset storage```
./data/app/<session>/system/presets/ << @ fs():store():system():presets()

```any number of domains may require a non trivial amount of additional data supplied to their context for proper use. Those data are stored here, (usually for user selection) on the basis of each domain```
./data/app/<session>/system/presets/<domain>/ << @ fs():store():presets()

```individual preset files should have a user supplied name for human readability```
[files :: <name>.preset.lua]  << @ fs():store():presets().domain('<domain>'):files()


## methods
```lua


fs()



```
# service()

# data()
data contains the runtime context required for use of services business logic

## input
the user may only supply valid input is a specifies number of cases, based on intent.
```lua

input = {
    path   = "...",
    role   = "job" | "order" | "boards" | "vendor" | "ledger" | "client"
    target = optional
}

```lua
state = {
    -- raw input data
    inputs = {
        { role = "", path = "", target = "" or nil}
        --...
    },
    -- descriptors only (pre-resolution)
    resources = {
        user = { 
            <inputs>, -- validated
            ...
            },
        system = {
            <defaults>, -- from app defaults
            vendor_store:files(),
            ledger_store.files(),
            client_store.files(),
            },
    },

    -- resolved data
    runtime = {
        user = {
            <job> -- from load
        },
        system = {
            <'vendor'> = { descriptor = ..., envelope = ...},
            <'ledger'> = { descriptor = ..., envelope = ...},
            <'client'> = { descriptor = ..., envelope = ...},
        },
    },
}
```





## system boundaries
```maintain for dev coherency```

app -> orchestration layer
fs() -> filesystem capability namespace (does not return raw topology, must return a wrapper)
service() -> business capability namespace
data() -> state data

###### slots


```lua
raw_input = {
  resources = {
    job = nil,       -- JobInput|nil
    vendor = nil,    -- VendorInput|nil
    client = nil,
    ledger = nil,
  },

  config = {
    overwrite_mode = nil,
    pricing_mode = nil,
    strict = false,
  },

  meta = {
    source = nil,
    submitted_at = nil,
  }
}

set_resource(type, payload)
get_resource(type)
set_config(key, value)
get_config(key)
clear_resource(type)
clear_all()
raw()
```

as job
job_file = 'path'
job_as_pair = 'path' as order, 'path' as boards

vendor

