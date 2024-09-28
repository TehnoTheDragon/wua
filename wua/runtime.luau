--!optimize 2
--!native
local nt = require("nt")
local types = require("types")

local runtime = {}

function runtime.new(module: types.WasmModule, memory: types.WasmMemory, stack: types.WasmStack): types.WasmRuntime
    local globals = {}
    for index, item in module.section.globals do
        globals[index] = {value = 0, mutable = item.mutability}
    end
    return (setmetatable({
        module = module,
        memory = memory,
        stack = stack,
        globals = globals,
        pc = 1,
    }, {
        __index = runtime
    }) :: any) :: types.WasmRuntime
end

runtime.execute_instruction = require("instruction_executor")

function runtime:interpret(instructions: {types.Instruction})
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