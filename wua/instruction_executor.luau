--!optimize 2
--!native
local types = require("types")

local OPCODES = {}
@native local function opcode<T>(opcode: number, fn: (self: any, operand: T) -> ())
    OPCODES[opcode] = fn
end

-- variable instructions
opcode(0x20, function(self: types.WasmRuntime, operand: number)
    self.stack:push(self.stack:get(operand))
end)
opcode(0x21, function(self: types.WasmRuntime, operand: number)
    self.stack:set(operand, self.stack:pop())
end)
opcode(0x22, function(self: types.WasmRuntime, operand: number)
    self.stack:set(operand, self.stack:peek())
end)
opcode(0x23, function(self: types.WasmRuntime, operand: number)
    self.stack:push(self.globals[operand].value)
end)
opcode(0x24, function(self: types.WasmRuntime, operand: number)
    local global = self.globals[operand]
    if not global then
        self.globals[operand] = {value = self.stack:pop(), mutable = true}
    else
        if not global.mutable then
            error(`global {operand} is immutable`, 2)
        end
        global.value = self.stack:pop()
    end
end)

-- numerics instructions
opcode(0x41, function(self: types.WasmRuntime, operand)
    self.stack:push(operand)
end)
opcode(0x6A, function(self: types.WasmRuntime, operand)
    local left = self.stack:pop()
    local right = self.stack:pop()
    self.stack:push(left + right)
end)

return function(self, instruction: types.Instruction)
    local opc = OPCODES[instruction.opcode]
    if opc then
        opc(self, instruction.operand)
    else
        error(`unsupported opcode: {("%02X"):format(instruction.opcode)}`, 2)
    end
end
