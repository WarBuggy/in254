-- ============================================
-- ScorchridgeV2 — Config
-- Grid sizes, cell layout, world constants
-- ============================================

local Config = {}

-- Screen
Config.SCREEN_W = 800
Config.SCREEN_H = 600

-- HUD heights
Config.TOP_H = 48
Config.BOT_H = 64

-- Play area = SCREEN_H - TOP_H - BOT_H = 488
Config.PLAY_H = Config.SCREEN_H - Config.TOP_H - Config.BOT_H

-- Cell grid
Config.CELL_W = 128
Config.CELL_H = 80
Config.CELLS_PER_ROW = 6
Config.TOTAL_CELLS = 20
Config.ROW_COUNT = 4

-- Header bar on top of each cell
Config.HEADER_H = 16

-- Hallway (corridor in front of cells)
Config.HALLWAY_H = 20

-- Row layout: header + cells + hallway
Config.ROW_H = Config.HEADER_H + Config.CELL_H + Config.HALLWAY_H

-- Gap between rows
Config.ROW_GAP = 4

-- Control room sits at the start of row 1
Config.CONTROL_ROOM_W = 128

-- Staircase connects rows
Config.STAIRCASE_W = 64

-- World width: control room + staircase + 6 cells
Config.WORLD_W = Config.CONTROL_ROOM_W + Config.STAIRCASE_W + Config.CELLS_PER_ROW * Config.CELL_W

-- Player
Config.PLAYER_SPEED = 200
Config.PLAYER_W = 16
Config.PLAYER_H = 24
Config.PLAYER_SCALE = 2

-- Interaction range (pixels from player center to cell center)
Config.INTERACT_RANGE = 80

-- Cell furniture offsets within a cell (relative to cell body top-left)
Config.FURNITURE = {
    terminal = { x = 8,  y = 4,  w = 16, h = 24 },
    table    = { x = 76, y = 4,  w = 24, h = 16 },
    bed      = { x = 8,  y = 52, w = 32, h = 16 },
    toilet   = { x = 84, y = 52, w = 16, h = 16 },
    inmate   = { x = 44, y = 30 },
}

return Config
