---@meta
-- AUTO-GENERATED FILE
-- Generated from schema runtime state
-- DO NOT EDIT

------------------------------------------------
-- FIELD DOMAINS
------------------------------------------------

---@alias SchemaFieldDomain
---|"allocation_entry"
---|"allocation_profile"
---|"batch"
---|"board"
---|"order"
---|"transaction"

------------------------------------------------
-- VALUE DOMAINS
------------------------------------------------

---@alias SchemaValueDomain
---|"allocation.basis"
---|"allocation.scope"
---|"board.grade"
---|"board.moisture"
---|"board.species"
---|"board.surface"
---|"board.tag"
---|"order.status"
---|"order.use"
---|"transaction.type"

------------------------------------------------
-- FIELD NAMES
------------------------------------------------

---@alias SchemaFieldName_allocation_profile
---|"allocations"
---|"description"
---|"extends"
---|"profile_id"

---@alias SchemaFieldName_transaction
---|"client_id"
---|"date"
---|"invoice_id"
---|"item_ids"
---|"notes"
---|"order_id"
---|"snapshot"
---|"total_bf"
---|"transaction_id"
---|"type"
---|"value"

---@alias SchemaFieldName_batch
---|"allocations"
---|"boards"
---|"meta"
---|"order"

---@alias SchemaFieldName_order
---|"client_id"
---|"date"
---|"items"
---|"order_id"
---|"order_notes"
---|"order_number"
---|"order_status"
---|"use"
---|"value"

---@alias SchemaFieldName_board
---|"base_h"
---|"base_w"
---|"bf_batch"
---|"bf_ea"
---|"bf_per_lf"
---|"bf_price"
---|"ct"
---|"ea_price"
---|"grade"
---|"l"
---|"lf_price"
---|"moisture"
---|"species"
---|"surface"
---|"tag"

---@alias SchemaFieldName_allocation_entry
---|"amount"
---|"basis"
---|"category"
---|"party"
---|"priority"
---|"scope"

------------------------------------------------
-- ENUM SYMBOLS
------------------------------------------------

---@alias SchemaEnum_allocation_basis
---|"fixed"
---|"per_bf"
---|"percent"

---@alias SchemaEnum_order_use
---|"adjustment"
---|"gift"
---|"personal"
---|"sale"
---|"transfer"
---|"waste"

---@alias SchemaEnum_board_tag
---|"c"
---|"f"
---|"n"

---@alias SchemaEnum_board_grade
---|"BC"
---|"BH"
---|"CA"
---|"CC"
---|"HA"
---|"HC"
---|"MC"
---|"MH"
---|"SC"
---|"SH"

---@alias SchemaEnum_board_species
---|"CD"
---|"DF"
---|"HF"
---|"PN"
---|"RW"

---@alias SchemaEnum_allocation_scope
---|"board"
---|"order"
---|"profit"

---@alias SchemaEnum_order_status
---|"closed"
---|"open"
---|"void"

---@alias SchemaEnum_board_surface
---|"RO"
---|"S2"
---|"S4"
---|"SL"
---|"TG"
---|"VR"

---@alias SchemaEnum_board_moisture
---|"AD"
---|"GR"
---|"KD"

---@alias SchemaEnum_transaction_type
---|"adjustment"
---|"gift"
---|"personal"
---|"purchase"
---|"refund"
---|"sale"
---|"transfer"
---|"waste"
