--[[
    SENTEX CORE v3.7 - Banner DUI con depuración (para Susano)
]]

_G.MenuModules = {}
_G.MenuVisible = false
_G.MenuCurrent = "main"
_G.MenuOption = 1
_G.MenuScroll = 0
_G.MenuMaxVisible = 12
_G.MenuDesc = ""

_G.MenuBgColor = {10, 10, 10, 210}
_G.MenuSelectionColor = {225, 17, 79, 220}
_G.MenuSeparatorColor = {80, 80, 90, 100}
_G.MenuPosX = 0.82

function Notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- ============================================================================
--                    BANNER CON DUI + DEPURACIÓN + FALLBACK
-- ============================================================================
-- CAMBIA ESTA URL POR UNA IMAGEN PNG DIRECTA DE GITHUB RAW
local BANNER_URL = "https://raw.githubusercontent.com/Sentexz/localhostmenu/main/panel.png"
-- Si no tienes panel.png en tu repo, usa esta de prueba (cambiar a una que funcione)
-- local BANNER_URL = "https://i.imgur.com/jnKfAh1.png"

local runtimeTxd = nil
local textureLoaded = false
local bannerReady = false
local duiHandle = nil
local duiObj = nil

local function loadBannerFromURL()
    print("[SENTEX] Cargando banner desde: " .. BANNER_URL)
    
    -- Crear DUI
    duiObj = CreateDui(BANNER_URL, 512, 128)
    if not duiObj then
        print("[SENTEX] ❌ Error: CreateDui falló")
        return false
    end
    print("[SENTEX] ✅ DUI creado correctamente")
    
    -- Obtener handle (con espera activa)
    local attempts = 0
    duiHandle = 0
    while attempts < 30 and duiHandle == 0 do
        duiHandle = GetDuiHandle(duiObj)
        if duiHandle == 0 then
            Citizen.Wait(100)
            attempts = attempts + 1
        end
    end
    
    if duiHandle == 0 then
        print("[SENTEX] ❌ Error: No se pudo obtener el handle del DUI después de " .. attempts .. " intentos")
        return false
    end
    print("[SENTEX] ✅ Handle DUI obtenido: " .. tostring(duiHandle))
    
    -- Crear TXD runtime
    runtimeTxd = CreateRuntimeTxd('sentex_banner_txd')
    if not runtimeTxd then
        print("[SENTEX] ❌ Error: CreateRuntimeTxd falló")
        return false
    end
    print("[SENTEX] ✅ Runtime TXD creado")
    
    -- Crear textura desde DUI handle
    local texture = CreateRuntimeTextureFromDuiHandle(runtimeTxd, 'banner_texture', duiHandle)
    if not texture then
        print("[SENTEX] ❌ Error: CreateRuntimeTextureFromDuiHandle falló")
        return false
    end
    print("[SENTEX] ✅ Textura runtime creada")
    
    textureLoaded = true
    print("[SENTEX] 🎉 Banner cargado exitosamente")
    return true
end

-- Carga con reintentos
local function waitForBanner()
    for attempt = 1, 3 do
        print("[SENTEX] Intento " .. attempt .. "/3")
        if loadBannerFromURL() then
            bannerReady = true
            return
        end
        if attempt < 3 then
            print("[SENTEX] Reintentando en 2 segundos...")
            Citizen.Wait(2000)
        end
    end
    print("[SENTEX] ❌ No se pudo cargar el banner, usando fallback")
    bannerReady = true
    textureLoaded = false
end

-- Inicializar banner al inicio
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    waitForBanner()
end)

-- Dibujo del banner (con fallback)
local function DrawBanner(x, y, w, h)
    if textureLoaded and runtimeTxd then
        -- Intentar dibujar la textura
        DrawSprite(runtimeTxd, 'banner_texture', x, y, w, h, 0.0, 255, 255, 255, 255)
        print("[SENTEX] DrawSprite ejecutado con textura")
    else
        -- Fallback: rectángulo rojo con texto
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
--                    RESTO DEL MENÚ (NAVEGACIÓN, ETC.)
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

function RegisterMenuModule(name, options)
    _G.MenuModules[name] = options
end

RegisterMenuModule("main", {
    {nombre="[»] Cargando módulos...", accion=nil, desc="Espera a que terminen las descargas"}
})

Notify("~b~[SENTEX] Core con depuración cargado.")

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsDisabledControlJustReleased(0, 11) then
            if not bannerReady then
                Notify("~r~Menú aún no listo. Espera a que cargue el banner.")
            else
                _G.MenuVisible = not _G.MenuVisible
                if _G.MenuVisible then
                    _G.MenuOption = 1
                    _G.MenuCurrent = "main"
                    _G.MenuScroll = 0
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    Notify("~b~[SENTEX] Menú abierto.")
                else
                    PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    Notify("~b~[SENTEX] Menú cerrado.")
                end
            end
        end
    end
end)
