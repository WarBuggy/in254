Events.OnDataInit = {
    Add = function(fn)
        Events.Register("OnDataInit", fn)
    end
}

Events.OnAnimationCreated = {
    Add = function(fn)
        Events.Register("OnAnimationCreated", fn)
    end
}

Events.OnDraw = {
    Add = function(fn) 
        Events.Register("OnDraw", fn) 
    end
}

Events.OnUpdate = {
    Add = function(fn) 
        Events.Register("OnUpdate", fn) 
    end
}

Events.OnDefinitionCreated = {
    Add = function(fn)
        Events.Register("OnDefinitionCreated", fn)
    end
}

function CreateEvent()
    return {
        _handlers = {},

        Add = function(self, fn)
            table.insert(self._handlers, fn)
        end,

        Remove = function(self, fn)
            for i, h in ipairs(self._handlers) do
                if h == fn then
                    table.remove(self._handlers, i)
                    return
                end
            end
        end,

        Fire = function(self, ...)
            for _, fn in ipairs(self._handlers) do
                fn(...)
            end
        end
    }
end