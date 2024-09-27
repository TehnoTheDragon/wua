--!optimize 2
--!native
local PAGE_SIZE = 65536

local mem = {}

function mem.new(initial_pages: number, max_pages: number): WasmMemory
    return (setmetatable({
        _memory = buffer.create((initial_pages or 1) * PAGE_SIZE),
        _current_pages = initial_pages,
        _max_pages = max_pages,
    }, {
        __index = mem
    }) :: any) :: WasmMemory
end

function mem:grow(pages: number): boolean
    if self._current_pages + pages > self._max_pages then
        return false
    end

    local old_size = buffer.len(self._memory)
    local new_size = old_size + pages * PAGE_SIZE
    local new_memory = buffer.create(new_size)
    buffer.copy(self._memory, 0, new_memory, 0, old_size)

    self._memory = new_memory
    self._current_pages += pages
    return true
end

function mem:readu8(offset: number): number
    return buffer.readu8(self._memory, offset)
end

function mem:readu32(offset: number): number
    return buffer.readu32(self._memory, offset)
end

function mem:writeu8(offset: number, value: number)
    buffer.writeu8(self._memory, offset, value)
end

function mem:writeu32(offset: number, value: number)
    buffer.writeu32(self._memory, offset, value)
end

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

return mem