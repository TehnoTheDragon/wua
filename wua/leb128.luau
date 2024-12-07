@native local function read_leb128(b: buffer, at_index: number): (number, number)
    local result = 0
    local shift = 0
    local cursor = 0

    while true do
        local byte = buffer.readu8(b, at_index + cursor)
        result += bit32.lshift(bit32.band(byte, 0x7F), shift)
        shift += 7
        if bit32.band(byte, 0x80) == 0 then
            break
        end
        cursor += 1
    end

    return result, cursor
end

@native local function write_leb128(b: buffer, at_index: number, value: number): (number, number)
    local result = 0
    local shift = 0
    local cursor = 0

    while true do
        local byte = buffer.readu8(b, at_index + cursor)
        result += bit32.lshift(bit32.band(byte, 0x7F), shift)
        shift += 7
        if bit32.band(byte, 0x80) == 0 then
            if shift < 32 and bit32.band(byte, 0x40) ~= 0 then
                return bit32.bor(result, bit32.lshift(bit32.bnot(0), shift)), cursor
            end
            break
        end
        cursor += 1
    end

    return result, cursor
end

return table.freeze {
    read = read_leb128,
    write = write_leb128,
}