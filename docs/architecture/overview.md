# Architecture Constraints

## Module Registry Dependency Architecture Requirement

Every module must expose a registry.lua that serves as a pure compatibility surface for the module’s internal systems. It is the authoritative internal interface for that module.

Internal scripts must not require each other directly. All internal cross-dependencies must resolve through the registry.

The registry exposes behavior but does not implement it.

## Requirements
	•	Must use lazy resolution (no top-level requires of internal modules) to prevent circular load failures
	•	Must not contain business logic, orchestration, validation, or transformation logic
	•	Must statically declare its surface (no dynamic key generation)
	•	Must expose endpoints for all intended internal cross-module behaviors
	•	Internal files may require the registry, but must not require sibling internal files directly
