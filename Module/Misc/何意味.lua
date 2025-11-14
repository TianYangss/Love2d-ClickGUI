local HYW = {
    enabled = false
}
UI.RegisterText("何意味", "何意味", "打开Ciallo\n关闭曼波")
function HYW:OnEnabled(dt)
    ty.log("Enable播放")
    local sound = love.audio.newSource("Assets/sound/Ciallo.mp3", "static")
    if sound then
        sound:play()
    end

    ty.ModuleStates['Misc']['HYW'] = false
end
function HYW:OnDisabled(dt)
    ty.log("Disable播放")
    local sound = love.audio.newSource("Assets/sound/ManBo.wav", "static")
    if sound then
        sound:play()
    end

    ty.ModuleStates['Misc']['HYW'] = false
end
return HYW
