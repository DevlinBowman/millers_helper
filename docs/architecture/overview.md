# Module Architecture Standard
# the "arc-spec"

This document defines the required structure and behavioral rules for every module in the system.
These are requirements for EVERY module. Modules should each be managed as standalone, first class systems that to not require between eachother. Chaining of behaviors across modules is manages in the top level .pipelines/* by importing and orchestrating behaviors exposed in module controllers. This maintains a tree-like designs patterns where all controll moves in a single direction for external use

## The Golden Rule for Module Structure

### Deterministic Logic Layer ('internal/*.lua")
The internal layer should explicitly contain only pure defined behavior. These scripts contain local domain layer logic only.
Each script should adopt a namespace that reflects its capacity at the 'tool' it is defined to be. this is the domain of determinism.
rule; 'if behavior requires reasoning or calculation it must first be distilled into an internal script'

### Structural Separation Later ("registry.lua")
a simple dependency boundary that forcibly divides the implementation logic from the composition of that logic.


### Orchestration Layer ("pipelines/*lua")
The pipeline layer should explicitly contain only execution of internal behaviors. These scripts contain only composed internals.
Each script should adopt a namespace that reflects its expected output. This is the domain of side effects.
rule; 'if behavior must be composed, it is time to create a pipeline script'

### Boundary Layer ("controller.lua")
The controller is the top of the line. It gatekeeps the entirety of the modules public surface.



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

- init.lua exposes the regitsry and the controller.
- controller.lua exposes the 'pipeline' defined behaviors and acts as a top level throughput control panel.
- pipeline/*.lua orchestrates complex behaviors.
- registry.lua exposes 'internal/' endpoints.
- internal/*.lua defined low level capabilities.

---

# Layer Responsibilities

## 1. internal/

**Purpose**
Pure implementation. Core logic lives here.

Any 'internal' file should serve a strict logical purpose in defining some schema, spec, or capability.

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
Expose 'internal/' capabilities.

Registry is a flat capability map for 'piplines' to access 'internal/' behaviors from. If somebody need internals

It must:
- Require internal files
- Return references only
- Contain no orchestration logic
- Contain no tracing
- Contain no validation
- Contain no contract enforcement

Registry is a directory, not a processor.

It answers:
> What do this modules internals provide?

It does not answer:
> How is it used?

---

## 3. pipelines/

**Purpose**
Chain behaviors together.

Pipelines define the systems that compose internals into useable structures. They are NOT to be used as wrappers or fascades. If internal scripts need to talk to eachother, pipeline scripts define how this is done. This is the modules orchestration layer. As is pertains to the modules expected use case, intent is defined here.

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
> How are internals intended to be used?

---

## 4. controller.lua

**Purpose**
Boundary definition and developer-facing entry point.

The controller is meant explicitly to wrap and expose functionality defined in 'pipelines/' orchestration layer. It is the modules primary service access point and should only be used to expose pipeline functionality and related checks. The controller is the access point/ boundary layer for the module. As boundary, it may define or include boundary level management code such as guards, traces, debug info, etc. This script should serves as a simple way to get and/or review the surface of the module in one place.

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
- Expose pipeline behaviors

It answers:
> What does this module expect?
> What does it return?
> What does it guarantee?

Controllers must not:
- Require 'internal/' files directly
- Require the registry
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
