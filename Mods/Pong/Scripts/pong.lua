-- ============================================
-- PONG Mod
-- P1: W/S  |  P2: Up/Down  |  Space: Serve
-- First to 5 wins
-- ============================================

local modId = "Pong"

-- Constants
local PADDLE_W = 20
local PADDLE_H = 100
local BALL_SIZE = 15
local PADDLE_SPEED = 400
local BALL_SPEED_INIT = 300
local BALL_SPEED_INCREMENT = 20
local PADDLE_MARGIN = 40
local DASH_W = 4
local DASH_H = 20
local DASH_GAP = 15
local DIGIT_W = 30
local DIGIT_H = 40
local WIN_SCORE = 5

-- Game state
local screenW = 0
local screenH = 0

local p1Y = 0
local p2Y = 0

local ballX = 0
local ballY = 0
local ballVX = 0
local ballVY = 0
local ballSpeed = BALL_SPEED_INIT

local score1 = 0
local score2 = 0

local serving = true      -- waiting for serve
local serveDir = 1        -- 1 = towards P2, -1 = towards P1
local matchOver = false

-- Edge detection for serve key
local prevServe = false

-- Texture IDs
local tex = {}
local texturesReady = false

-- Resolve all texture IDs from animation data
local function resolveTextures()
    if texturesReady then return true end

    tex.paddle = Animation.FrameTextureIdFrom(modId, "pongPaddle", "base", "idle", 1)
    tex.ball = Animation.FrameTextureIdFrom(modId, "pongBall", "base", "idle", 1)
    tex.dash = Animation.FrameTextureIdFrom(modId, "pongDash", "base", "idle", 1)

    tex.digits = {}
    for i = 0, 9 do
        tex.digits[i] = Animation.FrameTextureIdFrom(modId, "pongD" .. i, "base", "idle", 1)
        if not tex.digits[i] then return false end
    end

    if tex.paddle and tex.ball and tex.dash then
        texturesReady = true
        return true
    end
    return false
end

-- Draw a sprite
local function drawSprite(textureId, x, y, w, h)
    Drawing.AddRequest(
        textureId,
        {x, y},
        0, {1, 1}, nil, 0,
        w, h,
        0, 0, false, false
    )
end

-- Reset ball to center, ready for serve
local function resetBall()
    screenW = Screen.Width()
    screenH = Screen.Height()
    ballX = (screenW - BALL_SIZE) * 0.5
    ballY = (screenH - BALL_SIZE) * 0.5
    ballVX = 0
    ballVY = 0
    ballSpeed = BALL_SPEED_INIT
    serving = true
end

-- Start a new match
local function resetMatch()
    screenW = Screen.Width()
    screenH = Screen.Height()
    score1 = 0
    score2 = 0
    matchOver = false
    serveDir = 1
    p1Y = (screenH - PADDLE_H) * 0.5
    p2Y = (screenH - PADDLE_H) * 0.5
    resetBall()
    print(Localize("pong.serve"))
end

-- Serve the ball
local function serve()
    -- Slight vertical angle based on simple variation
    local angles = {-0.6, -0.3, 0.0, 0.3, 0.6}
    local pick = (score1 + score2) % #angles + 1
    local vy = angles[pick]

    ballVX = ballSpeed * serveDir
    ballVY = ballSpeed * vy
    serving = false
end

-- ============================================
-- UPDATE
-- ============================================
local function onUpdate(deltaTime, totalTime)
    screenW = Screen.Width()
    screenH = Screen.Height()

    local activeList, exists = GameData:TryGetFrom("Core", "actions.activeList")
    if not exists or not activeList then return end

    -- Serve / restart edge detection
    local serveActive = LedgerMap.TryGet(activeList, "pongServe") ~= nil
    local servePressed = serveActive and not prevServe
    prevServe = serveActive

    if matchOver then
        if servePressed then
            resetMatch()
        end
        return
    end

    -- Serve
    if serving then
        if servePressed then
            serve()
        end
        -- Still allow paddle movement while waiting to serve
    end

    -- P1 paddle movement (W/S)
    if LedgerMap.TryGet(activeList, "p1Up") then
        p1Y = p1Y - PADDLE_SPEED * deltaTime
    end
    if LedgerMap.TryGet(activeList, "p1Down") then
        p1Y = p1Y + PADDLE_SPEED * deltaTime
    end

    -- P2 paddle movement (Up/Down)
    if LedgerMap.TryGet(activeList, "p2Up") then
        p2Y = p2Y - PADDLE_SPEED * deltaTime
    end
    if LedgerMap.TryGet(activeList, "p2Down") then
        p2Y = p2Y + PADDLE_SPEED * deltaTime
    end

    -- Clamp paddles to screen
    if p1Y < 0 then p1Y = 0 end
    if p1Y > screenH - PADDLE_H then p1Y = screenH - PADDLE_H end
    if p2Y < 0 then p2Y = 0 end
    if p2Y > screenH - PADDLE_H then p2Y = screenH - PADDLE_H end

    -- Ball movement
    if not serving then
        ballX = ballX + ballVX * deltaTime
        ballY = ballY + ballVY * deltaTime

        -- Top/bottom wall bounce
        if ballY < 0 then
            ballY = 0
            ballVY = -ballVY
        elseif ballY + BALL_SIZE > screenH then
            ballY = screenH - BALL_SIZE
            ballVY = -ballVY
        end

        -- P1 paddle collision (left side)
        local p1X = PADDLE_MARGIN
        if ballVX < 0
            and ballX <= p1X + PADDLE_W
            and ballX + BALL_SIZE >= p1X
            and ballY + BALL_SIZE >= p1Y
            and ballY <= p1Y + PADDLE_H
        then
            ballX = p1X + PADDLE_W
            -- Adjust angle based on where ball hit the paddle
            local hitPos = ((ballY + BALL_SIZE * 0.5) - p1Y) / PADDLE_H -- 0 to 1
            local angle = (hitPos - 0.5) * 2.0 -- -1 to 1
            ballSpeed = ballSpeed + BALL_SPEED_INCREMENT
            ballVX = ballSpeed
            ballVY = ballSpeed * angle * 0.8
        end

        -- P2 paddle collision (right side)
        local p2X = screenW - PADDLE_MARGIN - PADDLE_W
        if ballVX > 0
            and ballX + BALL_SIZE >= p2X
            and ballX <= p2X + PADDLE_W
            and ballY + BALL_SIZE >= p2Y
            and ballY <= p2Y + PADDLE_H
        then
            ballX = p2X - BALL_SIZE
            local hitPos = ((ballY + BALL_SIZE * 0.5) - p2Y) / PADDLE_H
            local angle = (hitPos - 0.5) * 2.0
            ballSpeed = ballSpeed + BALL_SPEED_INCREMENT
            ballVX = -ballSpeed
            ballVY = ballSpeed * angle * 0.8
        end

        -- Scoring: ball passed left edge
        if ballX + BALL_SIZE < 0 then
            score2 = score2 + 1
            print(Localize("pong.point.p2"))
            print(Localize("pong.score", tostring(score1), tostring(score2)))
            if score2 >= WIN_SCORE then
                matchOver = true
                print(Localize("pong.p2wins"))
            else
                serveDir = -1 -- serve towards P1 (loser gets serve)
                resetBall()
            end
        end

        -- Scoring: ball passed right edge
        if ballX > screenW then
            score1 = score1 + 1
            print(Localize("pong.point.p1"))
            print(Localize("pong.score", tostring(score1), tostring(score2)))
            if score1 >= WIN_SCORE then
                matchOver = true
                print(Localize("pong.p1wins"))
            else
                serveDir = 1 -- serve towards P2
                resetBall()
            end
        end
    end
end

-- ============================================
-- DRAW
-- ============================================
local function onDraw()
    if not resolveTextures() then return end
    screenW = Screen.Width()
    screenH = Screen.Height()

    -- Draw center dashed line
    local dashCount = math.floor(screenH / (DASH_H + DASH_GAP))
    local centerX = (screenW - DASH_W) * 0.5
    for i = 0, dashCount - 1 do
        local dy = i * (DASH_H + DASH_GAP)
        drawSprite(tex.dash, centerX, dy, DASH_W, DASH_H)
    end

    -- Draw paddles
    local p1X = PADDLE_MARGIN
    local p2X = screenW - PADDLE_MARGIN - PADDLE_W
    drawSprite(tex.paddle, p1X, p1Y, PADDLE_W, PADDLE_H)
    drawSprite(tex.paddle, p2X, p2Y, PADDLE_W, PADDLE_H)

    -- Draw ball
    drawSprite(tex.ball, ballX, ballY, BALL_SIZE, BALL_SIZE)

    -- Draw scores
    -- P1 score: left quarter of screen
    local s1 = math.floor(score1) % 10
    drawSprite(tex.digits[s1], screenW * 0.25 - DIGIT_W * 0.5, 30, DIGIT_W, DIGIT_H)

    -- P2 score: right quarter of screen
    local s2 = math.floor(score2) % 10
    drawSprite(tex.digits[s2], screenW * 0.75 - DIGIT_W * 0.5, 30, DIGIT_W, DIGIT_H)
end

-- ============================================
-- INIT
-- ============================================
print(Localize("pong.welcome"))
print(Localize("pong.instructions"))

-- Initialize positions after a short delay (need screen dimensions)
local function onDataInit()
    screenW = Screen.Width()
    screenH = Screen.Height()
    p1Y = (screenH - PADDLE_H) * 0.5
    p2Y = (screenH - PADDLE_H) * 0.5
    resetBall()
    print(Localize("pong.serve"))
end

Events.OnDataInit.Add(onDataInit)
Events.OnUpdate.Add(onUpdate)
Events.OnDraw.Add(onDraw)
