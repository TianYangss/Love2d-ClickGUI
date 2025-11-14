--- START OF MODIFIED FILE main.txt ---

require("Utils.ui_components")
function findModuleInstanceGlobally(moduleName)
    if not ty or not ty.ModulesByCategory or not moduleName then return nil end
    for _, category_modules in pairs(ty.ModulesByCategory) do
        for _, mod in ipairs(category_modules) do
            if mod.name == moduleName then return mod.instance end
        end
    end
    return nil
end
local function tableToString(tbl, indent)
    indent = indent or 0
    local str = "{\n"
    local indentStr = string.rep(" ", indent + 2)

    for k, v in pairs(tbl) do
        local key
        if type(k) == "string" then
            key = string.format("[%q]", k)
        else
            key = string.format("[%s]", tostring(k))
        end

        if type(v) == "table" then
            str = str .. indentStr .. key .. " = " .. tableToString(v, indent + 2) .. ",\n"
        elseif type(v) == "string" then
            str = str .. indentStr .. key .. " = " .. string.format("%q", v) .. ",\n"
        else
            str = str .. indentStr .. key .. " = " .. tostring(v) .. ",\n"
        end
    end

    str = str .. string.rep(" ", indent) .. "}"
    return str
end

local function stringToTable(str)
    local f, err = load("return " .. str)
    if not f then
        ty.log("Error loading config:", err)
        return {}
    end
    return f()
end
local function getModuleLayout(widget)
    local screenW = ty.Manager.UI.Window.Width
    local screenH = ty.Manager.UI.Window.Height

    local guiX = widget.x * screenW
    local guiY = widget.y * screenH
    local guiW = widget.w * screenW
    local guiH = widget.h * screenH

    local columns = 3
    local moduleSpacing = 10
    local maxWidth = 600


    local leftWidth = 120
    local availableWidth = math.min(guiW - leftWidth - 30, maxWidth)


    local moduleWidth = (availableWidth - (columns - 1) * moduleSpacing) / columns
    local moduleHeight = 32


    local startX = guiX + leftWidth + 30
    local startY = guiY + 20

    return {
        x = startX,
        y = startY,
        w = moduleWidth,
        h = moduleHeight,
        spacing = moduleSpacing,
        cols = columns
    }
end



ty = {}
ty.OpenedModules = {}
function ty.closeAllOpenedModules()
    for name, panel in pairs(ty.OpenedModules) do
        panel.targetHeight = 0
        panel.targetAlpha = 0
        panel.isOpening = false
        panel.timer = 0
        panel.startHeight = nil
        panel.startAlpha = nil
    end
end

ty['Config'] = {}
ty['HUD'] = {}

ty['cfg'] = {
    save = function()
    
        local dataToSave = {
            GUI_Widget = { x = ty.GUI.widgets[1].x, y = ty.GUI.widgets[1].y },
            ModuleStates = ty.ModuleStates,
            ModuleSettings = {}
        }

    
        if ty.ModulesByCategory then
            for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
                for _, mod_obj in ipairs(modules_in_cat) do
                    if mod_obj.instance and type(mod_obj.instance) == "table" then
                        dataToSave.ModuleSettings[mod_obj.name] = mod_obj.instance
                    end
                end
            end
        end

    
        local success, result = pcall(tableToString, dataToSave)
        if success then
            love.filesystem.write("config.lua", "return " .. result)
            ty.log("Configuration saved successfully.")
        else
            ty.log("Error saving configuration:", result)
        end
    end,

    load = function()
    
        ty.GUI.widgets[1].x, ty.GUI.widgets[1].y = 0.1, 0.1
        ty.ModuleStates = {}
        ty.savedModuleSettings = nil -- 临时存放模块参数

        local fileInfo = love.filesystem.getInfo("config.lua")
        if fileInfo then
            local content, size = love.filesystem.read("config.lua")
            if size and size > 0 then
                local t = stringToTable(content)
                if type(t) == "table" then
                
                    if t.GUI_Widget and type(t.GUI_Widget) == "table" then
                        ty.GUI.widgets[1].x = t.GUI_Widget.x or 0.1
                        ty.GUI.widgets[1].y = t.GUI_Widget.y or 0.1
                    end
                    
                
                    ty.ModuleStates = t.ModuleStates or {}
                    
                
                    ty.savedModuleSettings = t.ModuleSettings or {}
                    
                    ty.log("Configuration loaded successfully.")
                    return
                end
            end
        end
        ty.log("No valid config file found, using defaults.")
    end
}

local w, h = love.graphics.getDimensions()
ty['Manager'] = {
    ['UI'] = {
        Window = {
            Width  = w,
            Height = h
        },
        video = {
            Width  = w,
            Height = h
        },
        GUI = {
            Enabled = false
        }
    }
}

function love.quit()
    ty.log("--- Application Closing, Saving Config ---")
    ty.cfg.save()
    return false
end
function love.resize(w, h)
    ty.Manager.UI.Window.Width  = w
    ty.Manager.UI.Window.Height = h

    if ty and ty.effects then
        ty.effects.screenCanvas = love.graphics.newCanvas(w, h)
        ty.effects.blurCanvas2 = love.graphics.newCanvas(w, h)
    end
end

ty.GUI = {
    widgets = {
        {
            x = 0.1,
            y = 0.1,
            w = 0.55,
            h = 0.6,
            dragging = false,
            offsetX = 0,
            offsetY = 0
        }
    }
}
ty.GUI.Style = {
    cornerRadius = 8,

    baseColor = { 0.1, 0.1, 0.1 },

    baseAlpha = 0.45,

    outlineAlpha = 0.7,

    headerHeight = 35,
}
ty.GUIRotation = ty.GUIRotation or 0
ty.GUIRotationTarget = ty.GUIRotationTarget or 0


function love.mousepressed(x, y, button)
    if ty.ModulesByCategory then
        for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
            if ty.ModuleStates and ty.ModuleStates[category_id] then
                for _, mod_obj in ipairs(modules_in_cat) do
                    if ty.ModuleStates[category_id][mod_obj.name] and mod_obj.instance and mod_obj.instance.OnMousePressed then
                        local success, handled = pcall(mod_obj.instance.OnMousePressed, mod_obj.instance, x, y, button)
                        if success and handled then
                            return
                        end
                    end
                end
            end
        end
    end

    if not ty.Manager.UI.GUI.Enabled then
        if UI and UI.MousePressed then UI.MousePressed(nil, x, y, button) end
        return
    end

    local screenW = ty.Manager.UI.Window.Width
    local screenH = ty.Manager.UI.Window.Height
    local widget = ty.GUI.widgets[1]
    local guiX = widget.x * screenW
    local guiY = widget.y * screenH

    if button == 1 then
        local startedDrag = false
        if x >= guiX and x <= guiX + ty.GUI.DragRegion.width and y >= guiY and y <= guiY + ty.GUI.DragRegion.height then
            widget.dragging = true
            widget.offsetX = x - guiX
            widget.offsetY = y - guiY
            startedDrag = true
        end

        if not startedDrag then
            local panelWidth = 800
            local panelHeight = 600
            local scaleFactor = 0.3
            local cx = guiX + 180 * scaleFactor
            local cy = guiY + panelHeight - 180 * scaleFactor
            local baseRadius = 120 * scaleFactor
            local baseOffset = 25 * scaleFactor
            local count = #ty.Modules
            local angleStep = (count > 0) and ((2 * math.pi) / count) or 0
            local font = love.graphics.getFont()
            for i, mod in ipairs(ty.Modules) do
                local angle = i * angleStep - math.pi / 2 + (ty.GUIRotation or 0)
                local rotation = angle + math.pi / 2
                local baseX = cx + math.cos(angle) * (baseRadius + baseOffset)
                local baseY = cy + math.sin(angle) * (baseRadius + baseOffset)
                local tw_unscaled = font:getWidth(mod.name)
                local th_unscaled = font:getHeight()
                local dx = x - baseX
                local dy = y - baseY
                local localX = dx * math.cos(-rotation) - dy * math.sin(-rotation)
                local localY = dx * math.sin(-rotation) + dy * math.cos(-rotation)
                if localX >= -tw_unscaled / 2 * scaleFactor * 1.4 and localX <= tw_unscaled / 2 * scaleFactor * 1.4 and localY >= -th_unscaled / 2 * scaleFactor * 1.4 and localY <= th_unscaled / 2 * scaleFactor * 1.4 then
                    mod.clickScaleTarget = 1.2
                    mod.clickTimer = 0.12
                    local targetAngle = -math.pi / 2
                    local diff = targetAngle - angle
                    diff = (diff + math.pi) % (2 * math.pi) - math.pi
                    ty.GUIRotationTarget = (ty.GUIRotation or 0) + diff
                    if ty.SelectedModuleCategory ~= mod.id then
                        ty.closeAllOpenedModules()
                        ty.SelectedModuleCategory = mod.id
                        if ty.ModulesByCategory[mod.id] then for _, m in ipairs(ty.ModulesByCategory[mod.id]) do m.initialized = false end end
                        ty.ModuleIconAnim.name = mod.name
                        ty.ModuleIconAnim.scale = 0.8
                        ty.ModuleIconAnim.alpha = 0
                        ty.ModuleIconAnim.timer = 0
                    end
                    return
                end
            end

            for name, panel in pairs(ty.OpenedModules) do
                local visualY = panel.y - widget.scroll_y
                if panel.currentHeight > 10 and panel.x and panel.w and x >= panel.x and x <= panel.x + panel.w and y >= visualY and y <= visualY + panel.currentHeight then
                    if y <= visualY + ty.GUI.Style.headerHeight then
                        local cat = ty.SelectedModuleCategory
                        ty.ModuleStates[cat] = ty.ModuleStates[cat] or {}
                        local oldState = ty.ModuleStates[cat][name]
                        ty.ModuleStates[cat][name] = not ty.ModuleStates[cat][name]
                        
                        local moduleInstance = findModuleInstance(name)
                        if moduleInstance then
                            if ty.ModuleStates[cat][name] and not oldState and moduleInstance.OnEnabled then
                                pcall(moduleInstance.OnEnabled, moduleInstance)
                            elseif not ty.ModuleStates[cat][name] and oldState and moduleInstance.OnDisabled then
                                pcall(moduleInstance.OnDisabled, moduleInstance)
                            end
                        end
                        
                        if ty.HUD.Island then ty.HUD.Island:addMessage(name .. " " .. (ty.ModuleStates[cat][name] and "Enabled" or "Disabled")) end
                        return
                    else
                        if UI and UI.MousePressed then UI.MousePressed(name, x, y, button, widget.scroll_y) end
                        return
                    end
                end
            end

            local cat = ty.SelectedModuleCategory
            if cat and ty.ModulesByCategory[cat] then
                for _, mod in ipairs(ty.ModulesByCategory[cat]) do
                    if mod.alpha > 0.5 then
                        local r = ty.ModuleRects[mod.name]
                        if r and x >= r.x and x <= r.x + r.w and y >= (r.y - widget.scroll_y) and y <= (r.y - widget.scroll_y) + r.h then
                            ty.ModuleStates[cat] = ty.ModuleStates[cat] or {}
                            local oldState = ty.ModuleStates[cat][mod.name]
                            ty.ModuleStates[cat][mod.name] = not ty.ModuleStates[cat][mod.name]
                            
                            if mod.instance then
                                if ty.ModuleStates[cat][mod.name] and not oldState and mod.instance.OnEnabled then
                                    pcall(mod.instance.OnEnabled, mod.instance)
                                elseif not ty.ModuleStates[cat][mod.name] and oldState and mod.instance.OnDisabled then
                                    pcall(mod.instance.OnDisabled, mod.instance)
                                end
                            end
                            
                            if ty.HUD.Island then ty.HUD.Island:addMessage(mod.name .. " " .. (ty.ModuleStates[cat][mod.name] and "Enabled" or "Disabled")) end
                            return
                        end
                    end
                end
            end
        end
    end

    if button == 2 then
        local mx, my = x, y
        for name, panel in pairs(ty.OpenedModules) do
            local visualY = panel.y - widget.scroll_y
            if panel.currentHeight > 10 and panel.x and panel.w and mx >= panel.x and mx <= panel.x + panel.w and my >= visualY and my <= visualY + 35 then
                panel.targetHeight = 0
                panel.targetAlpha = 0
                panel.isOpening = false
                panel.timer = 0
                panel.startHeight = nil
                panel.startAlpha = nil
                return
            end
        end
        if ty.ModuleRects then
            for name, r in pairs(ty.ModuleRects) do
                local visualY = r.y - widget.scroll_y
                if r and mx >= r.x and mx <= r.x + r.w and my >= visualY and my <= visualY + r.h then
                    if ty.OpenedModules[name] then
                        local panel = ty.OpenedModules[name]
                        panel.targetHeight = 0
                        panel.targetAlpha = 0
                        panel.isOpening = false
                        panel.timer = 0
                        panel.startHeight = nil
                        panel.startAlpha = nil
                    else
                        ty.OpenedModules[name] = { row = r.row, targetHeight = (widget.h * screenH) / 1.5, currentHeight = 0, targetAlpha = 1, currentAlpha = 0, timer = 0, duration = 0.25, isOpening = true, scroll_y = 0, content_height = 0 }
                    end
                    return
                end
            end
        end
    end

    if UI and UI.MousePressed then UI.MousePressed(nil, x, y, button) end
end
function love.mousereleased(x, y, button)
    if ty.ModulesByCategory then
        for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
            if ty.ModuleStates and ty.ModuleStates[category_id] then
                for _, mod_obj in ipairs(modules_in_cat) do
                    if ty.ModuleStates[category_id][mod_obj.name] and mod_obj.instance and mod_obj.instance.OnMouseReleased then
                        pcall(mod_obj.instance.OnMouseReleased, mod_obj.instance, x, y, button)
                    end
                end
            end
        end
    end

    if button == 1 then
        for _, widget in ipairs(ty.GUI.widgets) do
            widget.dragging = false
        end
    end
    if UI and UI.MouseReleased then
        UI.MouseReleased(nil, x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if ty.ModulesByCategory then
        for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
            if ty.ModuleStates and ty.ModuleStates[category_id] then
                for _, mod_obj in ipairs(modules_in_cat) do
                    if ty.ModuleStates[category_id][mod_obj.name] and mod_obj.instance and mod_obj.instance.OnMouseMoved then
                        pcall(mod_obj.instance.OnMouseMoved, mod_obj.instance, x, y, dx, dy)
                    end
                end
            end
        end
    end

    if ty.Manager.UI.GUI.Enabled then
        local screenW = ty.Manager.UI.Window.Width
        local screenH = ty.Manager.UI.Window.Height
        for _, widget in ipairs(ty.GUI.widgets) do
            if widget.dragging then
                local finalW = 800
                local finalH = 600
                local finalX = x - widget.offsetX
                local finalY = y - widget.offsetY
                if finalX < 0 then finalX = 0 elseif finalX + finalW > screenW then finalX = screenW - finalW end
                if finalY < 0 then finalY = 0 elseif finalY + finalH > screenH then finalY = screenH - finalH end
                widget.x = finalX / screenW
                widget.y = finalY / screenH
            end
        end
    end
    if UI and UI.MouseMoved then
        UI.MouseMoved(x, y, dx, dy)
    end
end

function love.load()
    ty.AttackEventReceivers = {}
    ty.StartupState     = "wait"
    ty.StartupTimer     = 0
    ty.StartupProgress  = 0
    ty.StartupProgressDuration = 1.5
    ty.StartupSkipProgress = 0
    ty.StartupSkipping = false
    ty.StartupParticles = {}
    local videoPath = "Assets/A.ogv"
    if love.filesystem.getInfo(videoPath) then
        ty.StartupVideo = love.graphics.newVideo(videoPath)
    else
        ty.StartupVideo = nil
        ty.StartupState = "done"
    end

    ty.ShowStartup = true

    local sourcePath = love.filesystem.getSource()
    local separator = package.config:sub(1, 1)
    local logFilePath = sourcePath .. separator .. "debug.log"
    local logFile = io.open(logFilePath, "w"); if logFile then logFile:close() end

    function ty.log(message, ...)
        local args = {...}; local formatted_args = ""
        if #args > 0 then for i, v in ipairs(args) do formatted_args = formatted_args .. "\t" .. tostring(v) end end
        local file = io.open(logFilePath, "a")
        if file then file:write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(message) .. formatted_args .. "\n"); file:close() end
    end

    ty.log("--- Application Starting ---")
    local fontPath = "Font/BOLD.TTF"; local fontSize = 24
    if love.filesystem.getInfo(fontPath) then local cnFont = love.graphics.newFont(fontPath, fontSize); love.graphics.setFont(cnFont) else ty.log("[Font] ❌ Font not found:", fontPath) end
    
    ty = ty or {}; ty.ModuleStates = ty.ModuleStates or {}
    ty.GUI = ty.GUI or { x = 100, y = 100, w = 300, h = 400 }
    ty.GUI.Anim = { alpha = 0, scale = 0.8, targetAlpha = 0, targetScale = 0.8, speed = 8 }
    ty.GUI.widgets[1].scroll_y = 0; ty.GUI.widgets[1].content_height = 0
    ty.GUI.DragHintAlpha = 0
    ty.GUI.Style = { cornerRadius = 8, baseColor = {0.1, 0.1, 0.1}, baseAlpha = 0.45, outlineAlpha = 0.7, headerHeight = 35 }
    ty.effects = { blurShader = love.graphics.newShader("blur.glsl"), screenCanvas = love.graphics.newCanvas(), blurCanvas2 = love.graphics.newCanvas() }
    ty.effects.blurShader:send("blur_amount", 1.5)
    ty.cfg.load()
    ty.GUI.DragRegion = { width = 120, height = 450, debug = true }

    ty.log("--- Loading Core UI Components ---")
    local island_path = "Module/HUD/Island.lua"
    if love.filesystem.getInfo(island_path) then
        local island_chunk, island_err = love.filesystem.load(island_path)
        if island_chunk then
            local success, result = pcall(island_chunk)
            if success and type(result) == "table" then
                ty.HUD.Island = result
                ty.log("[Island] Core module loaded successfully.")
            end
        else
            ty.log("[Island] ❌ Error loading core module:", island_err)
        end
    else
        ty.log("[Island] ❌ Core module file not found at:", island_path)
    end
    
    ty.log("--- Starting User Module Loading ---")
    ty.ModulesByCategory = {}
    ty.Modules = {}
    
    local lfs = love.filesystem
    local categories = lfs.getDirectoryItems("Module")
    for _, category in ipairs(categories) do
        local categoryPath = "Module/" .. category
        if lfs.getInfo(categoryPath, "directory") then
            local category_id = category:lower()
            ty.ModulesByCategory[category_id] = {}
            table.insert(ty.Modules, { name = category, id = category_id, scale = 1.0, targetScale = 1.0, offset = 0, targetOffset = 0, clickScale = 1.0, clickScaleTarget = 1.0, clickTimer = 0 })
            local files = lfs.getDirectoryItems(categoryPath)
            for _, file in ipairs(files) do
                if file:match("%.lua$") then
                    local moduleName = file:gsub("%.lua$", ""):lower()
                    if moduleName ~= "island" then
                        local moduleObject = { name = moduleName, instance = nil, x = -1, y = -1, targetX = 0, targetY = 0, alpha = 0, targetAlpha = 0, initialized = false }
                        local modulePath = categoryPath .. "/" .. file
                        local chunk, err = love.filesystem.load(modulePath)
                        if chunk then
                            local success, result = pcall(chunk)
                            if success and type(result) == "table" then moduleObject.instance = result end
                        end
                        table.insert(ty.ModulesByCategory[category_id], moduleObject)
                    end
                end
            end
        end
    end

    if ty.savedModuleSettings then
        ty.log("--- Applying Saved Module Settings ---")
        for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
            for _, mod_obj in ipairs(modules_in_cat) do
                if mod_obj.instance and ty.savedModuleSettings[mod_obj.name] then
                    for key, value in pairs(ty.savedModuleSettings[mod_obj.name]) do
                        mod_obj.instance[key] = value
                    end
                    
                    if ty.ModuleStates[category_id] and ty.ModuleStates[category_id][mod_obj.name] and mod_obj.instance.OnEnabled then
                        pcall(mod_obj.instance.OnEnabled, mod_obj.instance)
                    end
                end
            end
        end
        ty.savedModuleSettings = nil
        ty.log("--- Finished Applying Settings ---")
    end
    ty.log("--- Finished Module Loading ---")

    ty.ActivePotions = {}
    
    function ty.SetPotionEffect(effectName, duration)
        local potionDisplayInstance = findModuleInstanceGlobally("potiondisplay")
        local shouldShowInIsland = (potionDisplayInstance and potionDisplayInstance.showInIsland)

        if duration and duration > 0 then
            local found = false
            for _, effect in ipairs(ty.ActivePotions) do
                if effect.name == effectName then
                    effect.duration = duration
                    if shouldShowInIsland and ty.HUD.Island then ty.HUD.Island:addMessage(string.format("刷新了 %s 效果", effectName)) end
                    found = true
                    break
                end
            end
            if not found then
                table.insert(ty.ActivePotions, { name = effectName, duration = duration })
                if shouldShowInIsland and ty.HUD.Island then ty.HUD.Island:addMessage(string.format("获得了 %s 效果", effectName)) end
            end
        else
            for i = #ty.ActivePotions, 1, -1 do
                if ty.ActivePotions[i].name == effectName then
                    if shouldShowInIsland and ty.HUD.Island then ty.HUD.Island:addMessage(string.format("%s 效果消失了", effectName)) end
                    table.remove(ty.ActivePotions, i)
                    break
                end
            end
        end
    end
    
    ty.BackgroundImage = love.graphics.newImage('Assets/BG.png')
    ty.ModuleIcons = { Combat = love.graphics.newImage("Assets/Module/Combat.png"), Move = love.graphics.newImage("Assets/Module/Move.png"), Client = love.graphics.newImage("Assets/Module/Client.png"), Render = love.graphics.newImage("Assets/Module/Render.png"), Misc = love.graphics.newImage("Assets/Module/Misc.png"), HUD = love.graphics.newImage("Assets/Module/HUD.png") }
    ty.SelectedModuleCategory = "combat"
    ty.ModuleIconAnim = { name = "Combat", scale = 1, alpha = 1, timer = 0 }
    
    local count = #ty.Modules
    if count > 0 then
        for i, mod in ipairs(ty.Modules) do
            if mod.id == "combat" then
                local angleStep = (2 * math.pi) / count; local combatAngle = i * angleStep - math.pi / 2; local targetAngle = -math.pi / 2
                local diff = targetAngle - combatAngle; diff = (diff + math.pi) % (2 * math.pi) - math.pi
                ty.GUIRotation = ty.GUIRotation + diff; ty.GUIRotationTarget = ty.GUIRotation
                break
            end
        end
    end
end

function love.wheelmoved(x, y)
    if not ty.Manager.UI.GUI.Enabled then return end

    local widget = ty.GUI.widgets[1]
    local mx, my = love.mouse.getPosition()
    local scrollAmount = y * 25

    local screenW, screenH = love.graphics.getDimensions()
    local finalX = widget.x * screenW
    local finalY = widget.y * screenH
    local panelWidth = 800
    local panelHeight = 600

    local handled = false

    for name, panel in pairs(ty.OpenedModules) do
        if panel.currentHeight > ty.GUI.Style.headerHeight and panel.w then
            local contentX = panel.x
            local contentY = panel.y + ty.GUI.Style.headerHeight
            local contentW = panel.w
            local contentH = panel.h - ty.GUI.Style.headerHeight

            if mx >= contentX and mx <= contentX + contentW and my >= contentY and my <= contentY + contentH then
                panel.scroll_y = panel.scroll_y - scrollAmount
                local maxScroll = math.max(0, panel.content_height - contentH)
                panel.scroll_y = math.max(0, math.min(panel.scroll_y, maxScroll))
                handled = true
                break
            end
        end
    end


    if not handled then
        if mx >= finalX and mx <= finalX + panelWidth and my >= finalY and my <= finalY + panelHeight then
            widget.scroll_y = widget.scroll_y - scrollAmount
        
            local visibleHeight = panelHeight - 40
            local maxScroll = math.max(0, widget.content_height - visibleHeight)
            widget.scroll_y = math.max(0, math.min(widget.scroll_y, maxScroll))
        end
    end
end
function love.keypressed(key)
    if ty.StartupState ~= "done" and key == "space" then
        ty.StartupSkipping = true
        return
    end
    if UI and UI.KeyPressed and UI.ActiveText then
        local handled = UI.KeyPressed(key)
        if handled then return end
    end
    if ty and ty.ModulesByCategory then
        for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
            if ty.ModuleStates and ty.ModuleStates[category_id] then
                for _, mod_obj in ipairs(modules_in_cat) do
                    if ty.ModuleStates[category_id][mod_obj.name] and mod_obj.instance and mod_obj.instance.OnKeyPressed then
                        local ok, handled = pcall(mod_obj.instance.OnKeyPressed, mod_obj.instance, key)
                        if ok and handled then return end
                    end
                end
            end
        end
    end

    if key == "rshift" then
    
        if ty.GUI.Anim.targetAlpha < 0.5 then
            ty.Manager.UI.GUI.Enabled = true
            ty.GUI.Anim.targetAlpha = 1.0
            ty.GUI.Anim.targetScale = 1.0
        else
            ty.GUI.Anim.targetAlpha = 0.0
            ty.GUI.Anim.targetScale = 0.85
        end
    end
    if key == "escape" then
    
        ty.GUI.Anim.targetAlpha = 0.0
        ty.GUI.Anim.targetScale = 0.85
    end

    if key == "1" then ty.SetPotionEffect("力量", 10) end
    if key == "2" then ty.SetPotionEffect("生命恢复", 30) end
    if key == "3" then ty.SetPotionEffect("抗性提升", 60) end
    if key == "4" then ty.SetPotionEffect("速度", 20) end
end
function love.keyreleased(key)
    if ty.StartupState ~= "done" and key == "space" then
        ty.StartupSkipping = false
    end
    
    if ty and ty.ModulesByCategory then
        for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
            if ty.ModuleStates and ty.ModuleStates[category_id] then
                for _, mod_obj in ipairs(modules_in_cat) do
                    if ty.ModuleStates[category_id][mod_obj.name] and mod_obj.instance and mod_obj.instance.OnKeyReleased then
                        pcall(mod_obj.instance.OnKeyReleased, mod_obj.instance, key)
                    end
                end
            end
        end
    end
end
local function createStartupParticles(x, y)
    for i = 1, 2 do 
        local particle = {
            x = x,
            y = y + math.random(-5, 5),
            vx = math.random(40, 80),
            vy = math.random(-15, 15), 
            life = 1.0,
            maxLife = 0.6 + math.random() * 0.4,
            size = 1.5 + math.random() * 1.5,
            color = {1, 1, 1}
        }
        table.insert(ty.StartupParticles, particle)
    end
end

function love.update(dt)
    if ty.StartupState ~= "done" then
        if ty.StartupSkipping then
            ty.StartupSkipProgress = math.min(ty.StartupSkipProgress + dt, 1.0)
            if ty.StartupSkipProgress >= 1.0 then
                ty.StartupState = "done"
                if ty.StartupVideo then
                    ty.StartupVideo:pause()
                    ty.StartupVideo = nil
                end
                return
            end
        else
            ty.StartupSkipProgress = math.max(ty.StartupSkipProgress - dt, 0)
        end
        
        if ty.StartupState == "wait" then
            ty.StartupTimer = ty.StartupTimer + dt
            if ty.StartupTimer >= 0.5 then
                ty.StartupState = "video"
                if ty.StartupVideo then
                    ty.StartupVideo:play()
                end
            end
        elseif ty.StartupState == "video" then
            if ty.StartupVideo and not ty.StartupVideo:isPlaying() then
                ty.StartupState = "progress"
            end
        elseif ty.StartupState == "progress" then
            local oldProgress = ty.StartupProgress
            ty.StartupProgress = math.min(ty.StartupProgress + dt, ty.StartupProgressDuration)
            
            if ty.StartupProgress > oldProgress then
                local w = love.graphics.getWidth()
                local barWidth = 400
                local barX = (w - barWidth) / 2
                local progressPercentage = ty.StartupProgress / ty.StartupProgressDuration
                
            
                local particleX = barX + barWidth * progressPercentage
                local particleY = love.graphics.getHeight() - 55 
                createStartupParticles(particleX, particleY)
            end

            if ty.StartupProgress >= ty.StartupProgressDuration then
                ty.StartupState = "done"
                if ty.StartupVideo then
                    ty.StartupVideo:pause()
                    ty.StartupVideo = nil
                end
            end
        end

        for i = #ty.StartupParticles, 1, -1 do
            local p = ty.StartupParticles[i]
            p.vx = p.vx * (1 - 0.8 * dt) 
            p.vy = p.vy * (1 - 0.8 * dt)
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.life = p.life - dt / p.maxLife
            if p.life <= 0 then
                table.remove(ty.StartupParticles, i)
            end
        end

        if ty.StartupState ~= "done" then return end
    end


    local anim = ty.GUI.Anim
    anim.alpha = anim.alpha + (anim.targetAlpha - anim.alpha) * math.min(1, anim.speed * dt)
    anim.scale = anim.scale + (anim.targetScale - anim.scale) * math.min(1, anim.speed * dt)

    if ty.Manager.UI.GUI.Enabled and anim.alpha < 0.01 and anim.targetAlpha < 0.5 then
        ty.Manager.UI.GUI.Enabled = false
    end

    for _, mod in ipairs(ty.Modules) do
        local speed = 8
        mod.scale = mod.scale + (mod.targetScale - mod.scale) * math.min(1, dt * speed)
        mod.offset = mod.offset + (mod.targetOffset - mod.offset) * math.min(1, dt * speed)
        mod.clickScale = mod.clickScale + (mod.clickScaleTarget - mod.clickScale) * math.min(1, dt * 10)
        if mod.clickTimer and mod.clickTimer > 0 then
            mod.clickTimer = mod.clickTimer - dt
            if mod.clickTimer <= 0 then
                mod.clickScaleTarget = 1.0
            end
        end
    end
    ty.GUIRotation = ty.GUIRotation + ((ty.GUIRotationTarget or 0) - (ty.GUIRotation or 0)) * math.min(1, dt * 5)
    if ty.ModuleIconAnim then
        local anim = ty.ModuleIconAnim
        anim.timer = anim.timer + dt
        anim.scale = anim.scale + (1 - anim.scale) * 6 * dt
        anim.alpha = anim.alpha + (1 - anim.alpha) * 6 * dt
    end
    if ty.Manager.UI.GUI.Enabled then
        local targetAlpha = 0
        for _, widget in ipairs(ty.GUI.widgets) do
            if widget.dragging then
                targetAlpha = 1
                break
            end
        end
        ty.GUI.DragHintAlpha = ty.GUI.DragHintAlpha + (targetAlpha - ty.GUI.DragHintAlpha) * math.min(5 * dt, 1)
    end
    local modulesToRemove = {}
    for name, panel in pairs(ty.OpenedModules) do
        if panel.timer < panel.duration then
            panel.timer = panel.timer + dt
            local t = math.min(panel.timer / panel.duration, 1)
            local easeT = 1 - (1 - t) ^ 3
            if panel.startHeight == nil then panel.startHeight = panel.currentHeight end
            if panel.startAlpha == nil then panel.startAlpha = panel.currentAlpha end
            panel.currentHeight = panel.startHeight + (panel.targetHeight - panel.startHeight) * easeT
            panel.currentAlpha = panel.startAlpha + (panel.targetAlpha - panel.startAlpha) * easeT
        else
            panel.currentHeight = panel.targetHeight
            panel.currentAlpha = panel.targetAlpha
        end
        if panel.timer >= panel.duration then
            panel.startHeight = nil
            panel.startAlpha = nil
        end
        if not panel.isOpening and panel.currentHeight <= 0.1 and panel.targetHeight == 0 then table.insert(
            modulesToRemove, name) end
    end
    for _, name in ipairs(modulesToRemove) do ty.OpenedModules[name] = nil end

    local selectedCategory = ty.SelectedModuleCategory
    if selectedCategory and ty.ModulesByCategory[selectedCategory] then
        local widget = ty.GUI.widgets[1]
        local modules = ty.ModulesByCategory[selectedCategory]
        local layout = getModuleLayout(widget)
        local items_to_layout = {}
        local modules_with_open_panel = {}
        for name, _ in pairs(ty.OpenedModules) do modules_with_open_panel[name] = true end
        for _, mod in ipairs(modules) do if modules_with_open_panel[mod.name] then table.insert(items_to_layout,
                    ty.OpenedModules[mod.name]) else table.insert(items_to_layout, mod) end end
        for _, mod in ipairs(modules) do if modules_with_open_panel[mod.name] then mod.targetAlpha = 0 end end
        local cursor_x = layout.x
        local cursor_y = layout.y
        local row_height = layout.h
        for i, item in ipairs(items_to_layout) do
            if item.currentHeight then
                local panel = item
                if cursor_x > layout.x then cursor_y = cursor_y + row_height + layout.spacing end
                panel.targetX = layout.x
                panel.targetY = cursor_y
                cursor_y = cursor_y + panel.currentHeight + layout.spacing
                cursor_x = layout.x
                row_height = layout.h
            else
                local mod = item
                if cursor_x + layout.w > layout.x + layout.cols * (layout.w + layout.spacing) - layout.spacing / 2 then
                    cursor_y = cursor_y + row_height + layout.spacing
                    cursor_x = layout.x
                end
                mod.targetX = cursor_x
                mod.targetY = cursor_y
                mod.targetAlpha = 1
                cursor_x = cursor_x + layout.w + layout.spacing
            end
        end
        widget.content_height = cursor_y - layout.y
    end

    local widget = ty.GUI.widgets[1]
    local moveSpeed = 12
    for name, panel in pairs(ty.OpenedModules) do
        if panel.targetX then if widget.dragging then panel.x = panel.targetX else if panel.x then panel.x = panel.x +
                    (panel.targetX - panel.x) * math.min(1, dt * moveSpeed) else panel.x = panel.targetX end end end
        if panel.targetY then if widget.dragging then panel.y = panel.targetY else if panel.y then panel.y = panel.y +
                    (panel.targetY - panel.y) * math.min(1, dt * moveSpeed) else panel.y = panel.targetY end end end
    end
    if selectedCategory and ty.ModulesByCategory[selectedCategory] then
        for _, mod in ipairs(ty.ModulesByCategory[selectedCategory]) do
            if mod.targetX and mod.targetY then
                if widget.dragging then
                    mod.x, mod.y = mod.targetX, mod.targetY
                else
                    if not mod.initialized then
                        mod.x, mod.y, mod.alpha = mod.targetX, mod.targetY + 30, 0
                        mod.initialized = true
                    else
                        mod.x = mod.x + (mod.targetX - mod.x) * math.min(1, dt * moveSpeed)
                        mod.y = mod.y + (mod.targetY - mod.y) * math.min(1, dt * moveSpeed)
                    end
                end
            end
            if mod.targetAlpha ~= nil then mod.alpha = mod.alpha +
                (mod.targetAlpha - mod.alpha) * math.min(1, dt * (moveSpeed / 1.5)) end
        end
    end
    if UI and UI.Update then
        UI.Update(dt)
    end
    
    if ty.ModulesByCategory then
        for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
            for _, mod_obj in ipairs(modules_in_cat) do
                if ty.ModuleStates and ty.ModuleStates[category_id] and ty.ModuleStates[category_id][mod_obj.name] and mod_obj.instance and mod_obj.instance.OnUpdate then
                    pcall(mod_obj.instance.OnUpdate, mod_obj.instance, dt)
                end
            end
        end
    end

    if ty.HUD.Island then
        ty.HUD.Island:OnUpdate(dt)
    end
end


function love.draw()
    if ty.StartupState ~= "done" then
        local w, h = love.graphics.getDimensions()
        local fade = (ty.StartupState == "fadeout") and ty.StartupFade or 1
        love.graphics.setColor(1, 1, 1, fade)
        if ty.StartupVideo then
            local vw, vh = ty.StartupVideo:getWidth(), ty.StartupVideo:getHeight()
            local scale = math.min(w / vw, h / vh)
            love.graphics.draw(ty.StartupVideo, w / 2, h / 2, 0, scale, scale, vw / 2, vh / 2)
        end
        
    
        if ty.StartupState == "progress" then
            local barWidth = 400
            local barHeight = 10
            local barX = (w - barWidth) / 2
            local barY = h - 60
            local progressPercentage = ty.StartupProgress / ty.StartupProgressDuration

            love.graphics.setColor(0.2, 0.2, 0.2, 0.8 * fade)
            love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 3)

        
            local filledWidth = barWidth * progressPercentage
            love.graphics.setColor(1, 1, 1, 0.9 * fade) 
            love.graphics.rectangle("fill", barX, barY, filledWidth, barHeight, 3)
        end
        for _, p in ipairs(ty.StartupParticles) do
            local alpha = p.life
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * fade)
            love.graphics.circle("fill", p.x, p.y, p.size * (p.life ^ 0.7))
        end


        if ty.StartupSkipProgress > 0 then
            local circleRadius = 20
            local circleX = w - 40
            local circleY = 40
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", circleX, circleY, circleRadius)
            if ty.StartupSkipProgress > 0 then
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.arc("fill", circleX, circleY, circleRadius - 2,
                                 -math.pi/2, -math.pi/2 + 2 * math.pi * ty.StartupSkipProgress, 32)
            end
            love.graphics.setColor(1, 1, 1, 0.3)
        end
        return
    end

    local widget = ty.GUI.widgets[1]
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local Style = ty.GUI.Style

    love.graphics.setCanvas(ty.effects.screenCanvas)
    love.graphics.clear()
    if ty.BackgroundImage then
        local imgW, imgH = ty.BackgroundImage:getDimensions()
        local scaleX = screenW / imgW
        local scaleY = screenH / imgH
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ty.BackgroundImage, 0, 0, 0, scaleX, scaleY)
    end
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ty.effects.screenCanvas, 0, 0)

    if ty.GUI.Anim.alpha > 0.01 then
        local finalX = widget.x * screenW
        local finalY = widget.y * screenH
        local panelWidth = 800
        local panelHeight = 600
        local anim = ty.GUI.Anim
    
        love.graphics.setShader(ty.effects.blurShader)
        local w, h = ty.effects.screenCanvas:getDimensions()
        ty.effects.blurShader:send("texture_dimensions", { w, h })
        love.graphics.setCanvas(ty.effects.blurCanvas2)
        ty.effects.blurShader:send("blur_direction", { 1.0, 0.0 })
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ty.effects.screenCanvas, 0, 0)
        love.graphics.setCanvas()
        love.graphics.stencil(
        function() love.graphics.rectangle("fill", finalX, finalY, panelWidth, panelHeight, Style.cornerRadius,
                Style.cornerRadius) end, "replace", 1)
        love.graphics.setStencilTest("equal", 1)
        ty.effects.blurShader:send("blur_direction", { 0.0, 1.0 })
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ty.effects.blurCanvas2, 0, 0)
        love.graphics.setStencilTest()
        love.graphics.setShader()
    
        love.graphics.push()
        love.graphics.translate(finalX + panelWidth / 2, finalY + panelHeight / 2)
        love.graphics.scale(anim.scale)
        love.graphics.translate(-(finalX + panelWidth / 2), -(finalY + panelHeight / 2))
        
        local glowLayers = 12
        for glow = glowLayers, 1, -1 do
            local t = glow / glowLayers
            local alpha = 0.04 * (1 - t) * t
            love.graphics.setColor(1, 1, 1, alpha * anim.alpha)
            love.graphics.setLineWidth(1 + t * 3)
            love.graphics.rectangle("line", finalX - glow * 0.8, finalY - glow * 0.8, panelWidth + glow * 1.6,
                panelHeight + glow * 1.6, Style.cornerRadius + glow * 0.5, Style.cornerRadius + glow * 0.5)
        end
        love.graphics.setColor(1, 1, 1, 0.5 * anim.alpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", finalX, finalY, panelWidth, panelHeight, Style.cornerRadius, Style.cornerRadius)

        local scaleFactor = 0.3
        local textScaleFactor = scaleFactor * 1.4
        local listOffsetX = 180 * scaleFactor
        local listOffsetY = 180 * scaleFactor
        local cx = finalX + listOffsetX
        local cy = finalY + panelHeight - listOffsetY
        local baseRadius = 120 * scaleFactor
        local count = #ty.Modules
        local angleStep = (count > 0) and ((2 * math.pi) / count) or 0
        local mx, my = love.mouse.getPosition()
        local font = love.graphics.getFont()
        for glow = 12, 1, -1 do
            local t = glow / 12
            love.graphics.setColor(1, 1, 1, 0.015 * (t ^ 1.4) * anim.alpha)
            love.graphics.setLineWidth((1 + t * 4) * scaleFactor)
            love.graphics.circle("line", cx, cy, baseRadius)
        end
        love.graphics.setColor(1, 1, 1, 0.9 * anim.alpha)
        love.graphics.setLineWidth(3 * scaleFactor)
        love.graphics.circle("line", cx, cy, baseRadius)

        local selectedIconName = ""
        for _, mod in ipairs(ty.Modules) do
            if mod.id == ty.SelectedModuleCategory then
                selectedIconName = mod.name
                break
            end
        end

        local iconAnim = ty.ModuleIconAnim
        if iconAnim and iconAnim.name == selectedIconName then
            local currentIcon = ty.ModuleIcons[selectedIconName]
            if currentIcon then
                love.graphics.push()
                love.graphics.translate(cx, cy)
                local iconOriginalWidth, iconOriginalHeight = currentIcon:getWidth(), currentIcon:getHeight()
                local maxIconAreaRadius = baseRadius * 0.5
                local finalIconScale = math.min(maxIconAreaRadius * 2 / iconOriginalWidth,
                    maxIconAreaRadius * 2 / iconOriginalHeight) * iconAnim.scale
                love.graphics.setColor(1, 1, 1, iconAnim.alpha * anim.alpha)
                love.graphics.draw(currentIcon, 0, 0, 0, finalIconScale, finalIconScale, iconOriginalWidth / 2,
                    iconOriginalHeight / 2)
                love.graphics.pop()
            end
        end
        local baseOffset = 25 * scaleFactor
        local hoverExtra = 20 * scaleFactor
        for i, mod in ipairs(ty.Modules) do
            local angle = i * angleStep - math.pi / 2 + (ty.GUIRotation or 0)
            local rotation = angle + math.pi / 2
            local baseX, baseY = cx + math.cos(angle) * (baseRadius + baseOffset),
                cy + math.sin(angle) * (baseRadius + baseOffset)
            local x, y = baseX + math.cos(angle) * mod.offset * scaleFactor,
                baseY + math.sin(angle) * mod.offset * scaleFactor
            local text = mod.name
            local tw_unscaled, th_unscaled = font:getWidth(text), font:getHeight()
            local dx, dy = mx - baseX, my - baseY
            local localX, localY = dx * math.cos(-rotation) - dy * math.sin(-rotation),
                dx * math.sin(-rotation) + dy * math.cos(-rotation)
            local hovered = localX >= -tw_unscaled / 2 * textScaleFactor and localX <= tw_unscaled / 2 * textScaleFactor and
            localY >= -th_unscaled / 2 * textScaleFactor and localY <= th_unscaled / 2 * textScaleFactor
            local isSelected = (mod.id == ty.SelectedModuleCategory)
            if hovered then mod.targetScale, mod.targetOffset = 1.3, hoverExtra elseif isSelected then mod.targetScale, mod.targetOffset =
                1.7, hoverExtra * 0.6 else mod.targetScale, mod.targetOffset = 1.0, 0 end
            love.graphics.push()
            love.graphics.translate(x, y)
            love.graphics.rotate(rotation)
            local totalScale = (mod.scale or 1) * (mod.clickScale or 1) * textScaleFactor
            love.graphics.scale(totalScale)
            love.graphics.setColor(0, 0, 0, (0.4 + 0.4 * (totalScale - 1)) * anim.alpha)
            love.graphics.printf(text, -tw_unscaled / 2 + 2, -th_unscaled / 2 + 2, tw_unscaled, "center")
            love.graphics.setColor(1, 1, 1, 1 * anim.alpha)
            love.graphics.printf(text, -tw_unscaled / 2, -th_unscaled / 2, tw_unscaled, "center")
            love.graphics.pop()
        end

        local selectedCategory = ty.SelectedModuleCategory
        if selectedCategory and ty.ModulesByCategory[selectedCategory] then
            local layout = getModuleLayout(widget)
            ty.ModuleRects = {}
            local textH = font:getHeight()
            for name, panel in pairs(ty.OpenedModules) do
                if panel.currentAlpha > 0.01 and panel.x then
                    panel.w = (finalX + panelWidth - 20) - layout.x
                    panel.h = panel.currentHeight
                end
            end
            local listScissorX = layout.x
            local listScissorY = layout.y
            local listScissorW = (finalX + panelWidth - 20) - listScissorX
            local listScissorH = (finalY + panelHeight - 20) - listScissorY
            love.graphics.setScissor(listScissorX, listScissorY, listScissorW, listScissorH)
            love.graphics.push()
            love.graphics.translate(0, -widget.scroll_y)
            for i, mod in ipairs(ty.ModulesByCategory[selectedCategory]) do
                if mod.alpha > 0.01 and mod.x then
                    if ty.ModuleStates[selectedCategory] and ty.ModuleStates[selectedCategory][mod.name] then
                        local xPos, yPos, w, h = mod.x, mod.y, layout.w, layout.h
                        local glowColor = { 0.2, 0.7, 1 }
                        for g = 8, 1, -1 do
                            local t = g / 8
                            love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], 0.1 * t * mod.alpha * anim.alpha)
                            love.graphics.setLineWidth(1.5 + t * 2.5)
                            love.graphics.rectangle("line", xPos - g * 0.7, yPos - g * 0.7, w + g * 1.4, h + g * 1.4,
                                Style.cornerRadius + g * 0.3, Style.cornerRadius + g * 0.3)
                        end
                    end
                end
            end
            for name, panel in pairs(ty.OpenedModules) do
                if panel.currentAlpha > 0.01 and panel.x then
                    if ty.ModuleStates[selectedCategory] and ty.ModuleStates[selectedCategory][name] then
                        local panelX, panelY, panelW, panelH = panel.x, panel.y, panel.w, panel.h
                        local glowColor = { 0.2, 0.7, 1 }
                        for g = 8, 1, -1 do
                            local t = g / 8
                            love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], 0.1 * t * panel
                            .currentAlpha * anim.alpha)
                            love.graphics.setLineWidth(1.5 + t * 2.5)
                            love.graphics.rectangle("line", panelX - g * 0.7, panelY - g * 0.7, panelW + g * 1.4,
                                panelH + g * 1.4, Style.cornerRadius + g * 0.3, Style.cornerRadius + g * 0.3)
                        end
                    end
                end
            end
            for i, mod in ipairs(ty.ModulesByCategory[selectedCategory]) do
                if mod.alpha > 0.01 and mod.x then
                    local xPos, yPos, w, h = mod.x, mod.y, layout.w, layout.h
                    ty.ModuleRects[mod.name] = { x = xPos, y = yPos, w = w, h = h, row = math.floor((i - 1) / layout
                    .cols) }
                    love.graphics.setColor(Style.baseColor[1], Style.baseColor[2], Style.baseColor[3],
                        (Style.baseAlpha + 0.1) * mod.alpha * anim.alpha)
                    love.graphics.rectangle("fill", xPos, yPos, w, h, Style.cornerRadius, Style.cornerRadius)
                    love.graphics.setColor(1, 1, 1, Style.outlineAlpha * mod.alpha * anim.alpha)
                    love.graphics.rectangle("line", xPos, yPos, w, h, Style.cornerRadius, Style.cornerRadius)
                    love.graphics.setColor(1, 1, 1, 1 * mod.alpha * anim.alpha)
                    love.graphics.printf(mod.name, xPos, yPos + (h - textH) / 2 + 3, w, "center")
                end
            end
            for name, panel in pairs(ty.OpenedModules) do
                if panel.currentAlpha > 0.01 and panel.x then
                    local panelX, panelY, panelW, panelH = panel.x, panel.y, panel.w, panel.h
                    love.graphics.setColor(Style.baseColor[1], Style.baseColor[2], Style.baseColor[3],
                        Style.baseAlpha * panel.currentAlpha * anim.alpha)
                    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, Style.cornerRadius,
                        Style.cornerRadius)
                    love.graphics.setColor(1, 1, 1, Style.outlineAlpha * panel.currentAlpha * anim.alpha)
                    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, Style.cornerRadius,
                        Style.cornerRadius)
                    love.graphics.setColor(1, 1, 1, panel.currentAlpha * anim.alpha)
                    love.graphics.printf(name, panelX, panelY + (Style.headerHeight - textH) / 2 + 2, panelW, "center")

                    if panel.currentAlpha > 0.5 then
                        local contentX = panelX + 10
                        local contentY = panelY + Style.headerHeight
                        local contentW = panelW - 20
                        local contentH = panelH - Style.headerHeight - 10
                        local panelVisualY = contentY - widget.scroll_y
                        local intersectX = math.max(listScissorX, contentX)
                        local intersectY = math.max(listScissorY, panelVisualY)
                        local intersectEndX = math.min(listScissorX + listScissorW, contentX + contentW)
                        local intersectEndY = math.min(listScissorY + listScissorH, panelVisualY + contentH)
                        local intersectW = intersectEndX - intersectX
                        local intersectH = intersectEndY - intersectY

                        if intersectW > 0 and intersectH > 0 then
                            love.graphics.setScissor(intersectX, intersectY, intersectW, intersectH)
                            love.graphics.push()
                            love.graphics.translate(0, -panel.scroll_y)
                            panel.content_height = UI.Draw(name, contentX, contentY)
                            love.graphics.pop()
                            love.graphics.setScissor(listScissorX, listScissorY, listScissorW, listScissorH)
                        end
                    end
                end
            end
            love.graphics.pop()
            love.graphics.setScissor()
        end
        love.graphics.pop()
    end

    if ty.ModulesByCategory then
        for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
            if ty.ModuleStates and ty.ModuleStates[category_id] then
                for _, mod_obj in ipairs(modules_in_cat) do
                    if ty.ModuleStates[category_id][mod_obj.name] and mod_obj.instance and mod_obj.instance.OnDraw then
                        pcall(mod_obj.instance.OnDraw, mod_obj.instance)
                    end
                end
            end
        end
    end

    if ty.HUD.Island then
        ty.HUD.Island:OnDraw()
    end

    if ty.Manager.UI.GUI.Enabled and UI and UI.DrawOverlay then
        UI.DrawOverlay()
    end
end
function love.textinput(t)
    if ty and ty.Manager and ty.Manager.UI and ty.Manager.UI.GUI and ty.Manager.UI.GUI.Enabled then
        if UI and UI.TextInput and UI.ActiveText then
            pcall(UI.TextInput, t)
            return
        end
    end
    if ty and ty.ModulesByCategory then
        for category_id, modules_in_cat in pairs(ty.ModulesByCategory) do
            if ty.ModuleStates and ty.ModuleStates[category_id] then
                for _, mod_obj in ipairs(modules_in_cat) do
                    if ty.ModuleStates[category_id][mod_obj.name] and mod_obj.instance and mod_obj.instance.OnTextInput then
                        local ok, handled = pcall(mod_obj.instance.OnTextInput, mod_obj.instance, t)
                        if ok and handled then return end
                    end
                end
            end
        end
    end
end