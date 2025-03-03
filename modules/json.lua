local json = {}

function json:encode(...)
    return game:GetService("HttpService"):JSONEncode(...)
end

function json:decode(...)
    return game:GetService("HttpService"):JSONDecode(...)
end

return json
