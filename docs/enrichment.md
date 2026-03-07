# Enrichment

## Schema Layer
The schema layer is the primary domain graph and schema validation engine for the the entire project. It acts as the structural authority for the entire data model as a runtime engine. All primary runtime schemas come from it.


### Primary Purpose

Defines the canonical structure of all domain objects and provides
runtime tools to inspect, validate, traverse, construct, and safely
mutate those objects.

All higher-level systems (enrichment, pricing, allocation, ledger,
services, UI) rely on this layer for structural authority.


### Public Method Capabilities

Schema.controller.domain(domain):domain()
    # Retrieve the canonical schema definition for a domain.
    # Returns metadata describing the domain and its registered fields.

Schema.controller.field(domain, field):field()
    # Retrieve the schema record for a specific field.
    # Returns metadata such as type, required status, groups, reference,
    # authority, units, precision, etc.

Schema.controller.template(domain):template()
    # Generate a canonical object template for a domain.
    # Returns a new table with all fields defined and initialized
    # according to schema defaults (usually nil).

Schema.controller.audit(domain, obj):audit()
    # Validate an object against the domain schema.
    # Checks field presence, structure, and validation rules.
    # Returns an audit report describing object correctness.

Schema.controller.audit(domain, obj):audit():deep()
    # Perform recursive validation across the entire object graph.
    # Traverses nested domains using schema references and returns
    # a hierarchical audit report.

Schema.controller.dto(domain, obj):dto()
    # Construct a DTO wrapper for a domain object.
    # Used to apply controlled mutations that respect schema rules.
    # Ensures field existence, type correctness, and normalization.

dto:apply(patch, opts?)
    # Apply a patch table to the DTO object.
    # Validates and normalizes values before committing them to
    # the underlying object.

dto:export()
    # Export the normalized object after DTO mutation.
    # Returns the canonical representation of the object.


### Traversal Capability

Walker.walk(domain, obj, visitor)
    # Traverse an object graph using schema relationships.
    # Invokes visitor callbacks for each field encountered.

visitor(domain, field_record, value, depth)
    # Visitor callback signature used during traversal.
    # Provides access to field metadata and the current value.


### Field Metadata (from schema definitions)

Each field record may contain the following attributes:

name
    # Canonical field identifier.

type
    # Expected value type.

required
    # Indicates whether the field must be present.

groups
    # Semantic group membership used by systems like enrichment.

reference
    # Indicates that the field points to another domain object
    # or collection of objects.

authority
    # Indicates whether the value is authoritative, derived, or inferred.

unit
    # Measurement unit associated with numeric values.

precision
    # Decimal precision for numeric values.

description
    # Human-readable explanation of the field.


### Core Responsibilities

The schema layer is responsible for:

    • Domain structure definition
    • Field metadata definition
    • Object template construction
    • Structural validation
    • Recursive graph validation
    • Schema-aware object traversal
    • Safe mutation via DTO wrappers

The schema layer does NOT perform business logic.


### Intended Consumers

The following systems rely on the schema layer:

    enrichment
    pricing
    allocation
    compare
    ledger
    services
    UI inspection tools


Design Principle

The schema layer is the single source of truth for data structure.
All systems above it must derive structural knowledge from the schema
rather than defining their own models or assumptions.


## Enrichment Layer e
