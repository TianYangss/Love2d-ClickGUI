-- File: Utils/ui_components.lua (Final Corrected Version)

UI = {
    Components = {},
    ActiveSlider = nil,
    ActiveMenu = nil,
    Spacing = 15,
    CheckboxSize = 16,
    SliderHeight = 16,
    SliderWidth = 120,
    LabelPadding = 10
}

function UI.RegisterCheckbox(moduleName, label, key)
    local name = moduleName:lower()
    UI.Components[name] = UI.Components[name] or {}
    table.insert(UI.Components[name], { type = "checkbox", label = label, key = key, currentFill = 0 })
end
function UI.RegisterText(moduleName, label, content)
    local name = moduleName:lower()
    UI.Components[name] = UI.Components[name] or {}
    table.insert(UI.Components[name], { type = "text", label = label, content = content })
end
function UI.RegisterSlider(moduleName, label, key, min, max, step)
    local name = moduleName:lower()
    UI.Components[name] = UI.Components[name] or {}
    local moduleInstance = findModuleInstance(name)
    local startValue = (moduleInstance and moduleInstance[key]) or min
    table.insert(UI.Components[name],
        { type = "slider", label = label, key = key, min = min, max = max, step = step or 0.1, currentValue = startValue })
end

function UI.RegisterMode(moduleName, label, key, modes)
    local name = moduleName:lower()
    UI.Components[name] = UI.Components[name] or {}
    local font = love.graphics.getFont()
    local textH = font:getHeight()
    local baseHeight = textH + 8

    local maxWidth = UI.SliderWidth
    for _, mode in ipairs(modes) do
        local w = font:getWidth(mode)
        if w > maxWidth then
            maxWidth = w
        end
    end
    maxWidth = maxWidth + 20

    table.insert(UI.Components[name], {
        type = "mode",
        label = label,
        key = key,
        modes = modes,
        isOpen = false,
        baseHeight = baseHeight,
        currentHeight = baseHeight,
        targetHeight = baseHeight,
        startHeight = baseHeight,
        timer = 0,
        duration = 0.2,
        hoveredIndex = 0,
        currentHoverY = 0,
        currentHoverAlpha = 0,
        width = maxWidth
    })
end

function UI.Update(dt)
    if UI.ActiveMenu then
        local comp = UI.ActiveMenu.comp

        local targetAlpha = comp.hoveredIndex > 0 and 1 or 0
        comp.currentHoverAlpha = comp.currentHoverAlpha + (targetAlpha - comp.currentHoverAlpha) * 15 * dt
        if comp.hoveredIndex > 0 then
            local targetY = UI.ActiveMenu.y + (comp.hoveredIndex - 1) * comp.baseHeight
            if comp.currentHoverY == 0 or targetAlpha == 0 then comp.currentHoverY = targetY end
            comp.currentHoverY = comp.currentHoverY + (targetY - comp.currentHoverY) * 15 * dt
        end

        if comp.timer < comp.duration then
            comp.timer = comp.timer + dt
            local t = math.min(comp.timer / comp.duration, 1)
            local easeT = 1 - (1 - t) ^ 3
            comp.currentHeight = comp.startHeight + (comp.targetHeight - comp.startHeight) * easeT
        else
            comp.currentHeight = comp.targetHeight
            if comp.targetHeight == comp.baseHeight then
                comp.isOpen = false
                UI.ActiveMenu = nil
            end
        end
    end

    for moduleName, panel in pairs(ty.OpenedModules) do
        if panel.currentHeight > 10 and UI.Components[moduleName] then
            local moduleInstance = findModuleInstance(moduleName)
            if moduleInstance then
                for _, comp in ipairs(UI.Components[moduleName]) do
                    if comp.type == "slider" then
                        comp.currentValue = comp.currentValue + (moduleInstance[comp.key] - comp.currentValue) * 12 * dt
                    elseif comp.type == "checkbox" then
                        local targetFill = moduleInstance[comp.key] and 1 or 0
                        comp.currentFill = comp.currentFill + (targetFill - comp.currentFill) * 12 * dt
                    end
                end
            end
        end
    end
end

function findModuleInstance(moduleName)
    if not ty or not ty.ModulesByCategory or not moduleName then return nil end
    local selectedCat = ty.SelectedModuleCategory
    if selectedCat and ty.ModulesByCategory[selectedCat] then
        for _, mod in ipairs(ty.ModulesByCategory[selectedCat]) do if mod.name == moduleName then return mod.instance end end
    end
    return nil
end

function UI.Draw(moduleName, x, y)
    local components = UI.Components[moduleName]
    if not components then return 0 end
    local moduleInstance = findModuleInstance(moduleName)
    if not moduleInstance then return 0 end
    local currentY = y
    local font = love.graphics.getFont()
    local textH = font:getHeight()
    local Style = ty.GUI.Style

    for _, comp in ipairs(components) do
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(comp.label, x, currentY)
        local labelWidth = font:getWidth(comp.label)
        local controlX = x + labelWidth + UI.LabelPadding

        if comp.type == "checkbox" then
            local boxX = controlX
            local boxY = currentY + (textH - UI.CheckboxSize) / 2
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.rectangle("line", boxX, boxY, UI.CheckboxSize, UI.CheckboxSize, 3, 3)
            if comp.currentFill > 0.01 then
                local inset = 3
                local fullSize = UI.CheckboxSize - inset * 2
                local currentSize = fullSize * comp.currentFill
                local offset = (fullSize - currentSize) / 2
                love.graphics.setColor(0.2, 0.7, 1, comp.currentFill)
                love.graphics.rectangle("fill", boxX + inset + offset, boxY + inset + offset, currentSize, currentSize, 2,
                    2)
            end
            currentY = currentY + textH + UI.Spacing
        elseif comp.type == "slider" then
            local sliderX = controlX
            local sliderY = currentY + (textH - UI.SliderHeight) / 2
            local percent = (comp.currentValue - comp.min) / (comp.max - comp.min)
            percent = math.max(0, math.min(1, percent))
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.rectangle("fill", sliderX, sliderY + UI.SliderHeight / 2 - 2, UI.SliderWidth, 4, 2, 2)
            love.graphics.setColor(0.2, 0.7, 1, 1)
            love.graphics.rectangle("fill", sliderX, sliderY + UI.SliderHeight / 2 - 2, UI.SliderWidth * percent, 4, 2, 2)
            love.graphics.circle("fill", sliderX + UI.SliderWidth * percent, sliderY + UI.SliderHeight / 2, 6)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(string.format("%.2f", moduleInstance[comp.key]), sliderX + UI.SliderWidth + 10, currentY)
            currentY = currentY + textH + UI.Spacing
        elseif comp.type == "mode" then
            if not (UI.ActiveMenu and UI.ActiveMenu.comp == comp) then
                local w = comp.width
                local h = comp.baseHeight
                love.graphics.setColor(Style.baseColor[1], Style.baseColor[2], Style.baseColor[3], Style.baseAlpha + 0.1)
                love.graphics.rectangle("fill", controlX, currentY, w, h, Style.cornerRadius, Style.cornerRadius)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(moduleInstance[comp.key], controlX, currentY + (h - textH) / 2, w, "center")
                love.graphics.setColor(1, 1, 1, Style.outlineAlpha)
                love.graphics.rectangle("line", controlX, currentY, w, h, Style.cornerRadius, Style.cornerRadius)
            end
            currentY = currentY + comp.baseHeight + UI.Spacing
        end
    end
    local components = UI.Components[moduleName]
    if not components then return 0 end
    local moduleInstance = findModuleInstance(moduleName)
    if not moduleInstance then return 0 end
    local currentY = y
    local font = love.graphics.getFont()
    local textH = font:getHeight()
    local Style = ty.GUI.Style

    for _, comp in ipairs(components) do
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(comp.label, x, currentY)
        local labelWidth = font:getWidth(comp.label)
        local controlX = x + labelWidth + UI.LabelPadding

        if comp.type == "checkbox" then
            -- 原有的checkbox代码...
            currentY = currentY + textH + UI.Spacing
        elseif comp.type == "slider" then
            -- 原有的slider代码...
            currentY = currentY + textH + UI.Spacing
        elseif comp.type == "mode" then
            -- 原有的mode代码...
            currentY = currentY + comp.baseHeight + UI.Spacing
        elseif comp.type == "text" then
            -- 新增的text组件绘制
            love.graphics.setColor(0.8, 0.8, 0.8, 1)  -- 灰色文本
            love.graphics.print(comp.content, controlX, currentY)
            currentY = currentY + textH + UI.Spacing
        end
    end
    return currentY - y
end

function UI.DrawOverlay()
    if not UI.ActiveMenu then return end

    local info = UI.ActiveMenu
    local comp = info.comp
    if comp.currentHeight <= comp.baseHeight and comp.targetHeight == comp.baseHeight then return end

    local font = love.graphics.getFont()
    local textH = font:getHeight()
    local Style = ty.GUI.Style
    local panel = ty.OpenedModules[info.moduleName]
    if not panel then
        UI.ActiveMenu = nil
        return
    end

    local screenX = info.x
    local screenY = info.y
    local w = comp.width
    local h = comp.currentHeight

    love.graphics.push()
    love.graphics.setColor(Style.baseColor[1], Style.baseColor[2], Style.baseColor[3], Style.baseAlpha + 0.2)
    love.graphics.rectangle("fill", screenX, screenY, w, h, Style.cornerRadius, Style.cornerRadius)

    love.graphics.setScissor(screenX, screenY, w, h)

    local moduleInstance = findModuleInstance(info.moduleName)
    if not moduleInstance then
        UI.ActiveMenu = nil
        love.graphics.pop()
        return
    end
    local mx_scr, my_scr = love.mouse.getPosition()
    local hoveredThisFrame = false

    for i, mode in ipairs(comp.modes) do
        local itemY = screenY + (i - 1) * comp.baseHeight
        if mx_scr >= screenX and mx_scr <= screenX + w and my_scr >= itemY and my_scr < itemY + comp.baseHeight then
            comp.hoveredIndex = i
            hoveredThisFrame = true
        end
        if mode == moduleInstance[comp.key] then love.graphics.setColor(0.2, 0.7, 1, 1) else love.graphics.setColor(1, 1,
                1, 1) end
        love.graphics.printf(mode, screenX, itemY + (comp.baseHeight - textH) / 2, w, "center")
    end
    if not hoveredThisFrame then comp.hoveredIndex = 0 end

    if comp.currentHoverAlpha > 0.01 then
        love.graphics.setColor(0.2, 0.7, 1, 0.5 * comp.currentHoverAlpha)
        love.graphics.rectangle("fill", screenX, comp.currentHoverY, w, comp.baseHeight)
    end

    love.graphics.setScissor()
    love.graphics.setColor(1, 1, 1, Style.outlineAlpha)
    love.graphics.rectangle("line", screenX, screenY, w, h, Style.cornerRadius, Style.cornerRadius)
    love.graphics.pop()
end

function UI.MousePressed(moduleName, mx, my, button, main_scroll_y)
    if button ~= 1 then return end
    main_scroll_y = main_scroll_y or 0 -- 安全措施

    if UI.ActiveMenu then
        local info = UI.ActiveMenu
        local comp = info.comp
        local panel = ty.OpenedModules[info.moduleName]
        -- 覆盖层的坐标是屏幕坐标，不需要加任何滚动值
        local menuScreenY = info.y - panel.scroll_y

        if mx >= info.x and mx <= info.x + comp.width and my >= menuScreenY and my <= menuScreenY + comp.currentHeight then
            local itemIndex = math.floor((my - menuScreenY) / comp.baseHeight) + 1
            if itemIndex >= 1 and itemIndex <= #comp.modes then
                local moduleInstance = findModuleInstance(info.moduleName)
                if moduleInstance then moduleInstance[comp.key] = comp.modes[itemIndex] end
            end
            comp.targetHeight = comp.baseHeight
            comp.startHeight = comp.currentHeight
            comp.timer = 0
            return
        else
            comp.targetHeight = comp.baseHeight
            comp.startHeight = comp.currentHeight
            comp.timer = 0
        end
    end

    if not moduleName then return end
    local components = UI.Components[moduleName]
    if not components then return end
    local panel = ty.OpenedModules[moduleName]
    if not panel then return end
    local moduleInstance = findModuleInstance(moduleName)
    if not moduleInstance then return end

    -- 计算鼠标在“面板内部逻辑坐标系”中的Y值
    local panel_internal_mouseY = my - (panel.y - main_scroll_y) - ty.GUI.Style.headerHeight + panel.scroll_y

    local currentY_in_panel = 0 -- 相对面板内容区的Y坐标
    local currentX = panel.x + 10
    local font = love.graphics.getFont()

    for _, comp in ipairs(components) do
        local labelWidth = font:getWidth(comp.label)
        local controlX = currentX + labelWidth + UI.LabelPadding
        local height = font:getHeight()
        if comp.type == 'mode' then height = comp.baseHeight end
        local width = UI.SliderWidth
        if comp.type == 'mode' then width = comp.width end

        -- 使用面板内部坐标进行精确判断
        if mx >= controlX and mx <= controlX + width and panel_internal_mouseY >= currentY_in_panel and panel_internal_mouseY < currentY_in_panel + height then
            if comp.type == "checkbox" then
                moduleInstance[comp.key] = not moduleInstance[comp.key]
                return
            elseif comp.type == "slider" then
                UI.ActiveSlider = { module = moduleName, key = comp.key, comp = comp }
                UI.MouseMoved(mx, my, 0, 0)
                return
            elseif comp.type == "mode" then
                if UI.ActiveMenu and UI.ActiveMenu.comp ~= comp then
                    UI.ActiveMenu.comp.targetHeight = UI.ActiveMenu.comp.baseHeight
                    UI.ActiveMenu.comp.startHeight = UI.ActiveMenu.comp.currentHeight
                    UI.ActiveMenu.comp.timer = 0
                    UI.ActiveMenu.comp.isOpen = false
                end
                if comp.isOpen then
                    comp.targetHeight = comp.baseHeight
                else
                    comp.targetHeight = comp.baseHeight * #comp.modes
                    -- ActiveMenu的y坐标是屏幕坐标
                    local screenY = panel.y - main_scroll_y + ty.GUI.Style.headerHeight + currentY_in_panel -
                    panel.scroll_y
                    UI.ActiveMenu = { comp = comp, moduleName = moduleName, x = controlX, y = screenY, w = width }
                    comp.currentHoverY = 0
                end
                comp.isOpen = not comp.isOpen
                comp.startHeight = comp.currentHeight
                comp.timer = 0
                return
            end
        end
        currentY_in_panel = currentY_in_panel + height + UI.Spacing
    end
end

function UI.MouseMoved(mx, my, dx, dy)
    if not UI.ActiveSlider then return end
    local info = UI.ActiveSlider
    local panel = ty.OpenedModules[info.module]
    local moduleInstance = findModuleInstance(info.module)
    if not panel or not moduleInstance then return end
    local font = love.graphics.getFont()
    local labelWidth = font:getWidth(info.comp.label)
    local controlX = panel.x + 10 + labelWidth + UI.LabelPadding
    local percent = (mx - controlX) / UI.SliderWidth
    percent = math.max(0, math.min(1, percent))
    local range = info.comp.max - info.comp.min
    local rawValue = info.comp.min + range * percent
    moduleInstance[info.key] = math.floor(rawValue / info.comp.step + 0.5) * info.comp.step
end

function UI.MouseReleased(moduleName, x, y, button) if button == 1 then UI.ActiveSlider = nil end end

return UI
