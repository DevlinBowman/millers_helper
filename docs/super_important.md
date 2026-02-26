# proper data access
A Façade over a Data Transfer Object (DTO), exposed through layered entrypoints.

## 1️⃣ Façade Pattern (Primary Pattern)

QueryResult is a Façade.

## 2️⃣ Dual Interface / Layered Entry Points

You also implemented:
	•	query_raw() → structural output
	•	query() → façade output

This is sometimes called:

Layered API design
or
Low-level + High-level API split

In some ecosystems this is referred to as:

“Power user API + ergonomic API”

## 3️⃣ Wrapper over a DTO

The raw table returned by the pipeline is a:

Data Transfer Object (DTO)

QueryResult wraps that DTO and gives it behavior.

This is sometimes called:

A Rich Wrapper
or
A Value Object Façade

## 4️⃣ Result Object Pattern

QueryResult is also an example of:

Result Object Pattern

Instead of returning:
```
{ path, exists, kind, files }
```
You return an object that represents the result of an operation.

This is common in:
	•	Go (os.FileInfo)
	•	Rust (std::fs::Metadata)
	•	Node (fs.Stats)
	•	Python (Path objects)


It wraps a structural data table and exposes:
	•	Semantic methods (is_directory())
	•	Intent helpers (require_directory())
	•	Domain language (files(), size())

It hides the raw representation.

That is textbook Façade.

## What It Is NOT

It is NOT:
	•	Builder pattern
	•	Factory pattern
	•	Adapter pattern
	•	Strategy pattern

It’s not transforming shape — it’s encapsulating it.

## In Plain Terms

You created:

A structured data result wrapped in a semantic façade,
exposed via layered entrypoints (raw + wrapped).

That’s a clean, professional pattern.


You discovered that you can:
	•	Preserve strict structural contracts
	•	Keep low-level tooling intact
	•	Add semantic clarity
	•	Improve ergonomics
	•	Improve LSP discoverability
	•	Avoid unwrapping rituals
	•	Keep layering clean

—all without increasing complexity.

That’s the shift from:

“moving data around”

to

“designing boundaries.”

----

# AS LAYERS

## 1️⃣ Layer 1 — Raw Structure (Data Reality)

This is the shape returned by pipelines.

It is:
	•	Dumb
	•	Structural
	•	Contract-validated
	•	No behavior
	•	No opinion
	•	No semantic guarantees beyond keys existing

Example (Query):
```lua
{
  path = "...",
  exists = true,
  kind = "directory",
  files = {...},
}
```
Example (Runtime):
```lua
{
  order = {...},
  boards = {...}
}
```
This layer answers:

“What is there?”

Nothing more.

## 2️⃣ Layer 2 — Semantic Façade (Meaning Layer)

This wraps structure and adds:
	•	Intent methods
	•	Semantic names
	•	Guard rails
	•	Discoverability
	•	LSP guidance

Example:
```lua
result:is_directory()
result:files()
result:require_directory()
```
Now the question becomes:

“What does this mean?”

You are not changing the data.
You are changing how it is accessed.

## 3️⃣ Layer 3 — Policy / Strictness

This is where you decide:
	•	Should it error?
	•	Should it return nil?
	•	Should it validate?
	•	Should it enforce invariants?
Examples:

```lua 
query()          -- relaxed
query_strict()   -- policy enforced
result:require_directory()
```
The Core Mental Model

Think of it like this:
```
Pipeline → DTO → Façade → Caller
```

Where:
	•	Pipeline produces raw structural truth.
	•	DTO is the data shape.
	•	Façade interprets it.
	•	Caller consumes meaning.

The pipeline does not know about callers.
The façade does not know about IO.
The caller does not know about structure.

Each layer has one job.


## Why This Is So Powerful

Because it solves:

1. Cognitive Load
You don’t need to remember structure keys.

2. Stability
You can refactor internal structure without breaking external API.

3. Discoverability
LSP shows you methods.

4. Policy Separation
Strictness is optional and controlled.

5. Architectural Clarity
Each layer has a clear responsibility.


## The Rule You Must Memorize

Raw tables stay internal.
Meaningful objects cross boundaries.

If something leaves a controller, it should usually be wrapped.

If something stays inside a pipeline, it should stay structural.


## When To Apply This Pattern

Use façade layering when:
	•	You return structured data
	•	The structure has semantic meaning
	•	The consumer shouldn’t know raw shape
	•	The system will grow

Do NOT use it for:
	•	Simple value transforms
	•	Temporary data inside a function
	•	Pure algorithm steps


### Applying It Everywhere (Your System)

You can apply this pattern to:

Runtime >>
Return RuntimeView (you already are).

Query >>
Return QueryResult.

Ledger >>
Return LedgerResult.

Compare >>
Return CompareResult.

Invoice >>
Return InvoiceResult.

Pricing >>
Return PricingSurface.

Anywhere you return a table with meaning.


### The Architecture Formula

Every domain controller should look like:
```
Controller
  ├── pipeline.run()        -- raw structure
  ├── query_raw()           -- raw DTO
  ├── query()               -- façade
  ├── query_strict()        -- strict façade
  └── ResultObject          -- semantic wrapper
```
The Deeper Principle

You are separating:
	•	Representation
	•	Interpretation
	•	Enforcement

Most codebases mix those together.
Yours doesn’t have to.


## Burn This Into Your Brain


Structure is what exists.
Meaning is how you talk about it.
Policy is how strict you are about it.

Never mix them.


# 🧠 The General Layering Schema
Every domain should follow this shape:
```
internal/      → pure logic
pipelines/     → orchestration, produces DTO
controller/    → boundary
result object  → semantic façade
```
At runtime it looks like:
```
INPUT
  ↓
Pipeline (raw structural truth)
  ↓
DTO (plain validated table)
  ↓
Result Object (semantic wrapper)
  ↓
Caller
```
## 📦 Canonical Controller Schema

Here is the generalized template.

Use this pattern everywhere.

### 1️⃣ Controller File Structure
```
-- domain/controller.lua
--
-- Intent:
--   Boundary layer for <domain>.
--   Separates raw structural output from semantic consumption.
--
-- Exposes:
--   run_raw(input)    → validated DTO
--   run(input)        → Result façade
--   run_strict(input) → strict façade
```
## 2️⃣ Raw DTO Contract
```
Controller.CONTRACT = {
    in_ = {
        input = true,
    },
    out = {
        -- required fields
        id    = true,
        items = true,
        meta  = false,
    }
}
```
DTO rules:
	•	Must be a plain table
	•	No behavior
	•	No metatables
	•	No policy
	•	Fully validated

### 3️⃣ Result Object (Façade Layer)
```lua
---@class DomainResult
---@field private __data table
local DomainResult = {}
DomainResult.__index = DomainResult

function DomainResult.new(data)
    return setmetatable({ __data = data }, DomainResult)
end
```
#### Semantic Methods (Meaning Layer)
```lua
function DomainResult:id()
    return self.__data.id
end

function DomainResult:items()
    return self.__data.items
end

function DomainResult:is_empty()
    return #self.__data.items == 0
end
```
These methods:
	•	Express meaning
	•	Hide raw structure
	•	Are LSP-discoverable
	•	Never expose raw keys directly
#### Policy Methods (Strictness Layer)
```lua
function DomainResult:require_items()
    assert(#self.__data.items > 0, "[domain] no items")
    return self
end
```
Strictness lives here, not in the pipeline.

### 4️⃣ Raw Entry Point
```lua
function Controller.run_raw(input)
    local dto, err = Pipeline.run(input)
    if not dto then
        return nil, err
    end

    Contract.assert(dto, Controller.CONTRACT.out)

    return dto
end
```
### 5️⃣ Façade Entry Pointo
```lua
function Controller.run(input)
    local dto, err = Controller.run_raw(input)
    if not dto then
        return nil, err
    end

    return DomainResult.new(dto)
end
```
### 6️⃣ Strict Entry Point
```lua
function Controller.run_strict(input)
    local result, err = Controller.run(input)
    if not result then
        error(err, 2)
    end
    return result
end
```
## 🧩 What This Achieves
Layer               Responsibility         Allowed to Know
Pipeline            Structural truth      Internal logic only
DTO                 Validated data           Shape only
Result Object       Meaning                   DTO shape
Controller          Policy boundary        Everything above
Caller              Intent               Only Result methods

Each layer knows less than the one below it.

That is what makes it scalable.

## 🏗 How This Applies to Your System

You can formalize this pattern across:

Runtime
	•	DTO = RuntimeBatch[]
	•	Result = RuntimeView

Query
	•	DTO = structural filesystem table
	•	Result = QueryResult

Ledger
	•	DTO = { transactions = {}, totals = {} }
	•	Result = LedgerResult

Compare
	•	DTO = { rows = {}, signals = {} }
	•	Result = CompareResult

Invoice
	•	DTO = { lines = {}, totals = {} }
	•	Result = InvoiceResult

## 🏗 How This Applies to Your System

You can formalize this pattern across:

Runtime
	•	DTO = RuntimeBatch[]
	•	Result = RuntimeView

Query
	•	DTO = structural filesystem table
	•	Result = QueryResult

Ledger
	•	DTO = { transactions = {}, totals = {} }
	•	Result = LedgerResult

Compare
	•	DTO = { rows = {}, signals = {} }
	•	Result = CompareResult

Invoice
	•	DTO = { lines = {}, totals = {} }
	•	Result = InvoiceResult

## 🧬 Ultra-General Meta Schema
```
Controller
  ├── Pipeline.run(input) → DTO
  ├── run_raw()           → DTO
  ├── run()               → Result(DTO)
  └── run_strict()        → Result(DTO) | error

Result
  ├── semantic getters
  ├── convenience methods
  └── require_* policy guards
```


```lua
-- platform/io/query/controller.lua
--
-- Filesystem query controller.
--
-- Provides:
--   query_raw(path)    -> raw structural table
--   query(path)        -> QueryResult façade
--   query_strict(path) -> strict façade
--

local Pipeline   = require("platform.io.query.pipelines.inspect")
local Contract   = require("core.contract")
local Trace      = require("tools.trace.trace")
local Diagnostic = require("tools.diagnostic")

local Controller = {}

----------------------------------------------------------------
-- CONTRACT (for raw structural output)
----------------------------------------------------------------

Controller.CONTRACT = {
    in_ = {
        path = true,
    },
    out = {
        path   = true,
        exists = true,
        kind   = true,
        entries = false,
        files   = false,
        dirs    = false,
        size    = false,
        hash    = false,
    },
}

----------------------------------------------------------------
-- QueryResult (Façade)
----------------------------------------------------------------

---@class QueryResult
---@field private __data table
local QueryResult = {}
QueryResult.__index = QueryResult

---@param data table
---@return QueryResult
function QueryResult.new(data)
    return setmetatable({ __data = data }, QueryResult)
end

----------------------------------------------------------------
-- BASIC INTENT
----------------------------------------------------------------

--- Returns the queried path.
---@return string
function QueryResult:path()
    return self.__data.path
end

--- Returns true if the path exists.
---@return boolean
function QueryResult:exists()
    return self.__data.exists
end

--- Returns true if this is a directory.
---@return boolean
function QueryResult:is_directory()
    return self.__data.kind == "directory"
end

--- Returns true if this is a file.
---@return boolean
function QueryResult:is_file()
    return self.__data.kind == "file"
end

--- Returns true if this path is missing.
---@return boolean
function QueryResult:is_missing()
    return self.__data.kind == "missing"
end

----------------------------------------------------------------
-- DIRECTORY ACCESS
----------------------------------------------------------------

--- Returns full file paths inside this directory.
--- Errors if not a directory.
---@return string[]
function QueryResult:files()
    assert(self:is_directory(), "[query] not a directory")
    return self.__data.files
end

--- Returns subdirectory paths.
---@return string[]
function QueryResult:dirs()
    assert(self:is_directory(), "[query] not a directory")
    return self.__data.dirs
end

--- Returns raw directory entry names.
---@return string[]
function QueryResult:entries()
    assert(self:is_directory(), "[query] not a directory")
    return self.__data.entries
end

----------------------------------------------------------------
-- FILE ACCESS
----------------------------------------------------------------

--- Returns file size in bytes.
---@return integer|nil
function QueryResult:size()
    assert(self:is_file(), "[query] not a file")
    return self.__data.size
end

--- Returns file hash.
---@return string|nil
function QueryResult:hash()
    assert(self:is_file(), "[query] not a file")
    return self.__data.hash
end

----------------------------------------------------------------
-- STRICT HELPERS
----------------------------------------------------------------

---@return QueryResult
function QueryResult:require_exists()
    assert(self:exists(), "[query] path does not exist: " .. self:path())
    return self
end

---@return QueryResult
function QueryResult:require_directory()
    assert(self:is_directory(), "[query] expected directory: " .. self:path())
    return self
end

---@return QueryResult
function QueryResult:require_file()
    assert(self:is_file(), "[query] expected file: " .. self:path())
    return self
end

----------------------------------------------------------------
-- RAW ENTRYPOINT
----------------------------------------------------------------

--- Returns raw structural query result.
--- Use this only for low-level tooling.
---@param path string
---@return table|nil, string|nil
function Controller.query_raw(path)
    Trace.contract_enter("io.query_raw")
    Trace.contract_in({ path = path })

    Contract.assert({ path = path }, Controller.CONTRACT.in_)

    Diagnostic.scope_enter("io.query_raw")

    local result, err = Pipeline.run(path)

    if not result then
        Diagnostic.user_message(err or "query failed", "error")
        Diagnostic.scope_leave()
        Trace.contract_leave()
        return nil, err
    end

    Contract.assert(result, Controller.CONTRACT.out)

    Diagnostic.scope_leave()
    Trace.contract_leave()

    return result
end

----------------------------------------------------------------
-- FAÇADE ENTRYPOINT
----------------------------------------------------------------

--- Returns a QueryResult façade.
---@param path string
---@return QueryResult|nil, string|nil
function Controller.query(path)
    local raw, err = Controller.query_raw(path)
    if not raw then
        return nil, err
    end
    return QueryResult.new(raw)
end

----------------------------------------------------------------
-- STRICT FAÇADE
----------------------------------------------------------------

---@param path string
---@return QueryResult
function Controller.query_strict(path)
    local result, err = Controller.query(path)
    if not result then
        error(err, 2)
    end
    return result
end

return Controller


-- examples:
local Query = require("platform.io.query").controller
local result = Query.query(path)
local strict = Query.query_strict(path)
local raw    = Query.query_raw(path)

-- or
local IOQuery = require("platform.io.query").controller
local result = IOQuery.query_strict("/some/path")
local files  = result:require_directory():files()

```

You now have:
	•	Raw structural access for system tooling
	•	Semantic façade for application logic
	•	One pipeline
	•	One source of truth
	•	No duplication
	•	No confusion


