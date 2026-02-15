# Module Architecture Standard
# the "arc-spec"

This document defines the required structure and behavioral rules for every module in the system.
These are requirements for EVERY module. Modules should each be managed as standalone, first class systems that to not require between eachother. Chaining of behaviors across modules is manages in the top level .pipelines/* by importing and orchestrating behaviors exposed in module controllers.

## The Golden Rule for Module Structure

### Internal Layer
The internal layer should explicitly contain only pure defined behavior. These scripts contain local domain layer logic only.
Each script should adopt a namespace that reflects its capacity at the 'tool' it is defined to be. this is the domain of determinism.
rule; 'if behavior requires reasoning or calculation it must first be distilled into an internal script'


### Pipeline Layer
The pipeline layre should explixitly contain only execution of internal behaviors. These scripts contain only composed internals.
Each script should adopt a namespace that reflects its expected output. This is the domain of side effects.
rule; 'if behavior must be composed, it is time to create a pipeline script'

### Module Layer
Behavior is defined in internal.
Behavior is composed in pipelines.
Behavior is exposed in controller.

Behavior Definition is decoupled from Behavior Execution.

These may not be allowed to collapse.


## Module layer Examples

All modules must follow this layout:
```
module/
│
├── init.lua
├── controller.lua
├── registry.lua
│
├── pipelines/        (optional)
│   └── *.lua
│
└── internal/ [or dirs as needed (not required to be stored explicitly in 'internal/']
└── *.lua

```

```
                 RUNTIME FLOW (DOWNWARD)

                ┌────────────────────┐
                │     CONTROLLER     │
                │  contract + trace  │
                └─────────┬──────────┘
                          │
                          ▼
                ┌────────────────────┐
                │      PIPELINE      │
                │   behavior chain   │
                └─────────┬──────────┘
                          │
                          ▼
                ┌────────────────────┐
                │      REGISTRY      │
                │   capability map   │
                └─────────┬──────────┘
                          │
                          ▼
                ┌────────────────────┐
                │      INTERNAL      │
                │     pure logic     │
                └────────────────────┘


                 RETURN FLOW (UPWARD)

      INTERNAL → REGISTRY → PIPELINE → CONTROLLER
```

No exceptions.

---

# Layer Responsibilities

## 1. internal/

**Purpose**
Pure implementation. Core logic lives here.

**Allowed**
- Data transforms
- Builders
- Spec definitions
- Mechanical helpers
- Alias resolution
- Partition logic
- Pure computation

**Forbidden**
- Requiring `controller`
- Requiring `registry`
- Tracing
- Contracts
- Cross-module orchestration

Internal code must:
- Be composable
- Be deterministic
- Avoid side effects
- Avoid upward dependencies

This is the engine room.

---

## 2. registry.lua

**Purpose**
Expose internal capabilities.

Registry is a flat capability map.

It must:
- Require internal files
- Return references only
- Contain no orchestration logic
- Contain no tracing
- Contain no validation
- Contain no contract enforcement

Registry is a directory, not a processor.

It answers:
> What does this module provide?

It does not answer:
> How is it used?

---

## 3. pipelines/

**Purpose**
Chain behaviors together.

Pipelines:
- Require the registry
- Compose internal capabilities
- Return structured results
- Do not validate input shape
- Do not define contracts
- Do not trace

Pipelines define behavior combinations.

They answer:
> How are internal pieces composed?

---

## 4. controller.lua

**Purpose**
Boundary definition and developer-facing entry point.

Controller must:
- Define contracts (`in_` and `out`)
- Include tracing
- Enforce structural assertions
- Call pipelines or registry endpoints
- Expose strict variants (optional)

Controller is the only layer allowed to:
- Trace
- Validate
- Define input/output structure

It answers:
> What does this module expect?
> What does it return?
> What does it guarantee?

Controllers must not:
- Require internal files directly
- Contain core logic
- Duplicate internal behavior

---

## 5. init.lua

Public module surface.

Must expose:

```lua
return {
    controller = Controller,
    registry   = Registry,
}
