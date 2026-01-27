-- Draws a single frame of an animation using the new flat API
local function draw(animationName, modId)
    local mod = modId or "" -- if modId is nil, use current mod context

    -- Get base component name
    local baseCompName
    if mod ~= "" then
        baseCompName = Animation.BaseComponentFor(mod, animationName)
    else
        baseCompName = Animation.BaseComponent(animationName)
    end

    if type(baseCompName) ~= "string" or baseCompName == "" then
        print("Base component not found: " .. animationName)
        return
    end

    -- Get components list
    local components
    if mod ~= "" then
        components = Animation.ComponentsFor(mod, animationName)
    else
        components = Animation.Components(animationName)
    end

    if type(components) ~= "table" or #components == 0 then
        print("No components for animation: " .. animationName)
        return
    end

    -- Get base component default state
    local baseStateName
    if mod ~= "" then
        baseStateName = Animation.DefaultStateFor(mod, animationName, baseCompName)
    else
        baseStateName = Animation.DefaultState(animationName, baseCompName)
    end

    if type(baseStateName) ~= "string" or baseStateName == "" then
        print("Base component default state invalid: " .. baseCompName)
        return
    end

    -- Get first frame of base component
    local baseFrame = Animation.Frame(animationName, baseCompName, baseStateName, 1)
    if type(baseFrame) ~= "table" then
        print("Base component frame missing: " .. baseCompName .. " / " .. baseStateName)
        return
    end

    -- Center position
    local centerX = Screen.GetScreenWidth() / 2
    local centerY = Screen.GetScreenHeight() / 2
    local basePosX = centerX - (baseFrame.Width / 2)
    local basePosY = centerY - (baseFrame.Height / 2)

    -- Origin top-left for component alignment
    local originX = basePosX - baseFrame.OffsetX
    local originY = basePosY - baseFrame.OffsetY

    -- Loop through all components
    for i = 1, #components do
        local compName = components[i]

        -- Get component default state
        local stateName
        if mod ~= "" then
            stateName = Animation.DefaultStateFor(mod, animationName, compName)
        else
            stateName = Animation.DefaultState(animationName, compName)
        end

        if type(stateName) == "string" and stateName ~= "" then
            local frame 
            if mod ~= "" then
                frame = Animation.FrameFor(mod, animationName, compName, stateName, 1)
            else
                frame = Animation.Frame(animationName, compName, stateName, 1)
            end
           
            if type(frame) == "table" then
                local posX = originX + frame.OffsetX
                local posY = originY + frame.OffsetY

                Drawing.AddRequest(
                    frame.TextureId,
                    {posX, posY},
                    0,            -- rotation
                    {1, 1},       -- scale
                    nil,          -- color
                    0,            -- layerDepth
                    frame.Width,
                    frame.Height,
                    frame.OffsetX,
                    frame.OffsetY
                )
            end
        end
    end
end

-- Convenience functions
local function drawAnimation(animationName)
    draw(animationName)
end

local function drawAnimationFrom(modId, animationName)
    draw(animationName, modId)
end

local function drawPlayIdle()
    drawAnimation("player")
end

Events.OnDraw.Add(drawPlayIdle)
