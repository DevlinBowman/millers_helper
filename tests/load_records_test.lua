local Load = require("application.use_cases.load_records")

print("\n=== LOAD RECORDS ===")

do
    local result = Load.run_strict("data/test_inputs/test_lumber.json")
    assert(result.kind == "records")
    print("  ✓ json → records")
end

do
    local result = Load.run_strict("data/test_inputs/test_lumber.csv")
    assert(result.kind == "records")
    print("  ✓ csv → records")
end

do
    local result, err = Load.run("data/test_inputs/test_lumber.txt")
    assert(result == nil)
    assert(err)
    print("  ✓ text rejected (parser-owned)")
end

print("\nLOAD RECORDS TEST COMPLETE")
