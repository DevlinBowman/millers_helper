-- tests/run_tests.lua
-- run all tests
--
local Tests = {}

local suite = {
    format_surface = require('tests.format_surface_test'),
    io_surface = require('tests.io_surface_test'),
    load_records = require('tests.load_records_test'),
}

function Tests.run_all(group)
    for _, test in ipairs(group) do
        test = test
    end
end

Tests.run_all(suite)

