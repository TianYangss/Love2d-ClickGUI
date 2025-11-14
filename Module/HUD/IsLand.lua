local Island = {
    messages = {},
    showTime = 2.0,
    spacing = 10,
    lineHeight = 26,
    radius = 14,
    maxMessages = 20,
    baseY = 20,
    
    currentWidth = 300,
    targetWidth = 300,
    currentHeight = 60,
    targetHeight = 60,
    animSpeed = 8,

    currentCenterY = 0,
    
    particles = {},
    

    isReady = false

}

function Island:spawnParticlesAtPoint(x, y, count)
    for i = 1, count do
        local angle = math.random() * 2 * math.pi
        local speed = 40 + math.random() * 40
        local size = 1.2 + math.random() * 1.2
        
        local p = {
            x = x, y = y,
            vx = math.cos(angle) * speed, vy = math.sin(angle) * speed,
            life = 1.0, maxLife = 0.5 + math.random() * 0.4,
            size = size, currentSize = size,
            alpha = 1.0,
            drag = 0.8 + math.random() * 0.4
        }
        table.insert(self.particles, p)
    end
end

function Island:addMessage(text)
    local msg = {
        text = text,
        timer = self.showTime,
        alpha = 0,
        scale = 0.9
    }
    table.insert(self.messages, msg)
    if #self.messages > self.maxMessages then
        table.remove(self.messages, 1)
    end
end

function Island:OnUpdate(dt)


    if not self.isReady then
        self.isReady = true
    end


    local speed = self.animSpeed * dt
    self.currentWidth = self.currentWidth + (self.targetWidth - self.currentWidth) * speed
    self.currentHeight = self.currentHeight + (self.targetHeight - self.currentHeight) * speed

    for i = #self.messages, 1, -1 do
        local msg = self.messages[i]
        
        if msg.timer > self.showTime - 0.3 then
            msg.alpha = msg.alpha + (1 - msg.alpha) * dt * 8
            msg.scale = msg.scale + (1.05 - msg.scale) * dt * 6
        elseif msg.timer < 0.3 then
            local progress = math.max(0, msg.timer / 0.3)
            local easedProgress = progress * progress
            msg.alpha = easedProgress
            msg.scale = 0.9 + (1.0 - 0.9) * easedProgress
        else
            msg.scale = msg.scale + (1.0 - msg.scale) * dt * 4
            msg.alpha = math.min(msg.alpha + dt * 4, 1)
        end

        msg.timer = msg.timer - dt
        if msg.timer <= 0 and msg.alpha < 0.05 then 
            table.remove(self.messages, i)
        end
    end
    
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.vx = p.vx * (1 - p.drag * dt)
        p.vy = p.vy * (1 - p.drag * dt)
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt / p.maxLife
        p.vy = p.vy + 100 * dt
        
        local progress = math.max(0, p.life)
        local easedProgress = progress * progress
        p.currentSize = p.size * easedProgress
        p.alpha = easedProgress
        
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function Island:OnDraw()


    if not self.isReady then
        return
    end


    if not ty or not ty.effects or not ty.effects.blurShader then return end

    local screenW, screenH = love.graphics.getDimensions()
    local font = love.graphics.getFont()
    
    local baseHeight = 60
    local msgHeight = self.lineHeight + 16
    local spacing = self.spacing
    local topOffset = 10
    local sideInset = 10

    local targetHudInstance = findModuleInstanceGlobally("targethud")
    local targetHudEnabled = ty.ModuleStates and ty.ModuleStates["hud"] and ty.ModuleStates["hud"]["targethud"]
    local showHudInIsland = targetHudEnabled and targetHudInstance and targetHudInstance.showInIsland

    local hasMessages = #self.messages > 0
    local messagesAreaHeight = 0
    if hasMessages then
        messagesAreaHeight = #self.messages * (msgHeight + spacing) - spacing + topOffset * 2
    end
    
    self.targetWidth = showHudInIsland and 420 or 300
    local hudAreaHeight = 120
    local calculatedTargetHeight = 0
    
    if showHudInIsland then
        calculatedTargetHeight = hudAreaHeight
        if hasMessages then calculatedTargetHeight = calculatedTargetHeight + messagesAreaHeight + spacing end
    elseif hasMessages then
        calculatedTargetHeight = messagesAreaHeight
    else
        calculatedTargetHeight = baseHeight
    end
    
    self.targetHeight = calculatedTargetHeight

    local x = (screenW - self.currentWidth) / 2
    local y = self.baseY
    
    love.graphics.setShader(ty.effects.blurShader)
    love.graphics.stencil(function() love.graphics.rectangle("fill", x, y, self.currentWidth, self.currentHeight, self.radius, self.radius) end, "replace", 1)
    love.graphics.setStencilTest("equal", 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ty.effects.screenCanvas, 0, 0)
    love.graphics.setStencilTest()
    love.graphics.setShader()
    
    local glowLayers = 10
    for glow = glowLayers, 1, -1 do
        local t = glow / glowLayers; local alpha = 0.05 * (1 - t)
        love.graphics.setColor(1, 1, 1, alpha); love.graphics.setLineWidth(1 + (1-t) * 2)
        love.graphics.rectangle("line", x - glow * 0.5, y - glow * 0.5, self.currentWidth + glow * 1, self.currentHeight + glow * 1, self.radius + glow * 0.5, self.radius + glow * 0.5)
    end
    love.graphics.setColor(1, 1, 1, 0.4); love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, self.currentWidth, self.currentHeight, self.radius, self.radius)

    local currentY = y

    if showHudInIsland then
        self.currentCenterY = currentY + hudAreaHeight / 2
        if targetHudInstance and targetHudInstance.DrawInIsland then
             pcall(targetHudInstance.DrawInIsland, targetHudInstance, x, currentY, self.currentWidth, hudAreaHeight)
        end
        currentY = currentY + hudAreaHeight
        if hasMessages then currentY = currentY + spacing end
    end

    if hasMessages then
        local offsetY = currentY + topOffset
        for i, msg in ipairs(self.messages) do
            local text = msg.text
            local msgX = x + sideInset
            local msgY = offsetY + (i - 1) * (msgHeight + spacing)
            local msgW = self.currentWidth - sideInset * 2
            local msgR = self.radius / 2

            love.graphics.push()
            love.graphics.translate(screenW / 2, msgY + msgHeight / 2)
            love.graphics.scale(msg.scale)
            love.graphics.translate(-screenW / 2, -(msgY + msgHeight / 2))
            
            love.graphics.setShader(ty.effects.blurShader); love.graphics.stencil(function() love.graphics.rectangle("fill", msgX, msgY, msgW, msgHeight, msgR, msgR) end, "replace", 1); love.graphics.setStencilTest("equal", 1)
            love.graphics.setColor(1, 1, 1, msg.alpha); love.graphics.draw(ty.effects.screenCanvas, 0, 0); love.graphics.setStencilTest(); love.graphics.setShader()
            love.graphics.setColor(1, 1, 1, 0.3 * msg.alpha); love.graphics.setLineWidth(1); love.graphics.rectangle("line", msgX, msgY, msgW, msgHeight, msgR, msgR)
            
            love.graphics.setColor(0, 0, 0, 0.6 * msg.alpha)
            love.graphics.printf(text, msgX + 2, msgY + 4 + 2, msgW, "center")
            love.graphics.setColor(1, 1, 1, msg.alpha)
            love.graphics.printf(text, msgX, msgY + 4, msgW, "center")
            
            local progress = math.max(0, msg.timer / self.showTime)
            if progress > 0 then
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.setLineWidth(4)
                love.graphics.setLineStyle("rough")

                local path, arc_steps = {}, 16
                local cx_tr, cy_tr=msgX+msgW-msgR,msgY+msgR; local cx_tl,cy_tl=msgX+msgR,msgY+msgR; local cx_bl,cy_bl=msgX+msgR,msgY+msgHeight-msgR; local cx_br,cy_br=msgX+msgW-msgR,msgY+msgHeight-msgR
                table.insert(path,{x=msgX+msgW/2,y=msgY}); table.insert(path,{x=cx_tr,y=msgY})
                for j=1,arc_steps do local a=math.pi*1.5+(math.pi/2)*(j/arc_steps); table.insert(path,{x=cx_tr+math.cos(a)*msgR,y=cy_tr+math.sin(a)*msgR}) end
                table.insert(path,{x=msgX+msgW,y=cy_br})
                for j=1,arc_steps do local a=0+(math.pi/2)*(j/arc_steps); table.insert(path,{x=cx_br+math.cos(a)*msgR,y=cy_br+math.sin(a)*msgR}) end
                table.insert(path,{x=cx_bl,y=msgY+msgHeight})
                for j=1,arc_steps do local a=math.pi/2+(math.pi/2)*(j/arc_steps); table.insert(path,{x=cx_bl+math.cos(a)*msgR,y=cy_bl+math.sin(a)*msgR}) end
                table.insert(path,{x=msgX,y=cy_tl})
                for j=1,arc_steps do local a=math.pi+(math.pi/2)*(j/arc_steps); table.insert(path,{x=cx_tl+math.cos(a)*msgR,y=cy_tl+math.sin(a)*msgR}) end
                table.insert(path,{x=msgX+msgW/2,y=msgY})
                
                local total_len=0; for j=1,#path-1 do local p1,p2=path[j],path[j+1]; total_len=total_len+math.sqrt((p2.x-p1.x)^2+(p2.y-p1.y)^2) end
                local prog_len=total_len*progress; local verts={}; local len_drawn=0; table.insert(verts,path[1].x); table.insert(verts,path[1].y)
                for j=1,#path-1 do
                    local p1,p2=path[j],path[j+1]; local seg_len=math.sqrt((p2.x-p1.x)^2+(p2.y-p1.y)^2)
                    if len_drawn+seg_len>=prog_len then local r=0; if seg_len>0 then r=(prog_len-len_drawn)/seg_len end; table.insert(verts,p1.x+(p2.x-p1.x)*r); table.insert(verts,p1.y+(p2.y-p1.y)*r); break else len_drawn=len_drawn+seg_len; table.insert(verts,p2.x); table.insert(verts,p2.y) end
                end
                
                if #verts>=4 then
                    love.graphics.line(verts)
                    local endpointX, endpointY = verts[#verts-1], verts[#verts]
                    if msg.timer > 0.01 and msg.timer < self.showTime - 0.01 then
                        self:spawnParticlesAtPoint(endpointX, endpointY, 2)
                    end
                end
            end
            love.graphics.pop()
        end
    end

    if not showHudInIsland and not hasMessages and #self.particles == 0 then
        local fpsLine = string.format("FPS: %d | %s", love.timer.getFPS(), os.date("%H:%M:%S"))
        local textH = font:getHeight()
        
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.printf(fpsLine, x + 2, y + (baseHeight - textH) / 2 + 2, self.currentWidth, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(fpsLine, x, y + (baseHeight - textH) / 2, self.currentWidth, "center")
    end

    love.graphics.setLineStyle("smooth")
    for _, p in ipairs(self.particles) do
        if p.alpha > 0 then
            local tail_length_factor = 0.05
            local tailX = p.x - p.vx * tail_length_factor
            local tailY = p.y - p.vy * tail_length_factor
            love.graphics.setLineWidth(p.currentSize)
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.line(tailX, tailY, p.x, p.y)
        end
    end
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

return Island

