local signal = {}

signal.new = function()
    local self = {
        connections = {};
    }

    function self:connect(callback)
        table.insert(self.connections, callback)
    end

    function self:fire(...)
        for _, callback in next, self.connections do
            spawn(function()
                callback(...)
            end)
        end
    end

    return self
end

return signal
