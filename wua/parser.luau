--!optimize 2
--!native

@native local function table_insert<T>(t: {T}, v: T)
    t[if #t == 0 then 0 else #t + 1] = v
end

local parser = {}
parser._parse_expression = require("expression_parser")

export type WasmParser = {
    parse: (self: WasmParser, wasm: buffer) -> WasmModule
}

function parser.new(): WasmParser
    local self = {}
    self.cursor = 0
    self.size = 0
    return (setmetatable(self, {
        __index = parser,
    }) :: any) :: WasmParser
end

for _, datatype in {"u8", "u16", "u32", "i8", "i16", "i32", "f32", "f64"} do
    local bytesize = (tonumber(datatype:sub(2)) or 0) / 8
    assert(bytesize > 0, `invalid datatype: {datatype}`)
    parser[`_read_{datatype}`] = function(self, wasm: buffer)
        self.cursor += bytesize
        return buffer[`read{datatype}`](wasm, self.cursor - bytesize)
    end
end

function parser:_read_leb128_u32(wasm: buffer): number
    local result = 0
    local shift = 0

    while true do
        local byte = self:_read_u8(wasm)
        result += bit32.lshift(bit32.band(byte, 0x7F), shift)
        shift += 7
        if bit32.band(byte, 0x80) == 0 then
            break
        end
    end

    return result
end

function parser:_read_leb128_i32(wasm: buffer): number
    local result = 0
    local shift = 0

    while true do
        local byte = self:_read_u8(wasm)
        result += bit32.lshift(bit32.band(byte, 0x7F), shift)
        shift += 7
        if bit32.band(byte, 0x80) == 0 then
            if shift < 32 and bit32.band(byte, 0x40) ~= 0 then
                return bit32.bor(result, bit32.lshift(bit32.bnot(0), shift))
            end
            break
        end
    end

    return result
end

function parser:_read_bytes(wasm: buffer, size: number)
    self.cursor += size
    return {buffer.readstring(wasm, self.cursor-size, size):byte(1, -1)}
end


function parser:_read_string(wasm: buffer)
    local length = self:_read_leb128_u32(wasm)
    self.cursor += length
    return buffer.readstring(wasm, self.cursor-length, length)
end

function parser:_parse_limits(wasm: buffer)
    local flag = self:_read_u8(wasm)
    local min = self:_read_leb128_u32(wasm)
    local max = nil
    if bit32.band(flag, 0x01) ~= 0 then
        max = self:_read_leb128_u32(wasm)
    end
    return {min = min, max = max}
end

function parser:_parse_table_type(wasm: buffer)
    local element_type = self:_read_u8(wasm)
    local limits = self:_parse_limits(wasm)
    return {element_type = element_type, limits = limits}
end

function parser:_parse_global_type(wasm: buffer)
    local value_type = self:_read_u8(wasm)
    local mutability = self:_read_u8(wasm)
    return {value_type = value_type, mutability = mutability}
end

function parser:_parse_header(wasm: buffer)
    return { magic = self:_read_u32(wasm), version = self:_read_u32(wasm) }
end

function parser:_parse_section(wasm: buffer)
    return { id = self:_read_u8(wasm), size = self:_read_leb128_u32(wasm) }
end

function parser:_parse_custom_section(wasm: buffer, size: number)
    return self:_read_bytes(wasm, size)
end

function parser:_parse_type_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local types = {}
    for _ = 1, count do
        local form = self:_read_u8(wasm)
        assert(form == 0x60, `invalid type section form: {form} expected: 0x60`)
        local params_count = self:_read_leb128_u32(wasm)
        local params = {}
        for _ = 1, params_count do
            table_insert(params, self:_read_u8(wasm))
        end

        local results_count = self:_read_leb128_u32(wasm)
        local results = {}
        for _ = 1, results_count do
            table_insert(results, self:_read_u8(wasm))
        end

        table_insert(types, {params = params, results = results })
    end
    return types
end

function parser:_parse_import_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local imports = {}
    for _ = 1, count do
        local module = self:_read_string(wasm)
        local name = self:_read_string(wasm)
        local kind = self:_read_u8(wasm)
        
        local import = {
            module = module,
            name = name,
            kind = kind,
        }

        if kind == 0 then
            import.type_index = self:_read_leb128_u32(wasm)
        elseif kind == 1 then
            import.table_type = self:_parse_table_type(wasm)
        elseif kind == 2 then
            import.memory_type = self:_parse_limits(wasm)
        elseif kind == 3 then
            import.global_type = self:_parse_global_type(wasm)
        else
            error(`invalid import kind: {kind}`)
        end

        table_insert(imports, import)
    end
    return imports
end

function parser:_parse_function_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local functions = {}
    for _ = 1, count do
        local type_index = self:_read_leb128_u32(wasm)
        table_insert(functions, type_index)
    end
    return functions
end

function parser:_parse_table_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local tables = {}
    for _ = 1, count do
        local element_type = self:_read_u8(wasm)
        local limits = self:_parse_limits(wasm)
        table_insert(tables, {
            element_type = element_type,
            limits = limits
        })
    end
    return tables
end

function parser:_parse_memory_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local memories = {}
    for _ = 1, count do
        local limits = self:_parse_limits(wasm)
        table_insert(memories, limits)
    end
    return memories
end

function parser:_parse_global_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local globals = {}
    for _ = 1, count do
        local value_type = self:_read_u8(wasm)
        local mutability = self:_read_u8(wasm)
        local expression = self:_parse_expression(wasm)
        table_insert(globals, {value_type = value_type, mutability = mutability, expression = expression})
    end
    return globals
end

function parser:_parse_export_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local exports = {}
    for _ = 1, count do
        local name = self:_read_string(wasm)
        local kind = self:_read_u8(wasm)
        local index = self:_read_leb128_u32(wasm)
        table_insert(exports, {name = name, kind = kind, index = index})
    end
    return exports
end

function parser:_parse_start_section(wasm: buffer, size: number)
    return self:_read_leb128_u32(wasm)
end

function parser:_parse_element_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local elements = {}
    for _ = 1, count do
        local table_index = self:_read_leb128_u32(wasm)
        local offset = self:_parse_expression(wasm)

        local func_indices_count = self:_read_leb128_u32(wasm)
        local func_indices = {}
        for _ = 1, func_indices_count do
            local func_index = self:_read_leb128_u32(wasm)
            table_insert(func_indices, func_index)
        end

        table_insert(elements, {
            table_index = table_index,
            offset = offset,
            func_indices = func_indices
        })
    end
    return elements
end

function parser:_parse_code_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local codes = {}
    for _ = 1, count do
        local body_size = self:_read_leb128_u32(wasm) - 1 -- IDK, but it fixed for right now by this weird offset
        
        local local_count = self:_read_leb128_u32(wasm)
        local locals = {}
        for _ = 1, local_count do
            local local_amount = self:_read_leb128_u32(wasm)
            local local_type = self:_read_u8(wasm)
            table_insert(locals, {type = local_type, amount = local_amount})
        end

        if self.size < self.cursor + body_size then
            error(`invalid body size: {body_size} expected: {self.size - self.cursor}`)
        end
        
        local body = self:_parse_expression(wasm)
        table_insert(codes, {locals = locals, body = body})
    end
    return codes
end

function parser:_parse_data_section(wasm: buffer, size: number)
    local count = self:_read_leb128_u32(wasm)
    local data_segments = {}
    for _ = 1, count do
        local memory_index = self:_read_leb128_u32(wasm)
        local offset = self:_parse_expression(wasm)

        local data_size = self:_read_leb128_u32(wasm)
        local data = self:_read_bytes(wasm, data_size)

        table_insert(data_segments, {memory_index = memory_index, offset = offset, data = data})
    end
    return data_segments
end

function parser:_parse_module(wasm: buffer): WasmModule
    local header = self:_parse_header(wasm)
    assert(header.magic == 0x6d736100, `invalid magic: {header.magic}`)
    assert(header.version == 1, `invalid version: {header.version}`)

    local module_size = buffer.len(wasm)
    local module = {
        size = module_size,
        section = {
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
        },
    }

    local SECTION_MAP = {
        [0] = {section = "custom", parser = self._parse_custom_section},
        [1] = {section = "types", parser = self._parse_type_section},
        [2] = {section = "imports", parser = self._parse_import_section},
        [3] = {section = "functions", parser = self._parse_function_section},
        [4] = {section = "tables", parser = self._parse_table_section},
        [5] = {section = "memory", parser = self._parse_memory_section},
        [6] = {section = "globals", parser = self._parse_global_section},
        [7] = {section = "exports", parser = self._parse_export_section},
        [8] = {section = "start", parser = self._parse_start_section},
        [9] = {section = "elements", parser = self._parse_element_section},
        [10] = {section = "code", parser = self._parse_code_section},
        [11] = {section = "data", parser = self._parse_data_section},
    }
    local VISITED = {}

    while self.cursor < module_size do
        local section = self:_parse_section(wasm)
        if VISITED[section.id] then
            error(`duplicate section id: {section.id}`, 2)
        end

        local item = SECTION_MAP[section.id]
        if item then
            module.section[item.section] = item.parser(self, wasm, section.size)
            VISITED[section.id] = true
        else
            error(`unsupported section id: {section.id}`, 2)
        end
    end

    return (module :: any) :: WasmModule
end

function parser:parse(wasm: buffer): WasmModule
    self.size = buffer.len(wasm)
    self.cursor = 0
    return self:_parse_module(wasm)
end

type Instruction = {opcode: number, operand: any}
export type WasmModule = {
    size: number,
    section: {
        custom: any,
        types: {param_types: {number}, result_types: {number}},
        imports: {{
            module: string,
            name: string,
            type: string,
            type_index: number
        }},
        functions: {number},
        tables: {{
            element_type: number,
            limits: {min: number, max: number?}
        }},
        memory: {{
            limits: {min: number, max: number?}
        }},
        globals: {},
        exports: {{
            name: string,
            kind: number,
            index: number
        }},
        start: number,
        elements: {{
            table_index: number,
            offset: {Instruction},
            func_indices: {number}
        }},
        code: {{
            locals: {number},
            body: {Instruction}
        }},
        data: {{
            memory_index: number,
            offset: {Instruction},
            data: {number}
        }},
    }
}

return parser