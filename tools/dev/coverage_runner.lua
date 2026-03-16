return function()

local Backend  = require("system.backend")
local Executor = require("system.execution.controller")

------------------------------------------------------------
-- Boot Application
------------------------------------------------------------

local app = Backend.run("default")

------------------------------------------------------------
-- Filesystem Capability
------------------------------------------------------------

local fs = app:fs()

fs:util():ensure_layout()
fs:util():inspect_schema()
fs:util():inspect_graph()
fs:util():app_root()
fs:util():fs_root()

fs:store():ledger()
fs:store():client()
fs:store():vendor()

fs:store():user()
fs:store():imports()
fs:store():exports()
fs:store():vault()

fs:store():system()
fs:store():staged()
fs:store():sessions()
fs:store():runtime_ids()
fs:store():presets()
fs:store():last_session()

fs:store():preset_domain("intent")

------------------------------------------------------------
-- Input Submission
------------------------------------------------------------

app:data():submit("vendor", {
    name = "coverage_vendor",
    path = "data/ref/ace_hardware.csv"
})

app:data():submit("job", {
    path = "data/test_inputs/compiled_lumber_orders.csv"
})

app:data():submit("client", {
    path = "data/ref/client_sample.csv"
})

app:data():submit("ledger", {
    path = "data/ref/ledger_sample.csv"
})

------------------------------------------------------------
-- Resource Descriptors
------------------------------------------------------------

local resources = app:data():resources()

resources:pull_system()
resources:pull_user_from_inputs()

resources:get("system","vendor")
resources:get("user","job")

pcall(function()
    resources:get_one("system","vendor","path")
end)

------------------------------------------------------------
-- Runtime Loading
------------------------------------------------------------

local runtime = app:data():runtime()

runtime:pull("system","vendor")
runtime:pull("user","job")

pcall(function()
    runtime:require("system","vendor",1)
end)

pcall(function()
    runtime:require("user","job",1)
end)

runtime:require_many("system","vendor",{1})
runtime:require_all_with_count("system","vendor",1)

runtime:exists("system","vendor",1)
runtime:get("system","vendor",1)

runtime:all("system","vendor")
runtime:batches("system","vendor")

runtime:set("system","vendor",1,{mock=true})
runtime:clear("system","vendor",1)
runtime:clear_role("system","vendor")

------------------------------------------------------------
-- Slot Management
------------------------------------------------------------

local slots = app:data():slots()

slots:set_selection("user","job",1)
slots:set_selection("user","job",{batch=1})
slots:set_selection("system","vendor",{batch=1})

slots:select_board("user","job",1,1)

slots:get_selection("user","job")
slots:resolve("user","job")

slots:set_config("pricing_mode","test")
slots:get_config("pricing_mode")

slots:clear_selection("user","job")

------------------------------------------------------------
-- Intent State
------------------------------------------------------------

local intent = app:data():intent()

intent:set("pricing",{ basis="vendor_anchor", percentage=10 })
intent:get("pricing")
intent:inspect()
intent:all()

pcall(function()
    intent:save("pricing")
end)

pcall(function()
    intent:write("coverage_test",{example=true})
end)

pcall(function()
    intent:load("coverage_test")
end)

intent:clear("pricing")

intent:pull_all()

------------------------------------------------------------
-- Context System
------------------------------------------------------------

local ctx = app:data():context()

ctx:create("coverage_ctx",{value=1})
ctx:get()
ctx:get("coverage_ctx")
ctx:list()

ctx:clear("coverage_ctx")

------------------------------------------------------------
-- Vars State
------------------------------------------------------------

local vars = app:data():vars()

vars:set("coverage_key",true)
vars:get("coverage_key")
vars:all()
vars:clear("coverage_key")

------------------------------------------------------------
-- Session
------------------------------------------------------------

local session = app:data():session()

local snap = session:snapshot()
session:restore(snap)

------------------------------------------------------------
-- Surface Introspection
------------------------------------------------------------

app:instance()
app:app_root()
app:inspect_state()
app:inspect_fs_graph()

------------------------------------------------------------
-- Services Facade
------------------------------------------------------------

local services = app:services()

services:inspect()

services:vendor()
services:invoice()
services:quote()
services:compare()
services:ledger()
services:pricing()

------------------------------------------------------------
-- Execution Path
------------------------------------------------------------

local exec = app:execution()

pcall(function() exec:run("pricing") end)
pcall(function() exec:run("quote") end)
pcall(function() exec:run("compare") end)
pcall(function() exec:run("ledger") end)

------------------------------------------------------------
-- Direct Executor Path
------------------------------------------------------------

pcall(function() Executor.run(app,"pricing") end)
pcall(function() Executor.run(app,"quote") end)
pcall(function() Executor.run(app,"compare") end)

end
