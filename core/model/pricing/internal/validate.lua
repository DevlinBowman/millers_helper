-- core/model/pricing/internal/validate.lua

local Validate = {}

local function assert_number(name, v)
    assert(type(v) == "number", name .. " must be number")
end

local function assert_table(name, v)
    assert(type(v) == "table", name .. " must be table")
end

local function validate_piecewise(name, curve)
    assert_table(name, curve)
    for i, step in ipairs(curve) do
        assert(type(step) == "table", name .. "[" .. i .. "] must be table")
        assert_number(name .. "[" .. i .. "].max", step.max)
        assert_number(name .. "[" .. i .. "].factor", step.factor)
        assert(step.factor > 0, name .. "[" .. i .. "].factor must be > 0")
    end
end

function Validate.run(profile, schema)
    assert(type(profile) == "table", "Pricing.validate(): profile must be table")
    assert(type(profile.profile_id) == "string" and profile.profile_id ~= "", "profile_id required")

    assert_number("overhead_per_bf", profile.overhead_per_bf or 0)
    assert_number("base_markup_pct", profile.base_markup_pct or 0)
    assert_number("min_margin_per_bf", profile.min_margin_per_bf or 0)

    if profile.grade_curve then assert_table("grade_curve", profile.grade_curve) end
    if profile.size_curve then validate_piecewise("size_curve", profile.size_curve) end
    if profile.length_curve then validate_piecewise("length_curve", profile.length_curve) end

    if profile.custom_order then
        assert_table("custom_order", profile.custom_order)
        if profile.custom_order.waste_curve then validate_piecewise("custom_order.waste_curve", profile.custom_order.waste_curve) end
        if profile.custom_order.rush_curve then validate_piecewise("custom_order.rush_curve", profile.custom_order.rush_curve) end
        if profile.custom_order.small_piece_curve then validate_piecewise("custom_order.small_piece_curve", profile.custom_order.small_piece_curve) end
    end

    if profile.retail_discount_points then
        assert_table("retail_discount_points", profile.retail_discount_points)
        for i, d in ipairs(profile.retail_discount_points) do
            assert(type(d) == "number", "retail_discount_points[" .. i .. "] must be number")
        end
    end

    return profile
end

return Validate
