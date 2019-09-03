local gf = {}

local grid
--size never reduces. it is a rectange that only grows as elements are added
local size
local min_size
local backup_grid

gf.grid = function () return grid end

gf.get = function (x, y)
    if grid[x] == nil then return nil end
    return grid[x][y]
end

gf.set_grid = function (new_grid)
    grid = new_grid
end

gf.set_size = function (new_size)
    size = new_size
end

gf.set_min_size = function (new_min_size)
    min_size = new_min_size
end

gf.size = function () return size end
gf.min_size = function () return min_size end

gf.new_grid = function ()
    grid = {}
    size = {x = 0, y = 0}
    min_size = {x = nil, y = nil}
end

gf.set = function (x, y, value)
    assert(value ~= nil, "use remove() to set value to nil")
    
    if grid[x] == nil then
        grid[x] = {}
    end
    grid[x][y] = value

    if min_size.x == nil then
        min_size.x = x
    else
        min_size.x = math.min(x, min_size.x)
    end

    if min_size.y == nil then
        min_size.y = y
    else
        min_size.y = math.min(y, min_size.y)
    end

    size.x = math.max(x, size.x)
    size.y = math.max(y, size.y)
end

gf.remove = function (x, y)
    if grid[x] ~= nil then
        grid[x][y] = nil
        if next(grid[x]) == nil then grid[x] = nil end
    end
end

-- start inclusive
-- stop inclusive
gf.range_x = function (y, start, stop)
    local range = {}

    for i=0, stop - start do
        range[i+1] = grid[i + start][y]
    end

    return range
end

-- start inclusive
-- stop inclusive
gf.range_y = function (x, start, stop)
    return {unpack(grid[x], start, stop)}
end

gf.column = function (x)
    return grid[x] or {}
end

gf.row = function (y)
    print("grid.row not implemented yet")
    return nil
end

gf.print = function (type, n)
    if type == "column" then
        print(unpack(grid[n]))
    elseif type == "row" then
        for i=1, size.x do
            print(grid[i][n])
        end
    elseif type == "full" then
        for i=1, size.x do
            print(unpack(grid[i]))
        end
    else
        error ("column, row, or full")
    end
end

gf.backup = function ()
    backup_grid = {}
    for x, column in pairs(grid) do
        if column ~= nil then
            backup_grid[x] = {}
            for y, value in pairs(column) do
                backup_grid[x][y] = value
            end
        else
            backup_grid[x] = nil
        end
    end
end

gf.restore = function ()
    grid = backup_grid
end
            


return gf