local ClickGUI = {
    blur = true,
    blurAmount = 1.5
}
UI.RegisterCheckbox("ClickGUI", "Enable Blur", "blur")
UI.RegisterSlider("ClickGUI", "Blur Amount", "blurAmount", 0, 5, 0.1)
return ClickGUI