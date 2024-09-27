SCRIPT = """--!optimize 2
local w = {V}
return function()
    local b = buffer.create({L})
    buffer.writestring(b, 0, w, {L})
    return b
end"""

with open("dummy.wasm", "rb") as f:
    bytecode = f.read()

with open("dummy.luau", "w") as f:
    wasm = "\""
    for b in bytecode:
        wasm += "\\x{0:02x}".format(b)
    wasm += "\""
    f.write(SCRIPT.format(V=wasm, L=len(bytecode)))