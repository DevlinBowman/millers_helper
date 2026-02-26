SYSTEM LAYER SPECIFICATION

1. Purpose of the System Layer

The system/ layer provides:
•	Application runtime context
•	Canonical storage schema
•	Persistence adapters
•	Service orchestration
•	State container management

It is responsible for turning domain logic into a usable backend application.

It is NOT responsible for business rules.




2. Layering Rules (Hard Constraints)

Rule 1 — Domain Is Pure

core/domain/*:
•	Must not reference "data/"
•	Must not call io.open
•	Must not call os.execute
•	Must not require platform.io
•	Must not know storage layout

Domain operates on in-memory data only.


Rule 2 — Infrastructure Owns Disk

system/infrastructure/*:
•	Owns all filesystem layout
•	Owns canonical path resolution (via storage/controller.lua)
•	Owns persistence adapters (ledger, txn, attachments, id store)
•	May call FileGateway
•	May call platform.io

Infrastructure never contains business logic.

Rule 3 — Services Orchestrate

system/services/*:
•	Accept (context, request)
•	Use state from context
•	Call domain logic
•	Persist via infrastructure
•	Return structured results
•	Must not construct paths manually
•	Must not use "data/"

Services never call platform.io directly.

Rule 4 — Storage Schema Is Canonical

Only this file may reference "data/":

```
system/infrastructure/storage/controller.lua
```

This file defines:
•	ledger roots
•	transaction directories
•	export paths
•	session paths
•	cache paths
•	preset paths

All other modules resolve paths through it.


3. Runtime Context Contract

system/app/runtime_context.lua represents the active system instance.

A runtime instance must expose:

```lua
ctx:get_state()
ctx:get_storage()
ctx:get_gateway()
ctx.ledger_id
    ctx:load_source(path)
ctx:set_active_ledger(id)
```

Services must rely on the context, not global modules.

4. State Container Rules

system/app/state.lua holds:
•	context
•	loadables
•	results

It does NOT:
•	Know filesystem
•	Know services
•	Know domain logic

State is in-memory runtime memory only.

5. Storage Schema

Canonical layout:
```
data/
├── ledgers/
│   └── {ledger_id}/
│       ├── ledger.json
│       ├── txn/
│       │   └── {txn_id}/
│       │       ├── entry.json
│       │       ├── order.json
│       │       ├── boards.json
│       │       └── attachments/
│       └── exports_log.json
│
├── clients/
│   └── {client_id}.json
│
├── exports/
│   ├── quotes/
│   ├── invoices/
│   └── compare/
│
├── system/
│   ├── presets/
│   ├── caches/
│   │   └── vendor/
│   └── runtime_ids/
│
└── sessions/
└── last_session.json
```
All services must conform to this structure.


6. Service Contract

Each service must:

Accept:
```lua
Service.handle({
    state = state,
    opts  = {...}
})
```

Return:
```lua
{
    ok = boolean,
    error = string|nil,
    model|result = table|nil
}
```

Behavior Requirements:
	•	Must not crash on recoverable errors
	•	Must not mutate global modules
	•	Must update state.results
	•	Must use storage schema for exports
	•	Must write meta file for every export


7. Export Rules

Every export must:
	1.	Write the document
	2.	Write a .meta.json alongside it
	3.	Optionally register in ledger export log

Never reconstruct metadata from document text.


8. Ledger Rules

Ledger registry (ledger.json) stores summary rows only:

```json
{
  "transaction_id": "...",
  "date": "...",
  "type": "...",
  "order_id": "...",
  "customer_id": "...",
  "value": 123,
  "total_bf": 45.67
}
```
Full transaction data lives under:
```
txn/{txn_id}/
```

9. ID Store Rules
	•	ID counters stored under data/system/runtime_ids
	•	Never hardcoded paths
	•	Always use Storage.runtime_ids()


10. Vendor Cache Rules

Vendor caches must live under:
```
data/system/caches/vendor/
```

CompareService may default to loading from this directory.


11. Session Rules

Session snapshot:
```
data/sessions/last_session.json
```

Contains:
	•	active_ledger
	•	last loadables
	•	last context

System boot should auto-load this.


12. Forbidden Patterns

The following are illegal outside infrastructure:
```lua
"io.open"
"os.execute"
"data/"
"mkdir -p"
```

If found in domain or services, refactor required.


13. Dependency Graph

Final dependency direction:
```
platform → infrastructure → services → runtime_context → app entry
                 ↑
              domain
```

Domain must never depend upward.

14. What the System “Wants to See”

At minimum, a valid runtime instance must have:
	•	active ledger id
	•	storage controller mounted
	•	file gateway available
	•	state container initialized

Services assume:
	•	state.resources contains required inputs
	•	storage schema is valid
	•	ledger_id exists or can be created

