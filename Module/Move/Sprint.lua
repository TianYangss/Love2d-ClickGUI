local Sprint = {
    mode = 'Legit'
}

UI.RegisterMode("Sprint", "Mode", "mode", {"Legit", "Vanilla", "Grim"})

UI.RegisterCheckbox("Sprint", "Omni", "omni")

function Sprint:OnUpdate(dt)
end

return Sprint