Canopy Host Integration Contract (v1.0.0)

## Overview

Canopy is a declarative Lua UI runtime.

To integrate an external system with Canopy, you must provide:
	1.	A Spec table
	2.	A Context table

Canopy will:
	•	Validate your Spec
	•	Call your node callbacks
	•	Never require your modules
	•	Never mutate your context (except through edit.set)

### Required Spec Shape

```lua
{
    id    = "string",
    title = "string",
    nodes = { NodeSpec[] }
}
```

### NodeSpec Shape

```lua
{
    id    = "string",
    label = "string",

    -- ONE OR MORE OF:

    action  = function(ctx) end,

    next    = function(ctx)
        return Spec
    end,

    resolve = function(ctx)
        return Spec
    end,

    edit = function(ctx)
        return {
            value = any,
            set = function(new_value) end
        }
    end,

    children = { NodeSpec[] }
}
```

### Context Shape

```lua
Canopy.open({
    spec = MySpec,
    context = {
        api = MyAPI,
        state = {}
    }
})
```

Canopy guarantees:
	•	It will only pass context to your callbacks.
	•	It will never mutate context fields.
	•	It will never require your modules.

## Bridge Isolation Rule

If you are running Canopy inside LuaJIT (Neovim)
and your domain uses Lua 5.4:

You must isolate domain logic behind a bridge.

Canopy never loads domain modules directly or you will be fighting lua version mismatches.

## Versioning

Current contract version:

```
1.0.0
```
