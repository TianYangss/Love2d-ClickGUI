local PotionDisplay = {
    x = 10, y = 150,
    width = 0, height = 0,
    dragging = false, offsetX = 0, offsetY = 0,
    
    showBackground = true,
    showBorder = true,
    showShadow = true,
    showTimer = true,
    showInIsland = true, 
    
    effects = {}
}

UI.RegisterCheckbox("potiondisplay", "Background", "showBackground")
UI.RegisterCheckbox("potiondisplay", "Border", "showBorder")
UI.RegisterCheckbox("potiondisplay", "Shadow", "showShadow")
UI.RegisterCheckbox("potiondisplay", "Show Timer", "showTimer")
UI.RegisterCheckbox("potiondisplay", "Show in Island", "showInIsland")


function PotionDisplay:OnUpdate(dt)
    if ty and ty.ActivePotions then
        for i = #ty.ActivePotions, 1, -1 do
            local effect = ty.ActivePotions[i]
            effect.duration = effect.duration - dt
            if effect.duration <= 0 then table.remove(ty.ActivePotions, i) end
        end
    end
    local moduleIsEnabled = (ty.ModuleStates and ty.ModuleStates.hud and ty.ModuleStates.hud.potiondisplay)
    if not moduleIsEnabled then
        for _, item in ipairs(self.effects) do item.targetAlpha = 0 end
    else
        if ty and ty.ActivePotions then
            for _, globalEffect in ipairs(ty.ActivePotions) do
                local found = false
                for _, localEffect in ipairs(self.effects) do
                    if localEffect.name == globalEffect.name then
                        localEffect.duration = globalEffect.duration; localEffect.targetAlpha = 1; found = true; break
                    end
                end
                if not found then
                    table.insert(self.effects, { name = globalEffect.name, duration = globalEffect.duration, alpha = 0, targetAlpha = 1, y = #self.effects * 20, targetY = 0 })
                end
            end
        end
        for _, localEffect in ipairs(self.effects) do
            local stillActive = false
            if ty and ty.ActivePotions then
                for _, globalEffect in ipairs(ty.ActivePotions) do
                    if localEffect.name == globalEffect.name then stillActive = true; break end
                end
            end
            if not stillActive then localEffect.targetAlpha = 0 end
        end
    end
    
    local font = love.graphics.getFont()
    local lineHeight = font:getHeight()
    local visibleItemsForLayout = {}

    for _, item in ipairs(self.effects) do
        if item.alpha > 0.001 or item.targetAlpha > 0 then
            item.nameWidth = font:getWidth(item.name)
            table.insert(visibleItemsForLayout, item)
        end
    end
    
    table.sort(visibleItemsForLayout, function(a, b)
        local ad = math.floor(math.max(0, a.duration or 0))
        local bd = math.floor(math.max(0, b.duration or 0))
        if ad ~= bd then return ad > bd end
        if a.nameWidth ~= b.nameWidth then return a.nameWidth > b.nameWidth end
        return a.name < b.name
    end)

    local currentY = 0
    for _, item in ipairs(visibleItemsForLayout) do
        item.targetY = currentY
        currentY = currentY + lineHeight
    end

    local speed = 8 * dt
    for i = #self.effects, 1, -1 do
        local item = self.effects[i]
        if item.targetAlpha == 0 and item.alpha > 0.01 then item.targetY = item.y + 15 end
        item.y = item.y + (item.targetY - item.y) * speed
        item.alpha = item.alpha + (item.targetAlpha - item.alpha) * speed
        if item.targetAlpha == 0 and item.alpha < 0.01 then table.remove(self.effects, i) end
    end
end


function PotionDisplay:OnDraw()
    if #self.effects == 0 then self.width, self.height = 0, 0; return end
    if not ty or not ty.effects or not ty.effects.blurShader then return end
    
    local font = love.graphics.getFont()
    local lineHeight = font:getHeight()
    local padding = 6
    local cornerRadius = 6
    
    local visibleItemsToDraw = {}
    local maxWidth = 0
    local visibleCount = 0

    for _, item in ipairs(self.effects) do
        if item.alpha > 0.01 or item.targetAlpha > 0 then
            visibleCount = visibleCount + 1
            if item.alpha > 0.01 then
                local nameWidth = font:getWidth(item.name)
                local fullTextWidth
                if self.showTimer then
                    local dur = math.max(0, item.duration)
                    local intPart = math.floor(dur)
                    local intDigits = #tostring(intPart)
                    local digitWidth = font:getWidth("0")
                    local fracAndSuffixWidth = font:getWidth(".0s")
                    local separatorWidth = font:getWidth(" - ")
                    local timerWidthEstimate = digitWidth * intDigits + fracAndSuffixWidth
                    fullTextWidth = nameWidth + separatorWidth + timerWidthEstimate
                else
                    fullTextWidth = nameWidth
                end
                table.insert(visibleItemsToDraw, item)
                if fullTextWidth > maxWidth then maxWidth = fullTextWidth end
            end
        end
    end
    
    table.sort(visibleItemsToDraw, function(a, b) return (a.targetY or 0) < (b.targetY or 0) end)
    
    if #visibleItemsToDraw == 0 then self.width, self.height = 0, 0; return end
    
    self.width = maxWidth + padding * 2
    self.height = visibleCount * lineHeight + padding * 2
    
    local screenW, screenH = love.graphics.getDimensions()
    self.x = math.max(0, math.min(self.x, screenW - self.width))
    self.y = math.max(0, math.min(self.y, screenH - self.height))
    

    if self.showBackground then
        love.graphics.setShader(ty.effects.blurShader)
        love.graphics.stencil(function()
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, cornerRadius, cornerRadius)
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ty.effects.screenCanvas, 0, 0)
        love.graphics.setStencilTest()
        love.graphics.setShader()
    end

    if self.showBorder then
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, cornerRadius, cornerRadius)
    end

    
    local isRightSide = self.x > screenW / 2
    local isBottomSide = self.y > screenH / 2
    
    local function drawEffectLine(effect, yPos, alpha)
        local text = effect.name
        local color = {1, 1, 1}
        if self.showTimer then
            text = string.format("%s - %.1fs", effect.name, math.max(0, effect.duration))
            if effect.duration < 5 then color = {1, 0.5, 0.5} end
        end
        local drawX
        if isRightSide then
            drawX = self.x + self.width - padding - font:getWidth(text)
        else
            drawX = self.x + padding
        end
        if self.showShadow then
            love.graphics.setColor(0, 0, 0, 0.7 * alpha)
            love.graphics.print(text, drawX + 1, yPos + 1)
        end
        love.graphics.setColor(color[1], color[2], color[3], 0.9 * alpha)
        love.graphics.print(text, drawX, yPos)
    end
    
    love.graphics.setScissor(self.x, self.y, self.width, self.height)
    for _, item in ipairs(visibleItemsToDraw) do
        local drawY
        if isBottomSide then
            drawY = self.y + self.height - padding - item.y - lineHeight
        else
            drawY = self.y + padding + item.y
        end
        drawEffectLine(item, drawY, item.alpha)
    end
    love.graphics.setScissor()
end


function PotionDisplay:OnMousePressed(x, y, button)
    if not (ty.ModuleStates and ty.ModuleStates.hud and ty.ModuleStates.hud.potiondisplay) then return false end
    if button ~= 1 then return false end
    if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
        self.dragging = true; self.offsetX = x - self.x; self.offsetY = y - self.y; return true
    end
    return false
end

function PotionDisplay:OnMouseMoved(x, y)
    if self.dragging then
        local screenW, screenH = love.graphics.getDimensions()
        local newX = x - self.offsetX; local newY = y - self.offsetY
        self.x = math.max(0, math.min(newX, screenW - self.width))
        self.y = math.max(0, math.min(newY, screenH - self.height))
    end
end

function PotionDisplay:OnMouseReleased(_, _, button)
    if button == 1 then self.dragging = false end
end

return PotionDisplay