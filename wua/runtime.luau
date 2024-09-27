--!optimize 2
--!native
local mem = require("mem")
local stack = require("stack")
local parser = require("parser")
local nt = require("nt")

export type i32 = nt.i32
export type f32 = nt.f32
export type i64 = nt.i64
export type f64 = nt.f64

export type WasmMemory = mem.WasmMemory
export type WasmModule = parser.WasmModule
export type WasmStack = stack.WasmStack
export type Instruction = {opcode: number, operand: any}

local runtime = {}

export type WasmRuntime = {
    module: WasmModule,
    memory: WasmMemory,
    stack: WasmStack,
    pc: number,

    execute_instruction: (self: WasmRuntime, instruction: Instruction) -> (),
    interpret: (self: WasmRuntime, instructions: {Instruction}) -> (),
}

function runtime.new(module: WasmModule, memory: WasmMemory, stack: WasmStack): WasmRuntime
    return (setmetatable({
        module = module,
        memory = memory,
        stack = stack,
        pc = 1,
    }, {
        __index = runtime
    }) :: any) :: WasmRuntime
end

runtime.execute_instruction = require("instruction_executor")

function runtime:interpret(instructions: {Instruction})
    self.pc = 1
    local len = #instructions
    while self.pc <= len do
        local instruction = instructions[self.pc]
        if instruction.opcode == 0x0B then
            break
        end
        self:execute_instruction(instruction)
        self.pc += 1
    end
end

return runtime