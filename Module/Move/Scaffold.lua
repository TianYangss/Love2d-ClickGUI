local Scaffold = {
    mode = 'Normal',
    placedelay = 0,
    KeepY = false,
    MoveFix = true,
}

UI.RegisterMode("Scaffold", "Mode", "mode", {"Normal", "Telly", "Snap"})
UI.RegisterCheckbox("Scaffold", "Sprint", "Sprint")
UI.RegisterSlider("Scaffold", "Place Delay", "placedelay", 0, 5, 1)
UI.RegisterCheckbox("Scaffold", "Keep Y", "KeepY")
UI.RegisterCheckbox("Scaffold", "Move Fix", "MoveFix")

function Scaffold:OnUpdate(dt)
end

return Scaffold