--!optimize 2
--!native
local types = require("types")

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
@native local function opcode(opcode: number, operandType: types.ValueType)
    OPCODES[opcode] = function(self, wasm)
        local operand = if operandType == "none" then nil else self[valueTypeToReadFn[operandType]](self, wasm)
        return {
            opcode = opcode,
            operand = operand,
        }
    end
end

@native local function opcode_complex(opcode: number, fn: (self: types.WasmParser, wasm: buffer) -> any)
    OPCODES[opcode] = fn
end

@native local function opcode_from_to(from: number, to: number, operandType: types.ValueType)
    for i = from, to do
        opcode(i, operandType)
    end
end

-- control instructions
opcode(0x00, "none") -- unreachable
opcode(0x01, "none") -- nop
-- | block |
-- | loop |
-- | if |
-- | else |
opcode(0x0C, "leb128_u32") -- unconditional branch
opcode(0x0D, "leb128_u32") -- conditional branch
-- | table branch |
opcode(0x0F, "none") -- return
opcode(0x10, "leb128_u32") -- call
-- | call indirect |

-- variable instructions
opcode_from_to(0x20, 0x24, "leb128_u32")

-- numeric instructions
opcode(0x41, "leb128_i32")
opcode(0x42, "leb128_i64")
opcode(0x43, "f32")
opcode(0x44, "f64")

opcode_from_to(0x45, 0x4F, "i32")
opcode_from_to(0x50, 0x5A, "i64")
opcode_from_to(0x5B, 0x60, "f32")
opcode_from_to(0x61, 0x66, "f64")
opcode_from_to(0x67, 0x78, "i32")
opcode_from_to(0x79, 0x8A, "i64")
opcode_from_to(0x8B, 0x98, "f32")
opcode_from_to(0x99, 0xA6, "f64")
opcode_from_to(0xA7, 0xAB, "i32")
opcode_from_to(0xAC, 0xB1, "i64")
opcode_from_to(0xB2, 0xB6, "f32")
opcode_from_to(0xB7, 0xBB, "f64")

opcode(0xBC, "i32")
opcode(0xBD, "i64")
opcode(0xBE, "f32")
opcode(0xBF, "f64")

opcode(0xC0, "i32")
opcode(0xC1, "i32")
opcode(0xC2, "i64")
opcode(0xC3, "i64")
opcode(0xC4, "i64")

opcode(0x6A, "none")

opcode_complex(0x08, function(self: types.WasmParser, wasm: buffer): any
    return {opcode = 0x08, operand = self:_read_leb128_u32(wasm)}
end)

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