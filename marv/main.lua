--[[
#####################################
Marvellous Inc.
Copyright (C) 2017  MarvellousSoft & USPGameDev
See full license in file LICENSE.txt
(https://github.com/MarvellousSoft/MarvInc/blob/dev/LICENSE.txt)
#####################################
]]--

-- This allows placing the library binaries next to the .love bundle on ALL platforms
-- TODO: Test if it really works
local windows = package.config:sub(1, 1) == '\\'
package.cpath = string.format("%s;%s/?.%s", package.cpath, love.filesystem.getSourceBaseDirectory(), (windows and "dll" or "so"))

--HUMP STUFF
Gamestate = require "extra_libs.hump.gamestate"
Timer     = require "extra_libs.hump.timer"
Class     = require "extra_libs.hump.class"
Camera    = require "extra_libs.hump.camera"
Vector    = require "extra_libs.hump.vector"
Signal    = require "extra_libs.hump.signal"


--OTHER EXTRA LIBS
require "extra_libs.slam"

--MY MODULES
Util      = require "util"
Draw      = require "draw"
Setup     = require "setup"

--CLASSES

require "classes.primitive"

require "classes.color.rgb"
require "classes.color.hsl"
require "classes.color.color"

But = require "classes.button"

require "classes.tabs.tab"
Mail = require "classes.tabs.email"
require "classes.tabs.code"
require "classes.tabs.info"
require "classes.tabs.manual"
require "classes.tabs.settings"
require "classes.tabs.achievements"
require "classes.tabs.puzzle_list"

require "classes.side_message"
require "classes.pc_box"
require "classes.sprite"
require "classes.sprite_object"
require "classes.object"
require "classes.obstacle"
require "classes.leaderboards"
require "classes.dead"
require "classes.bucket"
require "classes.computer"
require "classes.console"
require "classes.container"
require "classes.dead_switch"
require "classes.emitter"
BotModule = require "classes.bot"
require "classes.puzzle"
require "classes.room"
require "classes.opened_email"
WarningWindow = require "classes.warning_window"
require "classes.audio"
Color = require "classes.color.color"
FX = require "classes.fx"
StepManager = require "classes.step_manager"
LoreManager = require "classes.lore_manager"
PopManager  = require "classes.pop_manager"
SaveManager = require "save_manager"
AchManager = require "achievement_manager"
ResManager = require "res_manager"

--GAMESTATES
GS = {
MENU     = require "gamestates.menu",     --Menu Gamestate
GAME     = require "gamestates.game",     --Game Gamestate
SPLASH = require "gamestates.splash",
ACT1 = require "gamestates.act1_intro",
ACT2 = require "gamestates.act2_intro",
ACT3 = require "gamestates.act3_intro",
CUTSCENE  = require "gamestates.cutscene",
FIREPLACE = require "gamestates.fireplace",
NEWS = require "gamestates.news",
CREDITS = require "gamestates.credits",
COMP = require "gamestates.computer",
WARNINGWIN = require "gamestates.warning_window",
BLANK = require "gamestates.blank",
LEADERBOARDS = require "gamestates.leaderboards"
}

-- When game starts, automatically changes to this puzzle
START_PUZZLE = nil
-- When game starts, automatically logs in with this user
START_USER = nil
-- Whether the game shows the splash screen
SKIP_SPLASH = nil

--STEAM STUFF
-- Whether the game is running with steam (for steam integration)
USING_STEAM = false
CREATE_APPID_FILE = false
for i, cmd in ipairs(arg) do
    if cmd == "--steam" then
        USING_STEAM = true
    elseif cmd == "--steam-dev" then
        USING_STEAM = true
        CREATE_APPID_FILE = true
    end
end

if USING_STEAM then
    if CREATE_APPID_FILE then
        local file = io.open("steam_appid.txt")
        if file then
            io.close(file)
        else
            local file, err = io.open("steam_appid.txt", "w")
            if file then
                file:write("827940") -- appid
                io.close(file)
            else
                error("Failed to write steam_appid.txt (because it's needed) in cd : " .. err)
            end
        end
    end

    Steam = require "luasteam"

    if not Steam.init() then
        error("Steam is not running. Closing game.")
    end
    -- We're gonna need this anyway, let's be quick
    CAN_USE_STEAM_STATS = false
    function Steam.userStats.onUserStatsReceived(data)
        CAN_USE_STEAM_STATS = true
    end
    Steam.userStats.requestCurrentStats()
else
    Steam = setmetatable({}, { __index = function(table, name)
        error('Trying to call Steam.' .. name .. ' on a game with disabled Steam')
    end })
end

function love.load(args)
    for i, cmd in ipairs(args) do
        if cmd:sub(1, 9) == "--puzzle=" then
            print("Hello World", 400, 300)
            START_PUZZLE = cmd:sub(10)
        elseif cmd:sub(1, 7) == "--user=" then
            START_USER = cmd:sub(8)
        elseif cmd == "--no-splash" or cmd == "--skip-splash" then
            SKIP_SPLASH = true
        elseif cmd == "--custom" then
            START_PUZZLE_CUSTOM = true
        end
    end

    Setup.config() --Configure your game

    local callbacks = {'errhand', 'update'}
    for c in pairs(love.handlers) do
        if c ~= 'mousepressed' and c ~= 'mousereleased' and c ~= 'mousemoved' and c ~= 'quit' then
            table.insert(callbacks, c)
        end
    end
    -- draw, mousereleased and mousepressed are called manually
    -- mousemoved is ignored
    Gamestate.registerEvents(callbacks) --Overwrites love callbacks to call Gamestate as well

    local got_warning = SaveManager.load()
    if not got_warning then
        Gamestate.switch(SKIP_SPLASH and GS.MENU or GS.SPLASH) --Jump to the initial state
    end
end

-----------------
--MOUSE FUNCTIONS
-----------------

CUR_TIME = 0

function love.update(dt)
    CUR_TIME = CUR_TIME + dt
    if USING_STEAM then
        Steam.runCallbacks()
    end
end

function love.draw()
    ResManager.preDraw()
    Gamestate.draw()
    ResManager.postDraw()
end

function love.mousereleased(x, y, ...)
    x, y = love.mouse.getPosition() -- fixed
    Gamestate.mousereleased(x, y, ...)
end

function love.mousepressed(x, y, but, ...)
    x, y = love.mouse.getPosition() -- fixed
    Gamestate.mousepressed(x, y, but, ...)
end

function love.mousemoved(x, y, dx, dy, ...)
    x, y = love.mouse.getPosition() -- fixed
    dx, dy = dx * ResManager.scale(), dy * ResManager.scale()
    Gamestate.mousemoved(x, y, dx, dy, ...)
end

function love.resize(w, h)
    ResManager.adjustWindow(w, h)
end

local ok_state = {[GS.SPLASH] = true, [GS.GAME] = true, [GS.MENU] = true, [GS.WARNINGWIN] = true, [GS.LEADERBOARDS] = true}
local _force = false
function love.quit()
    local room = GS['GAME'].getRoom()
    if room and room.puzzle_id == 'franz1' then
        if not Mail.exists('Tread very carefully') and not LoreManager.puzzle_done.franz1 then
            Mail.new('franz1_1')
        end
    end
    if not _force and (PopManager.pop or not ok_state[Gamestate.current()] or CLOSE_LOCK)  then
        WarningWindow.show('Warning', "Are you sure you want to close the game right now? It might lead to undefined behavior.",
            {"Close the game, I like to play with fire",
                function()
                    _force = true
                    love.event.quit()
                end,
            "Do not close, I will take the safe approach", nil, enter = 1, escape = 2
            }
        )
        return true

    end
    _force = false
    if PopManager.pop then
        PopManager.pop.buttons[1].callback()
        PopManager.quit()
    end
    SaveManager.save()
    local bgmm = GS['GAME'].getBGMManager()
    if bgmm then
        bgmm.current_bgm:fadeout()
    end
    if USING_STEAM then Steam.shutdown() end
end
