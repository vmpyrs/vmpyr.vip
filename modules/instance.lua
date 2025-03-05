local instance = {}

instance.new = function(class_name, properties, parent)
    local self = {}
    self.instance = Instance.new(class_name)

    function self:tween(goal, play, wait_until, tween_info)
        tween_info = tween_info or TweenInfo.new(0.4)
        local tween = game:GetService("TweenService"):Create(self.instance, tween_info, goal)
        if play then
            tween:Play()
        end
        if wait_until then
            wait(tween_info.Time + 0.2)
        end
        return tween
    end

    function self:destroy()
        if self.instance then
            self.instance:Destroy()
            self.instance = nil
        end
    end

    function self:child(child_class, child_properties)
        return instance.new(child_class, child_properties, self.instance)
    end

    setmetatable(self, {
        __index = function(tbl, key)
            if key == "instance" then
                return rawget(tbl, "instance")
            else
                return tbl.instance[key]
            end
        end;
        
        __newindex = function(tbl, key, value)
            tbl.instance[key] = value
        end;
    })
    
    if parent then
        self.instance.Parent = parent
    end

    if properties then
        for key, value in next, properties do
            self[key] = value
        end
    end

    return self
end

return instance
