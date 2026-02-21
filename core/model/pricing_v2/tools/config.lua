-- core/model/pricing_v2/tools/config.lua
--
-- Single source of truth for the pricing_v2 tools.
-- Must preserve exact behavior of:
--   • pricing_surface_dump.lua
--   • printing_surface_dump_extract.lua

local Config = {}

-- Match BOTH scripts
Config.baseline_price_per_bf = 2.00

-- Match pricing_surface_dump.lua lengths
Config.surface_lengths = { 8, 10, 12, 16, 20 }

-- Match printing_surface_dump_extract.lua lengths
Config.extract_lengths = { 6, 8, 10, 12, 16 }

-- Dimension regimes (must match both scripts)
Config.actual = {
  heights = { 1, 2, 4, 6, 8 },
  widths  = { 1, 2, 4, 6, 8, 10, 12 },
}

Config.nominal = {
  heights = { 0.75, 1.5, 3.5, 5.5, 7.25 },
  widths  = { 0.75, 1.5, 3.5, 5.5, 7.25, 9.25, 11.25 },
}

-- Match extract script output dir
Config.output_dir = os.getenv("HOME") .. "/Desktop/board_data/in_data/"

return Config
