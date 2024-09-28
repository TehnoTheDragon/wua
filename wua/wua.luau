--!optimize 2
--!native
local runtime = require("runtime")
local mem = require("mem")
local stack = require("stack")
local parser = require("parser")
local types = require("types")

local wua = {}

function wua.new(wasm: buffer, memory: types.WasmMemory): types.WasmInstance
    local module = parser.new():parse(wasm)
    local stack = stack.new()

    return (setmetatable({
        runtime = runtime.new(module, memory, stack),
    }, {
        __index = wua
    }) :: any) :: types.WasmInstance
end

function wua.from_string(wasm: string, memory: types.WasmMemory): types.WasmInstance
    local b = buffer.create(#wasm)
    buffer.writestring(b, 0, wasm, #wasm)
    return wua.new(b, memory)
end

function wua.create_memory(initial_pages: number, max_pages: number): types.WasmMemory
    return mem.new(initial_pages, max_pages)
end

function wua:execute_function(func_index: number)
    local module: types.WasmModule = self.runtime.module
    local stack: types.WasmStack = self.runtime.stack

    local func = module.section.functions[func_index]
    if not func then
        error(`no function with index ({func_index}) is found`, 2)
    end

    local func_type = module.section.types[func]
    local func_body = module.section.code[func]

    print(#func_type.params, #func_body.locals)
    for i, v in func_body.locals do
        stack:push(3, true)
    end

    local bytecode = func_body.body
    self.runtime:interpret(bytecode)
end

function wua:run()
    if self.runtime.module.section.start then
        self:execute_function(self.runtime.module.section.start)
    end
end

return wua