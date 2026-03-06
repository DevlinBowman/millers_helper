local function run_schema_surface_test()

    local Schema = require("core.schema")
    print("\nSCHEMA SURFACE TEST")
    print("-------------------")
    ------------------------------------------------
    -- field lookup
    ------------------------------------------------
    local field = Schema.schema.field("board", "grade")
    assert(field ~= nil, "field lookup failed")
    print("field lookup OK")

    ------------------------------------------------
    -- enum lookup
    ------------------------------------------------
    local value = Schema.schema.value("board.grade", "CA")
    assert(value ~= nil, "enum lookup failed")
    print("enum lookup OK")

    ------------------------------------------------
    -- field list
    ------------------------------------------------
    local fields = Schema.schema.fields("board")
    assert(type(fields) == "table", "field list failed")
    print("field list OK")

    ------------------------------------------------
    -- enum universe
    ------------------------------------------------
    local values = Schema.schema.values("board.grade")
    assert(type(values) == "table", "enum universe failed")
    print("enum universe OK")

    ------------------------------------------------
    -- reference resolution
    ------------------------------------------------
    local ref = Schema.schema.reference("grade", "board")
    assert(ref == "board.grade", "reference resolution failed")
    print("reference resolution OK")

    ------------------------------------------------
    -- DTO creation
    ------------------------------------------------
    local dto = Schema.object.dto("board", { grade = "CA" })
    assert(dto ~= nil, "dto creation failed")
    print("dto creation OK")

    ------------------------------------------------
    -- validation
    ------------------------------------------------
    local ok = Schema.object.check("board", { grade = "CA" })
    assert(ok ~= nil, "validation failed")
    print("validation OK")

    ------------------------------------------------
    -- audit
    ------------------------------------------------
    local audit = Schema.object.audit("board", { grade = "CA" })
    assert(audit ~= nil, "audit failed")
    print("audit OK")

    ------------------------------------------------
    -- query API
    ------------------------------------------------
    local item = Schema.query.get("board.grade")
    assert(item ~= nil, "query.get failed")
    print("query.get OK")

    local domains = Schema.query.domain_names()
    assert(type(domains) == "table", "query.domain_names failed")
    print("query.domain_names OK")

    ------------------------------------------------
    -- inspect API
    ------------------------------------------------
    local inspect = Schema.inspect.domain("board")
    assert(inspect ~= nil, "inspect.domain failed")
    print("inspect.domain OK")

    print("\nSCHEMA SURFACE TEST PASSED\n")
end

run_schema_surface_test()
