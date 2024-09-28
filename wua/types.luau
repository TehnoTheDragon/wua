local nt = require("nt")

export type i32 = nt.i32
export type f32 = nt.f32
export type i64 = nt.i64
export type f64 = nt.f64

export type ValueType = "none"
    | "u8" | "i8"
    | "u32" | "i32"
    | "u64" | "i64"
    | "f32" | "f64"
    | "leb128_u32" | "leb128_i32"
    | "leb128_u64" | "leb128_i64"
    | "vec128" | "funcref" | "externref" | "func"

export type Instruction = {opcode: number, operand: any}
export type Limits = {min: number, max: number?}

export type TypeSectionItem = {params: {number}, results: {number}}
export type ImportSectionItem = {module: string, name: string, kind: number, value: number | TableSectionItem | Limits | GlobalSectionItem}
export type FunctionSectionItem = number
export type TableSectionItem = {element_type: number, limits: Limits}
export type MemorySectionItem = {limits: Limits}
export type GlobalSectionItem = {value_type: number, mutability: boolean}
export type ExportSectionItem = {name: string, kind: number, index: number}
export type StartSectionItem = number
export type ElementSectionItem = {table_index: number, offset: {Instruction}, func_indices: {number}}
export type CodeSectionItem = {locals: {number}, body: {Instruction}}
export type DataSectionItem = {memory_index: number, offset: {Instruction}, data: {number}}
export type DatacountSectionItem = number

export type WasmModule = {
    size: number,
    section: {
        custom: any,
        types: {TypeSectionItem},
        imports: {ImportSectionItem},
        functions: {FunctionSectionItem},
        tables: {TableSectionItem},
        memory: {MemorySectionItem},
        globals: {GlobalSectionItem},
        exports: {ExportSectionItem},
        start: StartSectionItem,
        elements: {ElementSectionItem},
        code: {CodeSectionItem},
        data: {DataSectionItem},
        datacount: DatacountSectionItem,
    }
}
export type WasmParser = {
    parse: (self: WasmParser, wasm: buffer) -> WasmModule
}
export type WasmMemory = {
    _memory: buffer,
    _current_pages: number,
    _max_pages: number,

    grow: (self: WasmMemory, pages: number) -> boolean,
    readu8: (self: WasmMemory, offset: number) -> number,
    readu32: (self: WasmMemory, offset: number) -> number,
    writeu8: (self: WasmMemory, offset: number, value: number) -> (),
    writeu32: (self: WasmMemory, offset: number, value: number) -> (),
}
export type WasmStack = {
    data: {any},
    top: number,
    min_top: number,
    top_locals: number,
    max_locals: number,

    push: <T>(self: WasmStack, value: T, locals: boolean?) -> (),
    pop: <T>(self: WasmStack, locals: boolean?) -> T,
    peek: <T>(self: WasmStack, locals: boolean?) -> T,
    get: <T>(self: WasmStack, index: number) -> T,
    set: <T>(self: WasmStack, index: number, value: T) -> (),
    clear: (self: WasmStack) -> (),
}
export type WasmRuntime = {
    module: WasmModule,
    memory: WasmMemory,
    stack: WasmStack,
    globals: {[any]: {value: any, mutable: boolean}},
    pc: number,

    execute_instruction: (self: WasmRuntime, instruction: Instruction) -> (),
    interpret: (self: WasmRuntime, instructions: {Instruction}) -> (),
}
export type WasmInstance = {
    runtime: WasmRuntime,

    execute_function: (self: WasmInstance, func_index: number) -> (),
    run: (self: WasmInstance) -> (),
}

local types = {}

local VALUE_TYPE_TO_WASM_TYPE = {
    u8 = 0x7F,
    i8 = 0x7F,
    u32 = 0x7F,
    i32 = 0x7F,
    u64 = 0x7E,
    i64 = 0x7E,
    f32 = 0x7D,
    f64 = 0x7C,
    vec128 = 0x7B,
    funcref = 0x70,
    externref = 0x6F,
    func = 0x60,
}
function types.value_type_to_wasm_type(valueType: ValueType): number
    return VALUE_TYPE_TO_WASM_TYPE[valueType]
end

return table.freeze(types)