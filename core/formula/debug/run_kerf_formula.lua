local BoardFormula = require("core.formula.board.class")

local board = {
    base_h = 2,
    base_w = 4,
    h = 2,
    w = 4,
    l = 8,
    ct = 10
}

local F = BoardFormula.new(board)

print("BF:", F:bf())
print("Batch BF:", F:batch_bf())

local kerf = F:kerf(5/16)
print("Kerf Waste BF:", kerf.waste_total_bf)

local delta = F:n_delta()
print("Nominal Delta %:", delta.delta_percent)

print("EA -> BF:", F:ea_to_bf(25))
