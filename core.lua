--[[
    SENTEX CORE v3.7 - Con NUI (navegador web) para el banner
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

function Notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- ============================================================================
--                    BANNER CON NUI (navegador web)
-- ============================================================================
local bannerBrowser = nil
local bannerTexture = nil
local bannerReady = false
local BANNER_URL = "https://i.ibb.co/cKgX5CGH/resized-512x128.png"

-- Crear navegador y cargar la imagen
Citizen.CreateThread(function()
    -- Esperar a que el juego esté listo
    Citizen.Wait(2000)
    
    -- Crear navegador del tamaño de la imagen (512x128)
    bannerBrowser = CreateBrowser(512, 128, false, false)
    
    -- HTML simple que muestra la imagen centrada
    local html = [[
        <html>
        <head>
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    width: 100%;
                    height: 100%;
                }
                img {
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }
            </style>
        </head>
        <body>
            <img src="]] .. BANNER_URL .. [[" />
        </body>
        </html>
    ]]
    
    -- Convertir HTML a data URL
    local dataUrl = "data:text/html," .. html:gsub(" ", "%%20"):gsub("\n", "%%0A")
    SetBrowserUrl(bannerBrowser, dataUrl)
    
    -- Esperar a que el navegador cargue (tiempo estimado)
    Citizen.Wait(1500)
    
    -- Obtener la textura del navegador
    bannerTexture = GetBrowserTexture(bannerBrowser)
    if bannerTexture then
        bannerReady = true
        print("[SENTEX] Banner NUI cargado correctamente")
    else
        print("[SENTEX] Error: No se pudo obtener textura del navegador")
    end
end)

-- Dibujar el banner
local function DrawBanner(x, y, w, h)
    if bannerReady and bannerTexture then
        DrawSprite(bannerTexture, "browser_texture", x, y, w, h, 0.0, 255, 255, 255, 255)
    else
        -- Fallback mientras carga o si falla
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
--                    NAVEGACIÓN Y DIBUJO (resto del código)
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

function RegisterMenuModule(name, options)
    _G.MenuModules[name] = options
end

-- Menú principal por defecto
RegisterMenuModule("main", {
    {nombre="[»] Cargando módulos...", accion=nil, desc="Espera a que terminen las descargas"}
})

Notify("~b~[SENTEX] Core con NUI cargado.")

-- Tecla PAGEDOWN
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsDisabledControlJustReleased(0, 11) then
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
end)
