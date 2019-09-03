function love.conf(t)
    t.identity = "Puyo_Chains"
    t.modules.joystick = false
    t.modules.physics = false
    t.window.title = "Puyo Machine"
    t.window.resizable = true
    math.randomseed(os.time())
    local rand = math.random(5)
    if rand == 1 then
        t.window.icon = "puyos/red.png"
    elseif rand == 2 then
        t.window.icon = "puyos/green.png"
    elseif rand == 3 then
        t.window.icon = "puyos/blue.png"
    elseif rand == 4 then
        t.window.icon = "puyos/yellow.png"
    else
        t.window.icon = "puyos/purple.png"
    end
end