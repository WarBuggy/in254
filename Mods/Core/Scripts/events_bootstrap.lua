Events.OnDraw = {
    Add = function(fn) Events.Register("OnDraw", fn) end
}

Events.OnDefinitionCreated = {
    Add = function(fn)
        Events.Register("OnDefinitionCreated", fn)
    end
}