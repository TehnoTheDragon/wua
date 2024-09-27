--!optimize 2
--!native
local stack = {}

function stack.new(): WasmStack
    return (setmetatable({
        data = {},
        top = 0
    }, {
        __index = stack
    }) :: any) :: WasmStack
end

function stack:push(value: number)
    self.top += 1
    self.data[self.top] = value
end

function stack:pop(): number
    if self.top == 0 then
        error(`stack underflow`, 2)
    end
    self.top -= 1
    return self.data[self.top + 1]
end

function stack:peek(): number
    if self.top == 0 then
        error(`stack is empty`, 2)
    end
    return self.data[self.top]
end

function stack:read(index: number): number
    if index > self.top then
        error(`index out of bounds`, 2)
    elseif index < 0 then
        error(`negative index`, 2)
    end
    return self.data[index]
end

function stack:clear()
    self.data = {}
    self.top = 0
end

export type WasmStack = {
    data: {number},
    top: number,

    push: (self: WasmStack, value: number) -> (),
    pop: (self: WasmStack) -> number,
    peek: (self: WasmStack) -> number,
    clear: (self: WasmStack) -> (),
}

return stack