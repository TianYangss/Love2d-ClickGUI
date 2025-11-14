local ModuleList = {
    x = 10, y = 10,
    width = 0, height = 0,
    dragging = false, offsetX = 0, offsetY = 0,
    
    suffix = false,
    showBackground = true, -- 选项保留，但效果已变为玻璃
    showBorder = true,
    showShadow = true,
    
    animationStyle = "Up",
    
    items = {}
}

UI.RegisterMode("modulelist", "Module Animation", "animationStyle", { "Up", "Down" })
UI.RegisterCheckbox("modulelist", "Suffix", "suffix")
UI.RegisterCheckbox("modulelist", "Background", "showBackground")
UI.RegisterCheckbox("modulelist", "Border", "showBorder")
UI.RegisterCheckbox("modulelist", "Shadow", "showShadow")

local function findModuleInstanceGlobally(moduleName)
    if not ty or not ty.ModulesByCategory or not moduleName then return nil end
    for _, category_modules in pairs(ty.ModulesByCategory) do
        for _, mod in ipairs(category_modules) do
            if mod.name == moduleName then return mod.instance end
        end
    end
    return nil
end

local function getModuleMode(moduleName, shouldShowSuffix)
    if not shouldShowSuffix then return nil end
    local moduleInstance = findModuleInstanceGlobally(moduleName)
    if not moduleInstance or not UI.Components[moduleName] then return nil end
    for _, comp in ipairs(UI.Components[moduleName]) do
        if comp.type == "mode" and moduleInstance[comp.key] then
            return moduleInstance[comp.key]
        end
    end
    return nil
end

function ModuleList:OnUpdate(dt)
    local moduleListIsEnabled = (ty.ModuleStates and ty.ModuleStates.hud and ty.ModuleStates.hud.modulelist)
    local font = love.graphics.getFont()
    local lineHeight = font:getHeight()

    if not moduleListIsEnabled then
        for _, item in ipairs(self.items) do
            item.targetAlpha = 0
        end
    else
        local currentEnabledModules = {}
        if ty and ty.ModuleStates then
            for category, modules in pairs(ty.ModuleStates) do
                if category ~= "hud" then
                    for name, enabled in pairs(modules) do
                        if enabled and name ~= "modulelist" then
                            currentEnabledModules[name] = true
                        end
                    end
                end
            end
        end
        
        for name, _ in pairs(currentEnabledModules) do
            local found = false
            for _, item in ipairs(self.items) do
                if item.name == name then
                    found = true
                    item.targetAlpha = 1
                    item.suffix = getModuleMode(name, self.suffix)
                    break
                end
            end
            if not found then
                local displayName = name:sub(1, 1):upper() .. name:sub(2)
                local initialY
                if self.animationStyle == "Down" then
                    initialY = -lineHeight
                else
                    local futureVisibleCount = 1
                    for _, existingItem in ipairs(self.items) do
                        if existingItem.targetAlpha > 0 then
                            futureVisibleCount = futureVisibleCount + 1
                        end
                    end
                    initialY = futureVisibleCount * lineHeight
                end

                table.insert(self.items, {
                    name = name,
                    displayName = displayName,
                    suffix = getModuleMode(name, self.suffix),
                    alpha = 0,
                    targetAlpha = 1,
                    y = initialY,
                    targetY = initialY,
                })
            end
        end

        for _, item in ipairs(self.items) do
            if not currentEnabledModules[item.name] then
                item.targetAlpha = 0
            end
        end
    end

    local visibleItems = {}
    for _, item in ipairs(self.items) do
        if item.alpha > 0.001 or item.targetAlpha > 0 then
            local fullText = item.displayName .. (item.suffix and (" " .. item.suffix) or "")
            item.textWidth = font:getWidth(fullText)
            table.insert(visibleItems, item)
        end
    end
    
    table.sort(visibleItems, function(a, b) return a.textWidth > b.textWidth end)

    local currentY = 0
    for i, item in ipairs(visibleItems) do
        item.targetY = currentY
        currentY = currentY + lineHeight
    end

    local speed = 8 * dt
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        
        if item.targetAlpha == 0 and item.alpha > 0 then
            if self.animationStyle == "Down" then
                item.targetY = item.y - 15
            else
                item.targetY = item.y + 15
            end
        end

        item.y = item.y + (item.targetY - item.y) * speed
        item.alpha = item.alpha + (item.targetAlpha - item.alpha) * speed

        if item.targetAlpha == 0 and item.alpha < 0.01 then
            table.remove(self.items, i)
        end
    end
end


function ModuleList:OnDraw()
    if #self.items == 0 then self.width, self.height = 0, 0; return end
    if not ty or not ty.effects or not ty.effects.blurShader then return end

    local font = love.graphics.getFont()
    local lineHeight = font:getHeight()
    local padding = 6
    local cornerRadius = 6

    local visibleItems = {}
    local maxWidth = 0
    local visibleCount = 0
    for _, item in ipairs(self.items) do
        if item.alpha > 0.01 or item.targetAlpha > 0 then
            visibleCount = visibleCount + 1
            if item.alpha > 0.01 then
                table.insert(visibleItems, item)
                if item.textWidth and item.textWidth > maxWidth then
                    maxWidth = item.textWidth
                end
            end
        end
    end
    
    if #visibleItems == 0 then self.width, self.height = 0, 0; return end
    
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

    local function drawLine(mod, y, alpha)
        local name_w = font:getWidth(mod.displayName)
        local name_x, suffix_x
        
        if isRightSide then
            suffix_x = self.x + self.width - padding - (mod.suffix and font:getWidth(mod.suffix) or 0)
            name_x = suffix_x - (mod.suffix and font:getWidth(" ") or 0) - name_w
        else
            name_x = self.x + padding
            suffix_x = name_x + name_w + (mod.suffix and font:getWidth(" ") or 0)
        end

        if self.showShadow then
            love.graphics.setColor(0, 0, 0, 0.7 * alpha)
            love.graphics.print(mod.displayName, name_x + 1, y + 1)
            if mod.suffix then love.graphics.print(mod.suffix, suffix_x + 1, y + 1) end
        end

        love.graphics.setColor(1, 1, 1, 0.9 * alpha)
        love.graphics.print(mod.displayName, name_x, y)
        if mod.suffix then
            love.graphics.setColor(0.7, 0.7, 0.7, 0.8 * alpha)
            love.graphics.print(mod.suffix, suffix_x, y)
        end
    end

    love.graphics.setScissor(self.x, self.y, self.width, self.height)
    for _, item in ipairs(visibleItems) do
        local drawY
        if isBottomSide then
            drawY = self.y + self.height - padding - item.y - lineHeight
        else
            drawY = self.y + padding + item.y
        end
        drawLine(item, drawY, item.alpha)
    end
    love.graphics.setScissor()
end


function ModuleList:OnMousePressed(x, y, button)
    if not (ty.ModuleStates and ty.ModuleStates.hud and ty.ModuleStates.hud.modulelist) then return false end
    if button ~= 1 then return false end
    if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
        self.dragging = true; self.offsetX = x - self.x; self.offsetY = y - self.y; return true
    end
    return false
end

function ModuleList:OnMouseMoved(x, y)
    if self.dragging then
        local screenW, screenH = love.graphics.getDimensions()
        local newX = x - self.offsetX; local newY = y - self.offsetY
        self.x = math.max(0, math.min(newX, screenW - self.width))
        self.y = math.max(0, math.min(newY, screenH - self.height))
    end
end

function ModuleList:OnMouseReleased(_, _, button)
    if button == 1 then self.dragging = false end
end

return ModuleList