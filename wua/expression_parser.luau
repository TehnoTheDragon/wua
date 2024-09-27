--!optimize 2
--!native

type ValueType = "none" | "u8" | "i8" | "u32" | "i32" | "u64" | "i64" | "f32" | "f64" | "leb128_u32" | "leb128_i32" | "leb128_u64" | "leb128_i64"

local valueTypeToReadFn = {
    none = nil,
    u8 = "_read_u8",
    i8 = "_read_i8",
    u32 = "_read_u32",
    i32 = "_read_i32",
    u64 = "_read_u64",
    i64 = "_read_i64",
    f32 = "_read_f32",
    f64 = "_read_f64",
    leb128_u32 = "_read_leb128_u32",
    leb128_i32 = "_read_leb128_i32",
    leb128_u64 = "_read_leb128_u64",
    leb128_i64 = "_read_leb128_i64",
}

local OPCODES = {}
@native local function opcode(opcode: number, operandType: ValueType)
    OPCODES[opcode] = function(self, wasm)
        local operand = if operandType == "none" then nil else self[valueTypeToReadFn[operandType]](self, wasm)
        return {
            opcode = opcode,
            operand = operand,
        }
    end
end

@native local function opcode_complex(opcode: number, fn: (self: any, wasm: buffer) -> any)
    OPCODES[opcode] = fn
end

-- variable instructions
opcode(0x20, "leb128_u32")
opcode(0x21, "leb128_u32")
opcode(0x22, "leb128_u32")
opcode(0x23, "leb128_u32")
opcode(0x24, "leb128_u32")

-- numeric instructions
opcode(0x41, "leb128_i32")
opcode(0x42, "leb128_i64")
opcode(0x43, "f32")
opcode(0x44, "f64")

opcode(0x6A, "none")

return function(self, wasm: buffer)
    local opcode = self:_read_u8(wasm)
    local expression = {}
    while opcode ~= 0x0B do
        local opc = OPCODES[opcode]
        if not opc then
            error(`unsupported opcode: {("%02X"):format(opcode)}`, 1)
        end
        table.insert(expression, opc(self, wasm))
        opcode = self:_read_u8(wasm)
    end
    table.insert(expression, {opcode = 0x0B})
    return expression
end