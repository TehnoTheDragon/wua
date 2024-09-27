--!optimize 2
local nt = {}

@native function nt.i32(i32: number): i32
    local self = {value = bit32.band(math.ceil(i32), 0xffff_ffff)}
    local meta = {}
    function meta:__tostring(): string
        return self.value
    end
    function meta:__add(x: i32): i32
        return nt.i32(self.value + x.value)
    end
    function meta:__sub(x: i32): i32
        return nt.i32(self.value - x.value)
    end
    function meta:__mul(x: i32): i32
        return nt.i32(self.value * x.value)
    end
    function meta:__div(x: i32): i32
        return nt.i32(self.value / x.value)
    end
    function meta:__mod(x: i32): i32
        return nt.i32(self.value % x.value)
    end
    function meta:__pow(x: i32): i32
        return nt.i32(self.value ^ x.value)
    end
    function meta:__unm(): i32
        return nt.i32(-self.value)
    end
    function meta:__lt(x: i32): boolean
        return self.value < x.value
    end
    function meta:__le(x: i32): boolean
        return self.value <= x.value
    end
    function meta:__eq(x: i32): boolean
        return self.value == x.value
    end

    function self:band(x: i32): i32
        return nt.i32(bit32.band(self.value, x.value))
    end

    function self:bor(x: i32): i32
        return nt.i32(bit32.bor(self.value, x.value))
    end

    function self:bxor(x: i32): i32
        return nt.i32(bit32.bxor(self.value, x.value))
    end

    function self:bnot(): i32
        return nt.i32(bit32.bnot(self.value))
    end

    function self:shl(x: i32): i32
        return nt.i32(bit32.lshift(self.value, x.value))
    end

    function self:shr(x: i32): i32
        return nt.i32(bit32.rshift(self.value, x.value))
    end

    function self:rrot(x: i32): i32
        return nt.i32(bit32.rrotate(self.value, x.value))
    end

    function self:lrot(x: i32): i32
        return nt.i32(bit32.lrotate(self.value, x.value))
    end

    return setmetatable(self, meta)
end

@native function nt.f32(x: number): f32
    local self = {value = x}
    local meta = {}
    function meta:__tostring(): string
        return self.value
    end
    function meta:__add(x: f32): f32
        return nt.f32(self.value + x.value)
    end
    function meta:__sub(x: f32): f32
        return nt.f32(self.value - x.value)
    end
    function meta:__mul(x: f32): f32
        return nt.f32(self.value * x.value)
    end
    function meta:__div(x: f32): f32
        return nt.f32(self.value / x.value)
    end
    function meta:__mod(x: f32): f32
        return nt.f32(self.value % x.value)
    end
    function meta:__pow(x: f32): f32
        return nt.f32(self.value ^ x.value)
    end
    function meta:__unm(): f32
        return nt.f32(-self.value)
    end
    function meta:__lt(x: f32): boolean
        return self.value < x.value
    end
    function meta:__le(x: f32): boolean
        return self.value <= x.value
    end
    function meta:__eq(x: f32): boolean
        return self.value == x.value
    end

    return setmetatable(self, meta)
end

@native function nt.i64(high: number, low: number): i64
    local self = {value = {high = bit32.band(math.ceil(high), 0xffff_ffff), low = bit32.band(math.ceil(low), 0xffff_ffff)}}
    local meta = {}
    function meta:__tostring()
        local h = self.value.high
        local l = self.value.low
        
        if h < 0 then
            h += 0x100000000
        end

        return h * 0x100000000 + l
    end

    function meta:__add(x: i64): i64
        local low = bit32.band(self.value.low + x.value.low, 0xffffffff)
        local carry = bit32.band(self.value.low + x.value.low, 0x100000000)
        local high = bit32.band(self.value.high + x.value.high + carry, 0xffffffff)
        return nt.i64(high, low)
    end

    function meta:__sub(x: i64): i64
        local low = bit32.band(self.value.low - x.value.low, 0xffffffff)
        local carry = if bit32.band(self.value.low - x.value.low, 2 ^ 31) == 0 then 1 else 0
        local high = bit32.band(self.value.high - x.value.high - carry, 0xffffffff)
        return nt.i64(high, low)
    end

    function meta:__mul(x: i64): i64
        local low = bit32.band(self.value.low * x.value.low, 0xffffffff)
        local carry = if bit32.band(self.value.low * x.value.low, 2 ^ 31) == 0 then 1 else 0
        local high = bit32.band(self.value.high * x.value.high + carry, 0xffffffff)
        return nt.i64(high, low)
    end

    function meta:__div(x: i64): i64
        local low = bit32.band(self.value.low / x.value.low, 0xffffffff)
        local carry = if bit32.band(self.value.low / x.value.low, 2 ^ 31) == 0 then 1 else 0
        local high = bit32.band(self.value.high / x.value.high + carry, 0xffffffff)
        return nt.i64(high, low)
    end

    function meta:__mod(x: i64): i64
        local low = bit32.band(self.value.low % x.value.low, 0xffffffff)
        local carry = if bit32.band(self.value.low % x.value.low, 2 ^ 31) == 0 then 1 else 0
        local high = bit32.band(self.value.high % x.value.high + carry, 0xffffffff)
        return nt.i64(high, low)
    end

    function meta:__pow(x: i64): i64
        local low = bit32.band(self.value.low ^ x.value.low, 0xffffffff)
        local carry = if bit32.band(self.value.low ^ x.value.low, 2 ^ 31) == 0 then 1 else 0
        local high = bit32.band(self.value.high ^ x.value.high + carry, 0xffffffff)
        return nt.i64(high, low)
    end

    function meta:__unm(): i64
        return nt.i64(-self.value.high, -self.value.low)
    end

    function meta:__lt(x: i64)
        return self.value.high < x.value.high or (self.value.high == x.value.high and self.value.low < x.value.low)
    end

    function meta:__le(x: i64)
        return self.value.high < x.value.high or (self.value.high == x.value.high and self.value.low <= x.value.low)
    end

    return setmetatable(self, meta)
end

@native function nt.f64(x: number): f64
    local self = {value = x}
    local meta = {}

    function meta:__tostring(): string
        return self.value
    end
    function meta:__add(x: f64): f64
        return nt.f64(self.value + x.value)
    end
    function meta:__sub(x: f64): f64
        return nt.f64(self.value - x.value)
    end
    function meta:__mul(x: f64): f64
        return nt.f64(self.value * x.value)
    end
    function meta:__div(x: f64): f64
        return nt.f64(self.value / x.value)
    end
    function meta:__mod(x: f64): f64
        return nt.f64(self.value % x.value)
    end
    function meta:__pow(x: f64): f64
        return nt.f64(self.value ^ x.value)
    end
    function meta:__unm(): f64
        return nt.f64(-self.value)
    end
    function meta:__lt(x: f64): boolean
        return self.value < x.value
    end
    function meta:__le(x: f64): boolean
        return self.value <= x.value
    end
    function meta:__eq(x: f64): boolean
        return self.value == x.value
    end

    return setmetatable(self, meta)
end

export type i32 = typeof(nt.i32(0))
export type f32 = typeof(nt.f32(0))
export type i64 = typeof(nt.i64(0, 0))
export type f64 = typeof(nt.f64(0))

return nt