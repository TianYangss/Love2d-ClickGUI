local Keystrokes = {

    x = 30, y = 40,
    width = 0, height = 0,
    dragging = false, offsetX = 0, offsetY = 0,

    ShowType = "Key",
    ShowSpace = true,
    ShowMouse = true,
    RainbowEffect = false,
    
    keys = {
        W = {pressed = false, alpha = 0},
        A = {pressed = false, alpha = 0},
        S = {pressed = false, alpha = 0},
        D = {pressed = false, alpha = 0},
        LMB = {pressed = false, alpha = 0},
        RMB = {pressed = false, alpha = 0},
        SPACE = {pressed = false, alpha = 0}
    },
    
    keyPositions = {
        W = {x = 60, y = 0, width = 60, height = 60},
        A = {x = 0, y = 60, width = 60, height = 60},
        S = {x = 60, y = 60, width = 60, height = 60},
        D = {x = 120, y = 60, width = 60, height = 60},
        LMB = {x = 0, y = 120, width = 90, height = 50},
        RMB = {x = 90, y = 120, width = 90, height = 50},
        SPACE = {x = 0, y = 170, width = 180, height = 40}
    },
    
    fadeSpeed = 3,
    rainbowTimer = 0
}

UI.RegisterMode("keystrokes", "ShowTypes", "ShowType", {"Key", "Arrow"})
UI.RegisterCheckbox("keystrokes", "Space", "ShowSpace")
UI.RegisterCheckbox("keystrokes", "Mouse", "ShowMouse")
UI.RegisterCheckbox("keystrokes", "Rainbow", "RainbowEffect")

function Keystrokes:OnUpdate(dt)
    if self.RainbowEffect then
        self.rainbowTimer = (self.rainbowTimer + dt) % (2 * math.pi)
    end
    
    for key, state in pairs(self.keys) do
        local targetAlpha = state.pressed and 1 or 0
        state.alpha = state.alpha + (targetAlpha - state.alpha) * self.fadeSpeed * dt
    end
end

function Keystrokes:OnDraw()
    if not (ty.ModuleStates and ty.ModuleStates.hud and ty.ModuleStates.hud.keystrokes) then return end
    if not ty or not ty.effects or not ty.effects.blurShader then return end

    local r, g, b, a = love.graphics.getColor()
    local cornerRadius = 6
    

    local maxX, maxY = 0, 0
    for key, pos in pairs(self.keyPositions) do
        local shouldDraw = true
        if (key == "LMB" or key == "RMB") and not self.ShowMouse then shouldDraw = false end
        if key == "SPACE" and not self.ShowSpace then shouldDraw = false end
        
        if shouldDraw then
            if pos.x + pos.width > maxX then maxX = pos.x + pos.width end
            if pos.y + pos.height > maxY then maxY = pos.y + pos.height end
        end
    end

    if not self.ShowSpace and self.ShowMouse then
        maxY = self.keyPositions.LMB.y + self.keyPositions.LMB.height

    elseif not self.ShowSpace and not self.ShowMouse then
        maxY = self.keyPositions.A.y + self.keyPositions.A.height
    end
    
    self.width = maxX
    self.height = maxY
    

    local screenW, screenH = love.graphics.getDimensions()
    self.x = math.max(0, math.min(self.x, screenW - self.width))
    self.y = math.max(0, math.min(self.y, screenH - self.height))

    

    love.graphics.setShader(ty.effects.blurShader)
    love.graphics.stencil(function()
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, cornerRadius, cornerRadius)
    end, "replace", 1)
    love.graphics.setStencilTest("equal", 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ty.effects.screenCanvas, 0, 0)
    love.graphics.setStencilTest()
    love.graphics.setShader()
    
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, cornerRadius, cornerRadius)


    local pressedColor = {1.0, 1.0, 1.0, 0.8}
    local unpressedColor = {1.0, 1.0, 1.0, 0.3}
    local borderColor = {1.0, 1.0, 1.0, 0.6}
    local textColor = {1.0, 1.0, 1.0, 1.0}
    
    local rainbowColor = self:getRainbowColor(0)
    
    self:drawKey("W", self:getKeyText("W"), pressedColor, unpressedColor, borderColor, textColor, rainbowColor)
    self:drawKey("A", self:getKeyText("A"), pressedColor, unpressedColor, borderColor, textColor, rainbowColor)
    self:drawKey("S", self:getKeyText("S"), pressedColor, unpressedColor, borderColor, textColor, rainbowColor)
    self:drawKey("D", self:getKeyText("D"), pressedColor, unpressedColor, borderColor, textColor, rainbowColor)
    
    if self.ShowMouse then
        self:drawKey("LMB", self:getKeyText("LMB"), pressedColor, unpressedColor, borderColor, textColor, rainbowColor)
        self:drawKey("RMB", self:getKeyText("RMB"), pressedColor, unpressedColor, borderColor, textColor, rainbowColor)
    end
    
    if self.ShowSpace then
        self:drawKey("SPACE", self:getKeyText("SPACE"), pressedColor, unpressedColor, borderColor, textColor, rainbowColor)
    end
    
    love.graphics.setColor(r, g, b, a)
end

function Keystrokes:getKeyText(key)
    if self.ShowType == "Arrow" then
        local arrowMap = {W = "↑", A = "←", S = "↓", D = "→", SPACE = "SPACE", LMB = "LMB", RMB = "RMB"}
        return arrowMap[key] or key
    else
        return key
    end
end

function Keystrokes:getRainbowColor(offset)
    if not self.RainbowEffect then return {1.0, 1.0, 1.0} end
    local time = self.rainbowTimer + offset
    local r = (math.sin(time) + 1) / 2
    local g = (math.sin(time + 2 * math.pi / 3) + 1) / 2
    local b = (math.sin(time + 4 * math.pi / 3) + 1) / 2
    return {r, g, b}
end

function Keystrokes:drawKey(key, text, pressedColor, unpressedColor, borderColor, textColor, rainbowColor)
    local pos = self.keyPositions[key]
    if not pos then return end
    
    local state = self.keys[key]
    if not state then return end
    
    local currentAlpha = state.alpha
    local currentFillColor = {rainbowColor[1], rainbowColor[2], rainbowColor[3], pressedColor[4] * currentAlpha}
    

    love.graphics.setColor(currentFillColor)
    love.graphics.rectangle("fill", self.x + pos.x, self.y + pos.y, pos.width, pos.height, 6, 6)
    

    love.graphics.setColor(rainbowColor[1], rainbowColor[2], rainbowColor[3], borderColor[4])
    love.graphics.rectangle("line", self.x + pos.x, self.y + pos.y, pos.width, pos.height, 6, 6)
    

    local textAlpha = 0.4 + currentAlpha * 0.6
    love.graphics.setColor(textColor[1], textColor[2], textColor[3], textAlpha)
    
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, self.x + pos.x + (pos.width - textWidth) / 2, self.y + pos.y + (pos.height - textHeight) / 2)
end

function Keystrokes:OnKeyPressed(key)
    if key == "w" then self.keys.W.pressed = true
    elseif key == "a" then self.keys.A.pressed = true
    elseif key == "s" then self.keys.S.pressed = true
    elseif key == "d" then self.keys.D.pressed = true
    elseif key == "space" then self.keys.SPACE.pressed = true
    end
end

function Keystrokes:OnKeyReleased(key)
    if key == "w" then self.keys.W.pressed = false
    elseif key == "a" then self.keys.A.pressed = false
    elseif key == "s" then self.keys.S.pressed = false
    elseif key == "d" then self.keys.D.pressed = false
    elseif key == "space" then self.keys.SPACE.pressed = false
    end
end

function Keystrokes:OnMousePressed(x, y, button)

    if not (ty.ModuleStates and ty.ModuleStates.hud and ty.ModuleStates.hud.keystrokes) then return false end
    if button ~= 1 then return false end
    if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
        self.dragging = true; self.offsetX = x - self.x; self.offsetY = y - self.y; return true
    end
    

    if button == 1 then self.keys.LMB.pressed = true
    elseif button == 2 then self.keys.RMB.pressed = true
    end
    return false
end

function Keystrokes:OnMouseReleased(x, y, button)

    if button == 1 then self.dragging = false end


    if button == 1 then self.keys.LMB.pressed = false
    elseif button == 2 then self.keys.RMB.pressed = false
    end
end

function Keystrokes:OnMouseMoved(x, y, dx, dy)
    if self.dragging then
        local screenW, screenH = love.graphics.getDimensions()
        local newX = x - self.offsetX; local newY = y - self.offsetY
        self.x = math.max(0, math.min(newX, screenW - self.width))
        self.y = math.max(0, math.min(newY, screenH - self.height))
    end
end

return Keystrokes