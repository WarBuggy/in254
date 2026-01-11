local function draw(anim)
    if anim == nil then
        print("Animation not found: " .. animationName)
        return
    end

    -- Get base component and its default state
    local baseComponent = anim.components[anim.baseComponent]
    if not baseComponent then
        print("Base component not found: " .. anim.baseComponent)
        return
    end

    local baseState = baseComponent.states[baseComponent.defaultState]
    if not baseState or #baseState.frames == 0 then
        print("Base component default state invalid: " .. baseComponent.defaultState)
        return
    end

    local baseFrame = baseState.frames[1] -- draw first frame only for now

    -- Calculate base component position at screen center
    local centerX = Screen.GetScreenWidth() / 2
    local centerY = Screen.GetScreenHeight() / 2
    local basePosX = centerX - (baseFrame.width / 2)
    local basePosY = centerY - (baseFrame.height / 2)

    -- Base origin: top-left of the base frame minus its internal sprite offset
    local originX = basePosX - baseFrame.offsetX
    local originY = basePosY - baseFrame.offsetY

    -- Loop through all components
    for _, comp in pairs(anim.components) do
        local state = comp.states[comp.defaultState]
        if state and #state.frames > 0 then
            local frame = state.frames[1]

            -- Calculate screen position relative to base component
            local posX = originX + frame.offsetX
            local posY = originY + frame.offsetY

            Drawing.AddRequest(
                frame.textureId,
                {posX, posY},
                0,                 -- rotation
                {1,1},             -- scale
                nil,               -- color
                0,                 -- layerDepth
                frame.width,
                frame.height,
                frame.offsetX,
                frame.offsetY
            )
        end
    end
end

local function drawAnimation(animationName)
    local anim = Animation.getAnimation(animationName)
    draw(anim)
end

local function drawAnimationFrom(modId, animationName)
    local anim = Animation.getAnimationFrom(modId, animationName)
    draw(anim)
end

local function drawPlayIdle()
    drawAnimation("player") 
end


Events.OnDraw.Add(drawPlayIdle)