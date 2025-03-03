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
            spawn(callback, ...)
        end
    end

    return self
end

return signal
