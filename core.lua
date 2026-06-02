--[[
    SENTEX CORE v3.7 - Con keybinds, banner desde URL y soporte para toggles
]]

_G.MenuModules = {}
_G.MenuVisible = false
_G.MenuCurrent = "main"
_G.MenuOption = 1
_G.MenuScroll = 0
_G.MenuMaxVisible = 12
_G.MenuDesc = ""

-- Colores
_G.MenuBgColor = {10, 10, 10, 210}
_G.MenuSelectionColor = {225, 17, 79, 220}
_G.MenuSeparatorColor = {80, 80, 90, 100}
_G.MenuPosX = 0.82

-- Keybind para abrir menú (código de tecla, por defecto PAGEDOWN = 11)
local menuToggleKey = 11
local selectingKey = false

function Notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- ============================================================================
--                    BANNER CON IMAGEN DESDE URL (DUI)
-- ============================================================================
local BANNER_URL = "https://i.imgur.com/jnKfAh1.png"
local runtimeTxd = nil
local textureLoaded = false
local bannerReady = false

local function loadBannerFromURL()
    print("[SENTEX] Cargando banner desde: " .. BANNER_URL)
    local duiObj = CreateDui(BANNER_URL, 512, 128)
    if not duiObj then
        print("[SENTEX] ❌ CreateDui falló")
        return false
    end
    local duiHandle = nil
    local attempts = 0
    while attempts < 50 do
        duiHandle = GetDuiHandle(duiObj)
        if type(duiHandle) == "number" and duiHandle ~= 0 then
            break
        end
        Citizen.Wait(100)
        attempts = attempts + 1
    end
    if type(duiHandle) ~= "number" or duiHandle == 0 then
        print("[SENTEX] ❌ No se pudo obtener handle DUI válido")
        return false
    end
    runtimeTxd = CreateRuntimeTxd('sentex_banner_txd')
    if not runtimeTxd then
        print("[SENTEX] ❌ CreateRuntimeTxd falló")
        return false
    end
    local texture = CreateRuntimeTextureFromDuiHandle(runtimeTxd, 'banner_texture', duiHandle)
    if not texture then
        print("[SENTEX] ❌ CreateRuntimeTextureFromDuiHandle falló")
        return false
    end
    textureLoaded = true
    print("[SENTEX] 🎉 Banner cargado exitosamente")
    return true
end

local function waitForBanner()
    for attempt = 1, 3 do
        if loadBannerFromURL() then
            bannerReady = true
            return
        end
        if attempt < 3 then
            print("[SENTEX] Reintentando banner...")
            Citizen.Wait(2000)
        end
    end
    print("[SENTEX] Usando fallback (rectángulo rojo)")
    bannerReady = true
    textureLoaded = false
end

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    waitForBanner()
end)

local function DrawBanner(x, y, w, h)
    if textureLoaded and runtimeTxd then
        DrawSprite(runtimeTxd, 'banner_texture', x, y, w, h, 0.0, 255, 255, 255, 255)
    else
        -- Fallback elegante
        DrawRect(x, y, w, h, 225, 17, 79, 255)
        SetTextFont(1)
        SetTextScale(0.48, 0.48)
        SetTextColour(255, 255, 255, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("SENTEX v3.7 | SECURITY TEST")
        DrawText(x, y - 0.010)
    end
end

-- ============================================================================
--                    SISTEMA DE KEYBIND (cambio de tecla)
-- ============================================================================
local function setMenuKey(keyCode)
    menuToggleKey = keyCode
    Notify("~g~Tecla de menú cambiada a: " .. tostring(keyCode))
end

local function drawKeySelector()
    if not selectingKey then return end
    local screenW, screenH = GetActiveScreenResolution()
    local width = 400
    local height = 130
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    DrawRect(x, y, width, height, 0, 0, 0, 200)
    DrawRect(x, y, width, 5, 225, 17, 79, 255)
    SetTextFont(1)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("CAMBIAR TECLA DEL MENÚ")
    DrawText(x + width/2, y + 25)
    SetTextFont(0)
    SetTextScale(0.35, 0.35)
    SetTextColour(200, 200, 200, 255)
    SetTextEntry("STRING")
    AddTextComponentString("Presiona cualquier tecla...")
    DrawText(x + width/2, y + 60)
    SetTextEntry("STRING")
    AddTextComponentString("(ESC para cancelar)")
    DrawText(x + width/2, y + 90)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if selectingKey then
            drawKeySelector()
            for key = 1, 255 do
                if IsDisabledControlJustPressed(0, key) then
                    if key == 177 then -- BACKSPACE
                        selectingKey = false
                    else
                        setMenuKey(key)
                        selectingKey = false
                    end
                    break
                end
            end
        end
    end
end)

-- ============================================================================
--                    NAVEGACIÓN Y DIBUJO (con toggles)
-- ============================================================================
local function UpdateScroll(totalOpts)
    if totalOpts <= _G.MenuMaxVisible then
        _G.MenuScroll = 0
    else
        if _G.MenuOption < _G.MenuScroll + 1 then
            _G.MenuScroll = _G.MenuOption - 1
        elseif _G.MenuOption > _G.MenuScroll + _G.MenuMaxVisible then
            _G.MenuScroll = _G.MenuOption - _G.MenuMaxVisible
        end
        if _G.MenuScroll < 0 then _G.MenuScroll = 0 end
        if _G.MenuScroll > totalOpts - _G.MenuMaxVisible then
            _G.MenuScroll = totalOpts - _G.MenuMaxVisible
        end
    end
end

local function DrawItem(x, yCenter, w, opt, isSelected)
    local sepX = x - w / 2 + 0.02
    DrawRect(sepX, yCenter, 0.001, 0.03, _G.MenuSeparatorColor[1], _G.MenuSeparatorColor[2], _G.MenuSeparatorColor[3], _G.MenuSeparatorColor[4])
    
    local cleanText = opt.nombre:gsub("[%[»%]•]", ""):gsub("^%s*", "")
    SetTextFont(0)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(false)
    SetTextEntry("STRING")
    AddTextComponentString(cleanText)
    DrawText(x - w / 2 + 0.04, yCenter - 0.0125)
    
    if opt.toggle then
        local rightText = opt.toggleValue and "✔️ ON" or "❌ OFF"
        SetTextFont(0)
        SetTextScale(0.35, 0.35)
        SetTextColour(200, 200, 200, 200)
        SetTextCentre(false)
        SetTextEntry("STRING")
        AddTextComponentString(rightText)
        DrawText(x + w / 2 - 0.09, yCenter - 0.0125)
    else
        SetTextFont(0)
        SetTextScale(0.45, 0.45)
        SetTextColour(200, 200, 200, 200)
        SetTextCentre(false)
        SetTextEntry("STRING")
        AddTextComponentString("→")
        DrawText(x + w / 2 - 0.03, yCenter - 0.0125)
    end
end

function DrawMenu()
    local w = 0.23
    local x = _G.MenuPosX
    local y = 0.2
    local headerH = 0.09
    local optH = 0.042
    local lineH = 0.032
    local padDesc = 0.005

    local opts = _G.MenuModules[_G.MenuCurrent]
    if not opts then
        _G.MenuCurrent = "main"
        opts = _G.MenuModules["main"]
    end
    if not opts then return end
    local totalOpts = #opts
    UpdateScroll(totalOpts)
    local visibleOpts = math.min(totalOpts - _G.MenuScroll, _G.MenuMaxVisible)

    local descLines = {}
    if _G.MenuDesc and _G.MenuDesc ~= "" then
        local tmp = _G.MenuDesc
        while #tmp > 50 and #descLines < 2 do
            local cut = tmp:sub(1, 50):match("^.*[ ,]") or tmp:sub(1, 50)
            table.insert(descLines, cut)
            tmp = tmp:sub(#cut + 1)
        end
        if #tmp > 0 and #descLines < 2 then
            table.insert(descLines, tmp)
        end
    end
    local descH = #descLines * lineH + padDesc * 2
    if #descLines == 0 then descH = 0.02 end

    local totalH = headerH + (visibleOpts * optH) + descH + 0.015
    local startY = y

    DrawRect(x, startY + totalH / 2, w, totalH, _G.MenuBgColor[1], _G.MenuBgColor[2], _G.MenuBgColor[3], _G.MenuBgColor[4])
    DrawBanner(x, startY + headerH / 2, w, headerH)

    local optsY = startY + headerH + 0.008
    for i = 1, visibleOpts do
        local idx = _G.MenuScroll + i
        local opt = opts[idx]
        if opt then
            local yCenter = optsY + (i - 1) * optH + optH / 2
            local isSelected = (idx == _G.MenuOption)
            if isSelected then
                DrawRect(x, yCenter, w - 0.02, optH - 0.004, _G.MenuSelectionColor[1], _G.MenuSelectionColor[2], _G.MenuSelectionColor[3], _G.MenuSelectionColor[4])
            end
            DrawItem(x, yCenter, w, opt, isSelected)
            if isSelected then
                _G.MenuDesc = (opt.desc or "Selecciona una opción") .. " "
            end
        end
    end

    local descY = startY + headerH + (visibleOpts * optH) + 0.008
    for i, line in ipairs(descLines) do
        local lineY = descY + padDesc + (i - 1) * lineH + lineH / 2 - 0.008
        SetTextFont(0)
        SetTextScale(0.3, 0.3)
        SetTextColour(200, 200, 210, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString(line)
        DrawText(x, lineY)
    end

    local counter = _G.MenuOption .. "/" .. totalOpts
    SetTextFont(0)
    SetTextScale(0.25, 0.25)
    SetTextColour(150, 150, 160, 255)
    SetTextCentre(false)
    SetTextEntry("STRING")
    AddTextComponentString(counter)
    DrawText(x + w / 2 - 0.02, startY + totalH - 0.02)

    if totalOpts > _G.MenuMaxVisible then
        local scrollAreaY = startY + headerH + 0.008
        local scrollAreaH = visibleOpts * optH
        local thumbHeight = (visibleOpts / totalOpts) * scrollAreaH
        local thumbPos = (_G.MenuScroll / (totalOpts - visibleOpts)) * (scrollAreaH - thumbHeight)
        local barX = x + w / 2 - 0.008
        DrawRect(barX, scrollAreaY + scrollAreaH / 2, 0.003, scrollAreaH, 40, 40, 50, 180)
        DrawRect(barX, scrollAreaY + thumbHeight / 2 + thumbPos, 0.003, thumbHeight, 225, 17, 79, 220)
    end
end

-- ============================================================================
--                    BUCLE PRINCIPAL Y REGISTRO DE MÓDULOS
-- ============================================================================
function RegisterMenuModule(name, options)
    _G.MenuModules[name] = options
end

-- Módulo principal por defecto
RegisterMenuModule("main", {
    {nombre="[»] Cargando módulos...", accion=nil, desc="Espera a que terminen las descargas"}
})

-- Agregar opción de keybind en Settings (se añade dinámicamente cuando exista el módulo)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if _G.MenuModules["settings"] then
            -- Buscar si ya existe la opción de keybind
            local exists = false
            for _, opt in ipairs(_G.MenuModules["settings"]) do
                if opt.nombre == "• Cambiar tecla del menú" then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(_G.MenuModules["settings"], {
                    nombre = "• Cambiar tecla del menú",
                    accion = function()
                        selectingKey = true
                    end,
                    desc = "Asigna una nueva tecla para abrir/cerrar el menú"
                })
            end
            break
        end
    end
end)

-- Bucle de navegación del menú
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if _G.MenuVisible then
            DrawMenu()
            local opts = _G.MenuModules[_G.MenuCurrent]
            if opts then
                local maxOpt = #opts
                if IsDisabledControlJustReleased(0, 172) then
                    _G.MenuOption = _G.MenuOption - 1
                    if _G.MenuOption < 1 then _G.MenuOption = maxOpt end
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                elseif IsDisabledControlJustReleased(0, 173) then
                    _G.MenuOption = _G.MenuOption + 1
                    if _G.MenuOption > maxOpt then _G.MenuOption = 1 end
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                elseif IsDisabledControlJustReleased(0, 191) then
                    local sel = opts[_G.MenuOption]
                    if sel then
                        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                        if sel.submenu then
                            _G.MenuCurrent = sel.submenu
                            _G.MenuOption = 1
                            _G.MenuScroll = 0
                        elseif sel.toggle then
                            sel.toggleValue = not sel.toggleValue
                            if sel.onToggle then sel.onToggle(sel.toggleValue) end
                        elseif sel.accion then
                            local ok, err = pcall(sel.accion)
                            if not ok then Notify("~b~[SENTEX] Error: " .. tostring(err)) end
                        end
                    end
                elseif IsDisabledControlJustReleased(0, 177) then
                    if _G.MenuCurrent == "main" then
                        _G.MenuVisible = false
                        PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    else
                        _G.MenuCurrent = "main"
                        _G.MenuOption = 1
                        _G.MenuScroll = 0
                        PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    end
                end
            end
        end
    end
end)

-- Detectar tecla de apertura (con la tecla configurable)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if not selectingKey then
            if IsDisabledControlJustReleased(0, menuToggleKey) then
                _G.MenuVisible = not _G.MenuVisible
                if _G.MenuVisible then
                    _G.MenuOption = 1
                    _G.MenuCurrent = "main"
                    _G.MenuScroll = 0
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                else
                    PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                end
            end
        end
    end
end)

Notify("~b~[SENTEX] Core con keybinds y banner cargado. Usa la tecla asignada (PAGEDOWN por defecto).")
