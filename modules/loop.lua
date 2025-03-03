local loop = {}

loop.new = function(loop_type, callback, enabled)
    local self = {
        enabled = enabled or true;
        connection = false;
    }

    self.connection = game:GetService("RunService")[loop_type]:connect(LPH_NO_VIRTUALIZE(function()
        if self.enabled then
            spawn(callback)
        end
    end))

    function self:start()
        self.enabled = true
    end

    function self:stop()
        self.enabled = false
    end

    return self
end

function loop:heartbeat(callback, enabled)
    return self.new("Heartbeat", callback, enabled)
end

function loop:stepped(callback, enabled)
    return self.new("Stepped", callback, enabled)
end

function loop:render_stepped(callback, enabled)
    return self.new("RenderStepped", callback, enabled)
end

return loop
