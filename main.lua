local grid = require "grid_functions"
local play_mode = require "play_mode"

local utf8 = require("utf8")
local bitser = require 'bitser'
print(bitser)

GRID_SIZE = nil
PUYOS = {
    red = love.graphics.newImage("puyos/red.png"),
    green = love.graphics.newImage("puyos/green.png"),
    blue = love.graphics.newImage("puyos/blue.png"),
    purple = love.graphics.newImage("puyos/purple.png"),
    yellow = love.graphics.newImage("puyos/yellow.png"),
    iron = love.graphics.newImage("puyos/iron.png"),
    garbage = love.graphics.newImage("puyos/garbage.png"),
    block = love.graphics.newImage("puyos/block.png")
}
PUYO_ENUM = {
    blank = nil,
    red = 1,
    green = 2,
    blue = 3,
    yellow = 4,
    purple = 5,
    garbage = 6,
    iron = 7,
    block = 8
}
REV_PUYO_ENUM = {
    "red",
    "green",
    "blue",
    "yellow",
    "purple",
    "garbage",
    "iron",
    "block"
}
FPSCAP = 60

grid_scale = nil
mouse_pos = nil

state = nil
drawables = nil
selected_puyo = nil

prev_mouse_down = nil
font = nil
small_font = nil
save_name = ""
load_name = ""
dir_table = nil

function init ()
    font = love.graphics.newFont("Inconsolita.ttf", 32)
    small_font = love.graphics.newFont("Inconsolita.ttf", 16)
    prev_mouse_down = true
    GRID_SIZE = {x = 10, y = 10}
    grid_scale = 1
    drawables = {}
    state = "edit" -- or "play"
    grid.new_grid()
    local _x, _y = love.mouse.getPosition()
    mouse_pos = {x = _x, y = _y}
    selected_puyo = 1
end

function love.load()
    init()
    play_mode.init()
end

function love.update(dt)
    if state == "edit" then
        edit_update(dt)
    elseif state == "play" then
        play_update(dt)
    end

    sleep(dt)
end

function love.draw()
    if state == "save" then
        love.graphics.setFont(font)
        love.graphics.print("File Name:", 10, 10)
        love.graphics.print(save_name, 10, 50)
    elseif state == "load" then
        love.graphics.setFont(font)
        local wrap_index = nil
        local y =  nil
        local x = nil
        local mouse_x, mouse_y = love.mouse.getPosition()
        local mouse_wrap = mouse_x > math.floor(love.graphics.getWidth() / 2) + 10
        local mouse_y_index = math.floor((mouse_y - 10) / 32) + 1
        local mouse_index = nil
        
        for i, filename in ipairs(dir_table) do
            mouse_index = nil
            if wrap_index then
                x = math.floor(love.graphics.getWidth() / 2 + 10)
                y = 32 * (i - 1 - wrap_index) + 10
                if mouse_wrap and i - wrap_index == mouse_y_index then
                    love.graphics.setColor(1, 0, 0)
                    mouse_index = i
                end
            else
                x = 10
                y = 32 * (i - 1) + 10
                if y + 64 > love.graphics.getHeight() then wrap_index = i end
                if not mouse_wrap and i == mouse_y_index then
                    love.graphics.setColor(1, 0, 0)
                    mouse_index = i
                end
            end

            love.graphics.print(filename, x, y)
            love.graphics.setColor(1, 1, 1)
            
            if (love.mouse.isDown(1) and mouse_index) then load_file(dir_table[mouse_index]) end
        end
        
    else
        for i, column in pairs(grid.grid()) do
            for j, tile_int in pairs(column) do
                love.graphics.draw(PUYOS[REV_PUYO_ENUM[tile_int]], i * 32 - 32, j * 32 - 32)
            end
        end
        if state == "edit" and not love.mouse.isDown(2) then
            love.graphics.draw(PUYOS[REV_PUYO_ENUM[selected_puyo]], mouse_pos.x, mouse_pos.y)
        end
    end
    love.graphics.setFont(small_font)
    love.graphics.print(state, 0, love.graphics.getHeight() - 16)
end


function edit_update(dt)
    local x, y = love.mouse.getPosition()
    mouse_pos.x = round_nearest_multiple(x, 32)
    mouse_pos.y = round_nearest_multiple(y, 32)

    if love.mouse.isDown(1) then
        grid.set(mouse_pos.x / 32 + 1, mouse_pos.y / 32 + 1, selected_puyo)
    elseif love.mouse.isDown(2) then
        grid.remove(mouse_pos.x / 32 + 1, mouse_pos.y / 32 + 1)
    end
end


function love.textinput(t)
    if state == "save" and no_input == false then
        save_name = save_name .. t
    end
    no_input = false
end

function play_update(dt)
    play_mode.update(dt)
end

function love.keypressed(key, scancode, isrepeat)
    if state == "save" then
        if scancode == "escape" then
            state = "edit"
        elseif key == "backspace" then
            local byteoffset = utf8.offset(save_name, -1)

            if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
                save_name = string.sub(save_name, 1, byteoffset - 1)
            end
        elseif key == "return" then
            save_file()
            state = "edit"
        end
    else
        selected_puyo = tonumber(scancode) or selected_puyo
        if scancode == "space" then
            if state ~= "play" then
                state = "play"
                grid.backup()
                play.init_play = true
            end
        elseif scancode == "escape" then
            if state ~= "edit" then
                play.exit()
                state = "edit"
            end
        elseif key == "s" and state ~= "play" then
            play.exit()
            state = "save"
            no_input = true
        elseif key == "l" then
            if state ~= "load" then
                play.exit()
                state = "load"
                dir_table = love.filesystem.getDirectoryItems("")
                local i = 1
                while true do
                    if dir_table[i] == nil then break end
                    if not string.find(dir_table[i], ".puyo") then
                        table.remove(dir_table, i)
                    else
                        i = i + 1
                    end
                end
            end
        elseif key == "f" then
            love.window.setFullscreen(not love.window.getFullscreen())
        end
    end
end

function save_file ()
    bitser.dumpLoveFile(save_name .. ".puyo", {grid.size(), grid.min_size(), grid.grid()})
end

function load_file (filename)
    local size, min_size, new_grid = unpack(bitser.loadLoveFile(filename))
    grid.set_grid(new_grid)
    grid.set_size(size)
    grid.set_min_size(min_size)
    state = "edit"
end

function sleep(dt)
    local s = 1/FPSCAP - dt
    if s > 0 then love.timer.sleep(s) end
end

function round_nearest_multiple (num, mult)
    return mult*math.floor(num/mult)
end