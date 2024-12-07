local types = require("types")
local parser = require("parser")
local result = require("../result")
type Self = types.WasmModule

local WasmModule = {}

function WasmModule.new(bytes: types.bytes): result.Result<Self, string>
    local module = parser.new():parse(bytes)
    if module:is_err() then
        return module
    end
    return setmetatable(module, {__index = WasmModule}) :: any
end

return table.freeze(WasmModule)