local Curve = {}

function Curve.match_piecewise(curve, value)

    for index, rule in ipairs(curve) do
        if value <= rule.max then
            return {
                input_value  = value,
                matched_max  = rule.max,
                factor       = rule.factor,
                index        = index,
            }
        end
    end

    error("curve has no terminal rule")
end

function Curve.match_map(map, key)

    local factor = map[key] or map.DEFAULT or 1.0

    return {
        input_key = key,
        factor    = factor,
        source    = map[key] and "direct" or "default",
    }
end

return Curve
