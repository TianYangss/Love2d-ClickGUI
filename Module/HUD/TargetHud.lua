local TargetHUD = {
    
    showInIsland = false,
    uiInitialized = false,

    currentHealth = 20,
    maxHealth = 20,
    isAttacking = false,
    attackTimer = 0,
    attackDuration = 0.3,
    
    
    hurtTime = 0,
    maxHurtTime = 10,
    
    
    dragging = false,
    offsetX = 0,
    offsetY = 0,
    x = 0,
    y = 0,
    
    
    healthAnimation = 20,
    scaleAnimation = 1.0,
    pulseScale = 1.0,
    pulseDirection = 1,
    
    
    particles = {}
}




local headImage = nil


local function createParticles(startAngle, endAngle, centerX, centerY, radius)
    local particles = {}
    local segmentCount = 12  
    local angleStep = (endAngle - startAngle) / segmentCount
    
    for i = 1, segmentCount do
        local angle = startAngle + (i - 0.5) * angleStep
        local particle = {
            x = centerX + math.cos(angle) * radius,
            y = centerY + math.sin(angle) * radius,
            vx = math.cos(angle) * (80 + math.random() * 60),  
            vy = math.sin(angle) * (80 + math.random() * 60),
            life = 1.0,
            maxLife = 0.6 + math.random() * 0.4,  
            size = 1.5 + math.random() * 2.5,
            color = {1, 1, 1}  
        }
        table.insert(particles, particle)
    end
    
    return particles
end

function TargetHUD:GetCenter()
    if self.showInIsland and ty and ty.HUD and ty.HUD.Island and ty.HUD.Island.currentCenterY then
        local island_instance = ty.HUD.Island
        local baseRadius = 40
        local hudCircleWidth = (baseRadius + 5 + 4 + 2) * 2 
        local padding = 15
        
        local islandX = (love.graphics.getWidth() - island_instance.currentWidth) / 2
        
        return islandX + (hudCircleWidth/2) + padding, island_instance.currentCenterY
    end
    return self.x, self.y
end


function TargetHUD:OnAttack(damage)
    if not (ty.ModuleStates["hud"] and ty.ModuleStates["hud"]["targethud"]) then return end
    
    local oldHealth = self.currentHealth
    self.currentHealth = math.max(0, self.currentHealth - (damage or 7))
    
    self.hurtTime = self.maxHurtTime
    
    if self.currentHealth < oldHealth then
        local baseRadius = 40
        local healthRingWidth = 5
        local ringRadius = baseRadius + healthRingWidth/2
        
        local centerX, centerY = self:GetCenter()
        
        local oldHealthPercent = oldHealth / self.maxHealth
        local newHealthPercent = self.currentHealth / self.maxHealth
        
        local startAngle = -math.pi/2 + 2 * math.pi * newHealthPercent
        local endAngle = -math.pi/2 + 2 * math.pi * oldHealthPercent
        
        local newParticles = createParticles(startAngle, endAngle, centerX, centerY, ringRadius)
        for _, particle in ipairs(newParticles) do
            table.insert(self.particles, particle)
        end
    end
    
    self.isAttacking = true
    self.attackTimer = self.attackDuration
    
    self.pulseScale = 1.1
    self.pulseDirection = -1
    
    if self.currentHealth <= 0 then
        self.currentHealth = self.maxHealth
        self.healthAnimation = self.maxHealth
        self.hurtTime = 0  
    end
end


function TargetHUD:ResetTarget()
    self.currentHealth = self.maxHealth
    self.healthAnimation = self.maxHealth
    self.hurtTime = 0
    self.particles = {}
end


function TargetHUD:OnUpdate(dt)
    if not (ty.ModuleStates["hud"] and ty.ModuleStates["hud"]["targethud"]) then return end
    
    if self.hurtTime > 0 then
        self.hurtTime = math.max(0, self.hurtTime - dt * 20)  
    end
    
    if math.abs(self.healthAnimation - self.currentHealth) > 0.01 then
        local diff = self.currentHealth - self.healthAnimation
        self.healthAnimation = self.healthAnimation + diff * math.min(1, 8 * dt)
    else
        self.healthAnimation = self.currentHealth
    end
    
    if self.isAttacking then
        self.attackTimer = self.attackTimer - dt
        local progress = 1 - (self.attackTimer / self.attackDuration)
        
        local scaleProgress = 1 - math.pow(1 - progress, 2)
        self.scaleAnimation = 1 + 0.2 * math.sin(scaleProgress * math.pi)
        
        if self.attackTimer <= 0 then
            self.isAttacking = false
            self.scaleAnimation = 1.0
        end
    end
    
    if math.abs(self.pulseScale - 1.0) > 0.01 then
        self.pulseScale = self.pulseScale + self.pulseDirection * 4 * dt
        if self.pulseScale < 1.0 then
            self.pulseScale = 1.0
            self.pulseDirection = 1
        end
    end
    
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        particle.life = particle.life - dt / particle.maxLife
        particle.vy = particle.vy + 100 * dt
        particle.currentSize = particle.size * particle.life
        
        if particle.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function TargetHUD:_drawHudElement()
    local baseRadius = 40
    local healthRingWidth = 5
    local healthPercent = math.max(0, self.healthAnimation) / self.maxHealth
    
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setLineWidth(healthRingWidth)
    love.graphics.circle("line", 0, 0, baseRadius + healthRingWidth/2, 32)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.arc("line", "open", 0, 0, baseRadius + healthRingWidth/2, 
                     -math.pi/2, -math.pi/2 + 2 * math.pi * healthPercent, 32)
    
    if not headImage then
        if love.filesystem.getInfo("Assets/Steve.png") then
            headImage = love.graphics.newImage("Assets/Steve.png")
        end
    end
    
    if headImage then
        local headSize = baseRadius * 1.6
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(headImage, -headSize/2, -headSize/2, 0, headSize/headImage:getWidth(), headSize/headImage:getHeight())
    else
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("fill", 0, 0, baseRadius * 0.8)
    end
end


function TargetHUD:OnDraw()
    if not (ty.ModuleStates["hud"] and ty.ModuleStates["hud"]["targethud"]) then return end

    for _, particle in ipairs(self.particles) do
        local alpha = particle.life
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.currentSize or particle.size)
        
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha * 0.4)
        love.graphics.circle("fill", particle.x - particle.vx * 0.015, particle.y - particle.vy * 0.015, 
                            (particle.currentSize or particle.size) * 0.6)
    end
    
    if self.showInIsland and ty.HUD.Island then return end
    
    local totalScale = self.scaleAnimation * self.pulseScale
    
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.scale(totalScale)
    
    if self.hurtTime > 0 then
        local baseRadius = 40
        local healthRingWidth = 5
        local hurtTimeRingWidth = 4 
        local hurtTimePercent = self.hurtTime / self.maxHurtTime
        local hurtTimeRadius = baseRadius + healthRingWidth + hurtTimeRingWidth/2 + 2
        
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.setLineWidth(hurtTimeRingWidth)
        love.graphics.circle("line", 0, 0, hurtTimeRadius, 32)
        
        local r, g
        if hurtTimePercent > 0.5 then r = 1; g = (hurtTimePercent - 0.5) * 2 else r = hurtTimePercent * 2; g = 0 end
        love.graphics.setColor(r, g, 0, 0.8)
        love.graphics.arc("line", "open", 0, 0, hurtTimeRadius, -math.pi/2, -math.pi/2 + 2 * math.pi * hurtTimePercent, 32)
    end
    
    self:_drawHudElement()
    
    love.graphics.pop()
end

function TargetHUD:DrawInIsland(areaX, areaY, areaWidth, areaHeight)
    local baseRadius = 40
    local healthRingWidth = 5
    local hurtTimeRingWidth = 4
    local padding = 15

    local totalScale = 1.0 
    local hudWidth = (baseRadius + healthRingWidth + hurtTimeRingWidth + 2) * 2 * totalScale
    
    local hudDisplayX = areaX + (hudWidth/2) + padding
    local hudDisplayY = areaY + areaHeight / 2
    
    love.graphics.push()
    love.graphics.translate(hudDisplayX, hudDisplayY)
    love.graphics.scale(totalScale)
    self:_drawHudElement()
    love.graphics.pop()

    local font = love.graphics.getFont()
    local textH = font:getHeight()
    local textAreaX = areaX + hudWidth + padding * 2
    local textAreaWidth = areaWidth - hudWidth - padding * 3
    local totalTextHeight = textH * 2 + 8 
    local contentStartY = areaY + (areaHeight - totalTextHeight) / 2
    
   
    local nameText = "Name"
    local nameX = textAreaX + textAreaWidth - font:getWidth(nameText)
    local nameY = contentStartY
    
   
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.print(nameText, nameX + 2, nameY + 2)
    
   
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(nameText, nameX, nameY)

    if self.hurtTime > 0 then
        local hurtTimePercent = self.hurtTime / self.maxHurtTime
        local barY = contentStartY + textH + 2
        local barHeight = 4
        
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.rectangle("fill", textAreaX, barY, textAreaWidth, barHeight, 2)
        
        local r, g
        if hurtTimePercent > 0.5 then r = 1; g = (hurtTimePercent - 0.5) * 2 else r = hurtTimePercent * 2; g = 0 end
        love.graphics.setColor(r, g, 0, 0.8)
        love.graphics.rectangle("fill", textAreaX, barY, textAreaWidth * hurtTimePercent, barHeight, 2)
    end
    
    local healthText = string.format("%.0f/%.0f", self.healthAnimation, self.maxHealth)
    local healthX = textAreaX + textAreaWidth - font:getWidth(healthText)
    local healthY = contentStartY + textH + 8

   
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.print(healthText, healthX + 2, healthY + 2)
    
   
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(healthText, healthX, healthY)
   
end

function TargetHUD:OnMousePressed(x, y, button)
    if self.showInIsland then return false end
    if not (ty.ModuleStates["hud"] and ty.ModuleStates["hud"]["targethud"]) then return false end
    if button ~= 1 then return false end
    
    local hitRadius = 60
    
    local distance = math.sqrt((x - self.x) * (x - self.x) + (y - self.y) * (y - self.y))
    if distance <= hitRadius then
        self.dragging = true
        self.offsetX = x - self.x
        self.offsetY = y - self.y
        return true
    end
    return false
end

function TargetHUD:OnMouseMoved(x, y, dx, dy)
    if self.showInIsland then return end
    if self.dragging then
        local screenW, screenH = love.graphics.getDimensions()
        local newX = x - self.offsetX
        local newY = y - self.offsetY
        
        self.x = math.max(60, math.min(newX, screenW - 60))
        self.y = math.max(60, math.min(newY, screenH - 60))
    end
end

function TargetHUD:OnMouseReleased(x, y, button)
    if self.showInIsland then return end
    if button == 1 then 
        self.dragging = false 
    end
end

function TargetHUD:OnEnabled()
    ty.log("[TargetHUD] Module enabled")
    
    if not self.uiInitialized then
        if UI and UI.RegisterCheckbox then
            UI.RegisterCheckbox("targethud", "Show In IsLand", "showInIsland")
        end
        self.uiInitialized = true
    end

    if not ty.AttackEventReceivers then
        ty.AttackEventReceivers = {}
    end
    table.insert(ty.AttackEventReceivers, self)
    
    self:ResetTarget()
    
    local screenW, screenH = love.graphics.getDimensions()
    if self.x == 0 and self.y == 0 then
        self.x = screenW - 120
        self.y = 120
    end
    
    if love.filesystem.getInfo("Assets/Steve.png") then
        headImage = love.graphics.newImage("Assets/Steve.png")
    end
end

function TargetHUD:OnDisabled()
    ty.log("[TargetHUD] Module disabled")
    if ty.AttackEventReceivers then
        for i, receiver in ipairs(ty.AttackEventReceivers) do
            if receiver == self then
                table.remove(ty.AttackEventReceivers, i)
                break
            end
        end
    end
end

return TargetHUD