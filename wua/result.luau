export type Result<T, E> = {
    unwrap: (Result<T, E>) -> T?,
    is_err: (Result<T, E>) -> boolean,
    is_ok: (Result<T, E>) -> boolean,
}

local Ok_ = {}
function Ok_:unwrap()
    return self[1]
end

function Ok_:is_err()
    return false
end

function Ok_:is_ok()
    return true
end

local Err_ = {}

function Err_:unwrap()
    error(self[1], 2)
end

function Err_:is_err()
    return true
end

function Err_:is_ok()
    return false
end

local Result_ = {}

function Result_.ok<T, E>(value: T): Result<T, E>
    return setmetatable({value}, {__index = Ok_}) :: any
end

function Result_.err<T, E>(err: E): Result<T, E>
    return setmetatable({err}, {__index = Err_}) :: any
end

return table.freeze(Result_)