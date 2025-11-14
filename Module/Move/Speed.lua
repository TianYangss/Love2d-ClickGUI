local Speed = {
    mode = 'Vlucan'
}

UI.RegisterMode("Speed", "Mode", "mode", {
    "Vulcan", "Custom", "Grim",'Matrix','Intave','WatchDog','AAC','NCP','UNCP'
})


function Speed:OnUpdate(dt)
end

return Speed