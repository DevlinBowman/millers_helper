# CLI Architecture & Extension Guide

This document describes the conceptual model, control flow, and extension rules for the CLI system.

It explains how the CLI thinks and how new functionality should be added.

This is not user-facing documentation and does not describe individual commands or features.


## Mental Model

The CLI is a domain-oriented interface layer over the application.

It translates user intent into coordinated service calls, without implementing business logic itself.

Think in layers:

CLI Shell
↓
Domain Controller (orchestration)
↓
Application / Service Layer

The CLI owns intent, routing, and presentation — nothing else.


## High-Level Execution Flow

At runtime, the CLI performs the following steps:
    1.    Parse argv into structured intent
    2.    Resolve the domain and command
    3.    Instantiate the domain controller
    4.    Inject context and controller into the command
    5.    Execute the command adapter
    6.    Render output through cli/core

Conceptually:

argv
→ Parser
→ { domain, action, args, flags }
→ Registry
→ Controller(domain)
→ Command.run(ctx, controller)



## Core Principles



## 1. Domain-Oriented Structure

Each top-level CLI domain maps to a conceptual service cluster:
    •    ledger
    •    parse
    •    ingest
    •    review
    •    …

A domain represents what the user is working with, not how it is implemented.

Each domain lives under:

cli/domains//



## 2. Commands Are Interface Adapters

Commands are intentionally thin. They:
    •    Define help text
    •    Define argument shape
    •    Delegate execution to the controller

Commands must not:
    •    Load services directly
    •    Perform IO
    •    Implement business logic
    •    Mutate application state

A command file should conceptually contain:
    •    A help table
    •    A run(ctx, controller) function that delegates to the controller

If logic appears in a command, it belongs in the controller.



## 3. Controllers Are the Orchestration Layer

Each domain has exactly one controller:

cli/domains//controller.lua

The controller is responsible for:
    •    Interpreting flags and positionals
    •    Coordinating service calls
    •    Deciding dry-run vs mutation
    •    Loading and saving state
    •    Selecting output shape

Controllers may:
    •    Require application services
    •    Perform sequencing and branching
    •    Decide what to render

Controllers must not:
    •    Parse argv
    •    Define help text
    •    Print directly (must use cli/core)



## 4. cli/init.lua Owns Lifecycle

cli/init.lua is the only place where:
    •    Domains are loaded
    •    Controllers are instantiated
    •    Commands are invoked

No other file should:
    •    Construct controllers
    •    Call other domains
    •    Manage global CLI state

All lifecycle and wiring changes happen here.



## 5. Registry Is Structural Only

The registry:
    •    Knows which domains exist
    •    Knows which commands belong to each domain
    •    Knows which controller a domain uses

It does not:
    •    Execute code
    •    Validate arguments
    •    Contain business logic

The registry is a lookup table and nothing more.



## 6. Context Is the Execution Envelope

ctx is passed unchanged through the CLI boundary.

It contains:
    •    Parsed arguments and flags
    •    stdout / stderr handles
    •    Helper methods for usage and fatal errors

Context should be treated as read-only input plus a reporting channel.



## 7. Output Is Centralized

All user-visible output flows through:

cli/core/printer.lua

Controllers must not:
    •    Call print()
    •    Call Inspector.print() directly
    •    Write to stdout or stderr manually

This allows future output modes (JSON, TUI, logging, testing) without rewriting controllers.


## Directory Structure (Canonical)

cli/
├─ init.lua              CLI shell & dispatcher
├─ parser.lua            argv → intent
├─ registry.lua          domains, commands, controllers
├─ context.lua           execution context
├─ help.lua              help rendering
│
├─ core/
│  ├─ printer.lua        all output
│  ├─ render.lua         render dispatch (future)
│  └─ layout/            future structured layouts
│
└─ domains/
└─ /
├─ init.lua        domain registration
├─ controller.lua  orchestration
├─ .lua   interface adapters
└─ …

## Adding a New Domain

Checklist:
    1.    Create the domain directory:
cli/domains//
    2.    Add a controller:
controller.lua
    3.    Create init.lua to:
    •    Register the domain
    •    Attach the controller
    •    Register commands
    4.    Add command adapter files:
.lua
    5.    Require the domain in cli/init.lua

No other files need to change.



Adding a New Command

Checklist:
    1.    Create a new file:
cli/domains//.lua
    2.    Define:
    •    help
    •    run(ctx, controller)
    3.    Register the command in the domain’s init.lua

Do not modify:
    •    cli/init.lua
    •    Other domains
    •    Registry internals



What This Design Optimizes For
    •    Predictable growth
    •    Low cognitive overhead
    •    Clear separation of concerns
    •    Future TUI support
    •    Testability
    •    Refactor safety

The CLI is intentionally boring.
That is a feature.



Non-Goals (By Design)
    •    Automatic command discovery
    •    Magic reflection
    •    Shared mutable CLI state
    •    Domain cross-calling
    •    UI logic inside services

If any of these feel necessary, stop and reassess the design.



Final Rule

Commands describe the interface.
Controllers describe behavior.
Services do the work.

If this invariant holds, the CLI will scale cleanly.
