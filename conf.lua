---@diagnostic disable: undefined-global
function love.conf(t)
    t.window.width = 1270
    t.window.height = 720
    t.window.resizable = true
     t.window.msaa = 8
    t.identity = "CGUI"
    t.console = true
    t.window.title = "八宝粥行动"
    t.window.icon = "Assets/SJZ_icon.png"
end
