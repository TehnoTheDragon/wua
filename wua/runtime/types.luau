type Result<T, E> = {
    unwrap: (Result<T, E>) -> T?,
    is_err: (Result<T, E>) -> boolean,
    is_ok: (Result<T, E>) -> boolean,
}

export type bytes = buffer

export type WasmLimits = {min: number, max: number?}
export type WasmSection = {id: number, size: number}
export type WasmHeader = {magic: number, version: number}
export type WasmInstruction = {opc: number, opr: any}
export type WasmExpression = {WasmInstruction}
export type WasmLocal = {type: number, count: number}

export type WasmCustom = any
export type WasmType = {params: {number}, results: {number}}
export type WasmImport = {
    module: string,
    name: string,
    type: number,
    value: number
         | WasmTable
         | WasmLimits
         | WasmGlobal
}
export type WasmFunction = number
export type WasmTable = {type: number, limits: WasmLimits}
export type WasmMemory = {limits: WasmLimits}
export type WasmGlobal = {
    type: number,
    mutable: boolean,
    expression: any,
}
export type WasmExport = {
    name: string,
    type: number,
    index: number,
}
export type WasmStart = number
export type WasmElement = {
    table_index: number,
    offset: WasmExpression,
    function_indices: {number}
}
export type WasmCode = {
    locals: {WasmLocal},
    body: WasmExpression
}
export type WasmData = {
    memory_index: number,
    offset: WasmExpression,
    data: {number}
}
export type WasmDataCount = number

export type WasmModuleParser = {
    cursor: number,
    size: number,

    u8: (WasmModuleParser, bytes) -> number,
    u32: (WasmModuleParser, bytes) -> number,
    leb128: (WasmModuleParser, bytes) -> number,
    bytes: (WasmModuleParser, bytes, size: number) -> {number},
    string: (WasmModuleParser, bytes) -> string,

    parse_expression: (WasmModuleParser, bytes) -> Result<WasmExpression, string>,
    parse_table_type: (WasmModuleParser, bytes) -> Result<WasmTable, string>,
    parse_global_type: (WasmModuleParser, bytes) -> Result<WasmGlobal, string>,
    parse_limits: (WasmModuleParser, bytes) -> Result<WasmLimits, string>,
    parse_header: (WasmModuleParser, bytes) -> Result<WasmHeader, string>,
    parse_custom_section: (WasmModuleParser, bytes, size: number) -> Result<WasmCustom, string>,
    parse_types_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmType}, string>,
    parse_imports_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmImport}, string>,
    parse_functions_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmFunction}, string>,
    parse_tables_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmTable}, string>,
    parse_memory_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmMemory}, string>,
    parse_globals_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmGlobal}, string>,
    parse_exports_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmExport}, string>,
    parse_start_section: (WasmModuleParser, bytes, size: number) -> Result<WasmStart, string>,
    parse_elements_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmElement}, string>,
    parse_code_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmCode}, string>,
    parse_data_section: (WasmModuleParser, bytes, size: number) -> Result<{WasmData}, string>,

    parse_section: (WasmModuleParser, bytes) -> Result<WasmSection, string>,
    parse_module: (WasmModuleParser, bytes) -> Result<WasmModule, string>,
    parse: (WasmModuleParser, bytes) -> Result<WasmModule, string>,
}
export type WasmModule = {
    size: number,
    custom: WasmCustom,
    types: {WasmType},
    imports: {WasmImport},
    functions: {WasmFunction},
    tables: {WasmTable},
    memory: {WasmMemory},
    globals: {WasmGlobal},
    exports: {WasmExport},
    start: WasmStart,
    elements: {WasmElement},
    code: {WasmCode},
    data: {WasmData},
    datacount: WasmDataCount,
}
return table.freeze {}