--!optimize 2
--!native
local types = require("types")

local stack = {}

function stack.new(max_locals: number?): types.WasmStack
    local max_locals = max_locals or 1000
    return (setmetatable({
        data = {},
        top = max_locals,
        min_top = max_locals + 1,
        top_locals = 0,
        max_locals = max_locals,
    }, {
        __index = stack
    }) :: any) :: types.WasmStack
end

function stack:push(value, locals: boolean?)
    if locals then
        if self.top_locals > self.max_locals then
            error(`stack of locals is overflowed`, 2)
        end
        self.data[self.top_locals] = value
        self.top_locals += 1
    else
        self.data[self.top] = value
        self.top += 1
    end
end

function stack:pop(locals: boolean?)
    if locals then
        if self.top_locals <= 0 then
            error(`stack of locals is underflowed`, 2)
        end
        self.top_locals -= 1
        local value = self.data[self.top_locals]
        return value
    else
        if self.top < self.min_top then
            error(`stack underflow`, 2)
        end
        self.top -= 1
        local value = self.data[self.top]
        return value
    end
end

function stack:peek(locals: boolean?)
    if locals then
        if self.top_locals == 0 then
            error(`stack of locals is empty`, 2)
        end
        return self.data[self.top_locals - 1]
    else
        if self.top < self.min_top then
            error(`stack is empty`, 2)
        end
        return self.data[self.top - 1]
    end
end

function stack:get(index: number)
    if index > self.top or index < 0 then
        error(`index out of bounds`, 2)
    end
    return self.data[index]
end

function stack:set(index: number, value)
    if index > self.top or index < 0 then
        error(`index out of bounds`, 2)
    end
    self.data[index] = value
end

function stack:clear()
    self.data = {}
    self.top = 0
    self.top_locals = 0
end

return stack