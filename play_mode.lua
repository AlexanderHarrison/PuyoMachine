local grid = require "grid_functions"
local play_mode = nil

play = {}

local columns_changed = nil
local timer_start = nil

local pc -- puyo count
local cp -- chain power
local cb -- chain bonus
local gb -- group bonus



play.init = function ()
    play.delay = 0.5 --seconds
end

play.score = nil

play.init_play = false

play.update = function (dt)

    --first update of play mode
    if play.init_play then
        play.score = 0
        play.init_play = false
        play_mode = "fall"
        --set columns_changed to all columns
        columns_changed = {}
        for i=grid.min_size().x, grid.size().x do columns_changed[#columns_changed + 1] = i end
        timer_start = love.timer.getTime()
    end

    if timer_start + play.delay < love.timer.getTime() then
        timer_start = love.timer.getTime()


        if play_mode == "fall" then
            play.fall()
            play_mode = "pop"
            new_canvas()
        elseif play_mode == "pop" then
            if play.pop() then
                play_mode = "fall"
                new_canvas()
            else
                play_mode = "end"
            end
        else
            --end of chain, do nothing
        end
    end

end

play.fall = function ()
    --could be optimized by using pairs() and finding difference in index instead of checking for nil values
    for _, x in pairs(columns_changed) do
        local fall_spaces = 0
        local cur_column = grid.column(x)
        for y = grid.size().y, grid.min_size().y, -1 do
            local puyo_num = grid.get(x, y)
            if puyo_num == nil then
                fall_spaces = fall_spaces + 1
            elseif REV_PUYO_ENUM[puyo_num] == "block" then
                fall_spaces = 0
            elseif fall_spaces > 0 then -- if puyo falls
                cur_column[y + fall_spaces] = cur_column[y]
                cur_column[y] = nil
            end
        end
    end
end

play.pop = function ()
    local puyos_to_remove = play.retest_for_chain(columns_changed)
    if next(puyos_to_remove) == nil then return nil end
    columns_changed = play.remove_puyos(puyos_to_remove)
    return true
end


play.test_for_chain = function (puyo_pos)
    local check_puyo_num = grid.get(puyo_pos.x, puyo_pos.y)
    local connecting_puyos = {}
    local connecting_puyos_len = 0 -- does not count garbage
    local puyos_to_check = {}
    puyos_to_check[puyo_pos] = true

    -- puyos whose adjacent spaces have not been checked tosee if they can join the string of puyos
    local puyos_unadjecented = {}
    local puyos_unadjecented_len = 0
    
    --group_bonus = 0
    while true do
        
        for puyo, _ in pairs(puyos_to_check) do
            if check_puyo_num == grid.get(puyo.x, puyo.y) then
                if not puyo_in_table(connecting_puyos, puyo) then
                    connecting_puyos[puyo] = true
                    connecting_puyos_len = connecting_puyos_len + 1
                    puyos_unadjecented[puyo] = true
                    puyos_unadjecented_len = puyos_unadjecented_len + 1
                end
            elseif REV_PUYO_ENUM[grid.get(puyo.x, puyo.y)] == "garbage" then
                if not puyo_in_table(connecting_puyos, puyo) then
                    connecting_puyos[puyo] = true
                end
            end
        end
        
        puyos_to_check = {}
        
        if puyos_unadjecented_len == 0 then
            break
        end
    
        for puyo, _ in pairs(puyos_unadjecented) do
            if puyo.x ~= grid.size().x then
                puyos_to_check[{x = puyo.x + 1, y = puyo.y}] = true end
            if puyo.x ~= grid.min_size().x then
                puyos_to_check[{x = puyo.x - 1, y = puyo.y}] = true end
            if puyo.y ~= grid.size().y then
                puyos_to_check[{x = puyo.x, y = puyo.y + 1}] = true end
            if puyo.y ~= grid.min_size().y then
                puyos_to_check[{x = puyo.x, y = puyo.y - 1}] = true end
        end
        
        puyos_unadjecented = {}
        puyos_unadjecented_len = 0
    end
    
    --if len(connecting_puyos) > 4:
    --    group_bonus = group_bonus_table[len(connecting_puyos) - 4]
    
    return connecting_puyos, connecting_puyos_len --, group_bonus #list of puyos the same color as input puyo and touching, as well as group bonus
end

play.retest_for_chain = function (columns)
    --columns is a list of ints for columns to check
    local removing_puyos = {}
    --group_bonus = 0
    --group_bonus_addition = 0
    for _, x in pairs(columns) do
        for y, puyo_num in pairs(grid.column(x)) do
            local puyo = {x = x, y = y}
            if is_puyo(puyo_num) and not puyo_in_table(removing_puyos, puyo) then
                --connecting_puyos, group_bonus_addition = test_for_chain([c, s])
                local connecting_puyos, connecting_puyos_len = play.test_for_chain(puyo)
                --group_bonus += group_bonus_addition
                if connecting_puyos_len >= 4 then
                    for puyo, _ in pairs(connecting_puyos) do
                        removing_puyos[puyo] = true
                    end
                end
            end
        end
    end
    return removing_puyos--, group_bonus
end

play.remove_puyos = function (puyos_to_remove)
    local columns_removed_from = {}
    --local colors = {}

    for puyo, _ in pairs(puyos_to_remove) do --gets columns and adds them to list, while setting the puyos to 9
        if not int_in_table(columns_removed_from, puyo.x) then
            columns_removed_from[#columns_removed_from + 1] = puyo.x
        end
        
        --if internal_puyo_table[puyo_pos[0]][puyo_pos[1]] not in colors:
        --    colors.append(internal_puyo_table[puyo_pos[0]][puyo_pos[1]])
        grid.remove(puyo.x, puyo.y)
    end
    
    return columns_removed_from--, len(colors)
end

play.exit = function ()
    if state == "play" then
        state = "edit"
        grid.restore()
    end
end

function puyo_in_table (parent, puyo)
    for key_puyo, _ in pairs(parent) do
        if key_puyo.x == puyo.x and key_puyo.y == puyo.y then 
            return true 
        end
    end
    return nil
end

function int_in_table (table, int)
    for _, v in ipairs(table) do
        if v == int then return true end
    end
    return nil
end

function is_puyo (num)
    return num == PUYO_ENUM.red or 
           num == PUYO_ENUM.green or 
           num == PUYO_ENUM.blue or 
           num == PUYO_ENUM.yellow or 
           num == PUYO_ENUM.purple
end

function chain_power (chain_num)
    if chain_num == 1 then
        return 0
    elseif chain_num == 2 then
        return 8
    elseif chain_num == 3 then
        return 16
    else
        return (chain_num - 3) * 32
    end
end

function color_bonus (color_count)
    return 3 * (color_count - 1)
end

function group_bonus (puyo_count)
    if puyo_count == 4 then
        return 0
    elseif puyo_count < 11 then
        return puyo_count - 3
    else
        return 10
    end
end

return play