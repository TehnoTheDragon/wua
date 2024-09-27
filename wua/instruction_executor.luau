--!optimize 2
--!native

export type Instruction = {opcode: number, operand: any}

local OPCODES = {}
@native local function opcode(opcode: number, fn: (self: any, operand: any?) -> ())
    OPCODES[opcode] = fn
end

-- variable instructions
opcode(0x20, function(self, operand)
    
end)

-- numerics instructions
opcode(0x41, function(self, operand)
    self.stack:push(operand)
end)
opcode(0x6A, function(self, operand)
    local left = self.stack:pop()
    local right = self.stack:pop()
    self.stack:push(left + right)
end)

return function(self, instruction: Instruction)
    local opc = OPCODES[instruction.opcode]
    if opc then
        opc(self, instruction.operand)
    else
        error(`unsupported opcode: {("%02X"):format(instruction.opcode)}`, 2)
    end
end
