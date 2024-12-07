local types = require("types")
local leb128 = require("../leb128")
local result = require("../result")
type Self = types.WasmModuleParser

local WasmModuleParser = {}

local SECTIONS

function WasmModuleParser.new(): Self
    return setmetatable({
        cursor = 0,
        size = 0,
    }, {__index = WasmModuleParser}) :: any
end

function WasmModuleParser.u8(self: Self, bytes: types.bytes): number
    local value = buffer.readu8(bytes, self.cursor)
    self.cursor += 1
    return value
end

function WasmModuleParser.u32(self: Self, bytes: types.bytes): number
    local value = buffer.readu32(bytes, self.cursor)
    self.cursor += 4
    return value
end

function WasmModuleParser.leb128(self: Self, bytes: types.bytes): number
    local value, offset = leb128.read(bytes, self.cursor)
    self.cursor += offset
    return value
end

function WasmModuleParser.bytes(self: Self, bytes: types.bytes, size: number): {number}
    local ARRAY_SIZE = self.cursor - self.size + size
    local array = table.create(ARRAY_SIZE, 0)
    for i = 0, size - 1 do
        array[i + 1] = buffer.readu8(bytes, self.cursor + i)
    end
    self.cursor += size
    return array
end

function WasmModuleParser.string(self: Self, bytes: types.bytes): string
    local length = self:leb128(bytes)
    local value = buffer.readstring(bytes, self.cursor, length)
    self.cursor += length
    return value
end

function WasmModuleParser.parse_table_type(self: Self, bytes: types.bytes): result.Result<types.WasmTable, string>
    local element_type = self:u8(bytes)
    local limits = self:parse_limits(bytes)
    local table_: types.WasmTable = {
        type = element_type,
        limits = limits,
    }
    return result.ok(table_)
end

function WasmModuleParser.parse_global_type(self: Self, bytes: types.bytes): result.Result<types.WasmGlobal, string>
    local value_type = self:u8(bytes)
    local mutable = self:u8(bytes) == 1
    local global: types.WasmGlobal = {
        type = value_type,
        mutable = mutable,
    }
    return result.ok(global)
end

function WasmModuleParser.parse_limits(self: Self, bytes: types.bytes): result.Result<types.WasmLimits, string>
    local flag = self:u8(bytes)
    local min = self:leb128(bytes)
    local max = nil
    if bit32.band(flag, 0x01) ~= 0 then
        max = self:leb128(bytes)
    end
    local limits: types.WasmLimits = {min = min, max = max}
    return result.ok(limits)
end

function WasmModuleParser.parse_header(self: Self, bytes: types.bytes): result.Result<types.WasmHeader, string>
    local magic = self:u32(bytes)
    local version = self:u32(bytes)
    local header: types.WasmHeader = {magic = magic, version = version}
    return result.ok(header)
end

function WasmModuleParser.parse_section(self: Self, bytes: types.bytes): result.Result<types.WasmSection, string>
    local id = self:u8(bytes)
    local size = self:leb128(bytes)
    local section: types.WasmSection = {id = id, size = size}
    return result.ok(section)
end

function WasmModuleParser.parse_custom_section(self: Self, bytes: types.bytes, size: number): result.Result<types.WasmCustom, string>
    return result.ok(self:bytes(bytes, size))
end

function WasmModuleParser.parse_types_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmType}, string>
    local count = self:leb128(bytes)
    local types: {types.WasmType} = {}
    for _ = 1, count do
        local form = self:u8(bytes)
        if form ~= 0x60 then
            return result.err(`Invalid Type Section form: {form} expected: 0x60`)
        end

        local params_count = self:leb128(bytes)
        local params = {}
        for _ = 1, params_count do
            table.insert(params, self:u8(bytes))
        end

        local results_count = self:leb128(bytes)
        local results = {}
        for _ = 1, results_count do
            table.insert(results, self:u8(bytes))
        end

        local type: types.WasmType = {
            params = params,
            results = results,
        }
        table.insert(types, type)
    end
    return result.ok(types)
end

function WasmModuleParser.parse_imports_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmImport}, string>
    local count = self:leb128(bytes)
    local imports = {}
    for _ = 1, count do
        local module = self:string(bytes)
        local name = self:string(bytes)
        local type = self:u8(bytes)

        local value
        if type == 0 then
            value = self:leb128(bytes)
        elseif type == 1 then
            value = self:parse_table_type(bytes)
        elseif type == 2 then
            value = self:parse_limits(bytes)
        elseif type == 3 then
            value = self:parse_global_type(bytes)
        else
            return result.err(`Invalid import type: {type}`)
        end

        local import: types.WasmImport = {
            module = module,
            name = name,
            type = type,
            value = value,
        }

        table.insert(imports, import)
    end
    return result.ok(imports)
end

function WasmModuleParser.parse_functions_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmFunction}, string>
    local count = self:leb128(bytes)
    local functions = {}
    for _ = 1, count do
        local type_index = self:leb128(bytes)
        table.insert(functions, type_index)
    end
    return result.ok(functions)
end

function WasmModuleParser.parse_tables_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmTable}, string>
    local count = self:leb128(bytes)
    local tables = {}
    for _ = 1, count do
        local element_type = self:u8(bytes)
        local limits = self:parse_limits(bytes)
        local table_: types.WasmTable = {
            type = element_type,
            limits = limits
        }
        table.insert(tables, table_)
    end
    return result.ok(tables)
end

function WasmModuleParser.parse_memory_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmMemory}, string>
    local count = self:leb128(bytes)
    local memories = {}
    for _ = 1, count do
        local limits = self:parse_limits(bytes)
        local memory: types.WasmMemory = {
            limits = limits
        }
        table.insert(memories, memory)
    end
    return result.ok(memories)
end

function WasmModuleParser.parse_globals_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmGlobal}, string>
    local count = self:leb128(bytes)
    local globals = {}
    for _ = 1, count do
        local type = self:u8(bytes)
        local mutable = self:u8(bytes)
        local exporession = self:parse_expression(bytes)
        local global: types.WasmGlobal = {
            type = type,
            mutable = mutable,
            expression = exporession,
        }
        table.insert(globals, global)
    end
    return result.ok(globals)
end

function WasmModuleParser.parse_exports_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmExport}, string>
    local count = self:leb128(bytes)
    local exports = {}
    for _ = 1, count do
        local name = self:string(bytes)
        local type = self:u8(bytes)
        local index = self:leb128(bytes)
        local export: types.WasmExport = {
            name = name,
            type = type,
            index = index,
        }
        table.insert(exports, export)
    end
    return result.ok(exports)
end

function WasmModuleParser.parse_start_section(self: Self, bytes: types.bytes, size: number): result.Result<types.WasmStart, string>
    return result.ok(self:leb128(bytes))
end

function WasmModuleParser.parse_elements_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmElement}, string>
    local count = self:leb128(bytes)
    local elements = {}
    for _ = 1, count do
        local table_index = self:leb128(bytes)
        local offset = self:parse_expression(bytes)

        local func_indices_count = self:leb128(bytes)
        local func_indices = {}
        for _ = 1, func_indices_count do
            local func_index = self:leb128(bytes)
            table.insert(func_indices, func_index)
        end

        local element: types.WasmElement = {
            table_index = table_index,
            offset = offset,
            function_indices = func_indices,
        }
        table.insert(elements, element)
    end
    return result.ok(elements)
end

function WasmModuleParser.parse_code_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmCode}, string>
    local count = self:leb128(bytes)
    local codes = {}
    for _ = 1, count do
        local body_size = self:leb128(bytes)

        local locals_count = self:leb128(bytes)
        local locals = {}
        for _ = 1, locals_count do
            local local_count = self:leb128(bytes)
            local local_type = self:u8(bytes)
            local local_: types.WasmLocal = {
                count = local_count,
                type = local_type,
            }
            table.insert(locals, local_)
        end

        if self.size < self.cursor + body_size then
            return result.err(`Invalid body size: {body_size}, left: {self.size - self.cursor}`)
        end

        local body = self:parse_expression(bytes)
        local code: types.WasmCode = {
            locals = locals,
            body = body,
        }
        table.insert(codes, code)
    end
    return result.ok(codes)
end

function WasmModuleParser.parse_data_section(self: Self, bytes: types.bytes, size: number): result.Result<{types.WasmData}, string>
    local count = self:leb128(bytes)
    local data_segments = {}
    for _ = 1, count do
        local memory_index = self:leb128(bytes)
        local offset = self:parse_expression(bytes)

        local data_size = self:leb128(bytes)
        local data_bytes = self:bytes(bytes, data_size)

        local data: types.WasmData = {
            memory_index = memory_index,
            offset = offset,
            data = data_bytes
        }
        table.insert(data_segments, data)
    end
    return result.ok(data_segments)
end

function WasmModuleParser.parse_data_count_section(self: Self, bytes: types.bytes, size: number): result.Result<types.WasmDataCount, string>
    return result.ok(0)
end

@native function WasmModuleParser.parse_module(self: Self, bytes: types.bytes): result.Result<types.WasmModule, string>
    local header = self:parse_header(bytes):unwrap()
    if header.magic ~= 0x6d736100 then
        return result.err(`Invalid Magic: {header.magic}`)
    elseif header.version ~= 1 then
        return result.err(`Invalid Version: {header.version}; current parser supports only '1' version of binary wasm modules`)
    end
    
    local module = {
        size = self.size,
        custom = {},
        types = {},
        imports = {},
        functions = {},
        tables = {},
        memory = {},
        globals = {},
        exports = {},
        start = {},
        elements = {},
        code = {},
        data = {},
        datacount = 0,
    }
    
    local VISITED = {}
    while self.cursor < self.size do
        local section = self:parse_section(bytes)
        if section:is_err() then
            return section
        end
        section = section:unwrap()
        if VISITED[section.id] then
            return result.err(`Duplicate Section ID: {section.id}`)
        end
        
        local item = SECTIONS[section.id]
        if item then
            local value = item.parser(self, bytes)
            if value:is_err() then
                return value
            end
            value = value:unwrap()
            module[item.section] = value
            VISITED[section.id] = true
        else
            return result.err(`Invalid Section ID: {section.id}`)
        end
    end

    return result.ok(module :: any)
end

function WasmModuleParser.parse(self: Self, bytes: types.bytes): result.Result<types.WasmModule, string>
    self.cursor = 0
    self.size = buffer.len(bytes)
    return self:parse_module(bytes)
end

SECTIONS = table.freeze {
    [0]  = { section = "custom",   parser = ((WasmModuleParser :: any) :: Self).parse_custom_section},
    [1]  = { section = "types",    parser = ((WasmModuleParser :: any) :: Self).parse_types_section},
    [2]  = { section = "imports",  parser = ((WasmModuleParser :: any) :: Self).parse_imports_section},
    [3]  = { section = "functions",parser = ((WasmModuleParser :: any) :: Self).parse_functions_section},
    [4]  = { section = "tables",   parser = ((WasmModuleParser :: any) :: Self).parse_tables_section},
    [5]  = { section = "memory",   parser = ((WasmModuleParser :: any) :: Self).parse_memory_section},
    [6]  = { section = "globals",  parser = ((WasmModuleParser :: any) :: Self).parse_globals_section},
    [7]  = { section = "exports",  parser = ((WasmModuleParser :: any) :: Self).parse_exports_section},
    [8]  = { section = "start",    parser = ((WasmModuleParser :: any) :: Self).parse_start_section},
    [9]  = { section = "elements", parser = ((WasmModuleParser :: any) :: Self).parse_elements_section},
    [10] = { section = "code",     parser = ((WasmModuleParser :: any) :: Self).parse_code_section},
    [11] = { section = "data",     parser = ((WasmModuleParser :: any) :: Self).parse_data_section},
}

return table.freeze(WasmModuleParser)