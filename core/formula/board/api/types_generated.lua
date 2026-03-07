---@meta
-- AUTO-GENERATED FILE
-- Board Formula API symbolic type declarations
-- DO NOT EDIT

------------------------------------------------
-- BOARD FORMULA METHODS
------------------------------------------------

---@alias FormulaBoardMethod
---|"bf"
---|"bf_per_lf"
---|"bf_batch"
---|"kerf"
---|"n_delta"
---|"ea_to_bf"
---|"lf_to_bf"
---|"bf_to_ea"
---|"bf_to_lf"
---|"ea_to_batch"
---|"round"

------------------------------------------------
-- COMMON RECORDS
------------------------------------------------

---@class FormulaKerfResult
---@field waste_ratio number
---@field waste_total_bf number

---@class FormulaNominalDeltaResult
---@field delta_ratio number
---@field delta_percent number

------------------------------------------------
-- API SURFACES
------------------------------------------------

---@class FormulaBoardSurface
---@field new fun(board:table):FormulaBoardContext

---@class FormulaBoardContext
---@field h number
---@field w number
---@field l number
---@field ct number
---@field base_h number|nil
---@field base_w number|nil
---@field bf fun(self:FormulaBoardContext):number
---@field bf_per_lf fun(self:FormulaBoardContext):number
---@field bf_batch fun(self:FormulaBoardContext):number
---@field kerf fun(self:FormulaBoardContext, kerf:number):FormulaKerfResult
---@field n_delta fun(self:FormulaBoardContext):number, number
---@field ea_to_bf fun(self:FormulaBoardContext, ea_price:number):number
---@field lf_to_bf fun(self:FormulaBoardContext, lf_price:number):number
---@field bf_to_ea fun(self:FormulaBoardContext, bf_price:number):number
---@field bf_to_lf fun(self:FormulaBoardContext, bf_price:number):number
---@field ea_to_batch fun(self:FormulaBoardContext, ea_price:number):number
---@field round fun(self:FormulaBoardContext, value:number, decimals:number|nil):number
