--[[
    SENTEX LOADER v3.7 - Professional Edition
    Pantalla de carga nativa con barra de progreso
]]

local CORE_URL = "https://raw.githubusercontent.com/Sentexz/localhostmenu/refs/heads/main/core.lua"
local MODULES_URL = "https://raw.githubusercontent.com/Sentexz/localhostmenu/refs/heads/main/modules.lua"

if not Susano or not Susano.HttpGet then
    print("[SENTEX] Susano.HttpGet no disponible")
    return
end

local steps = {
    { text = "Conectando con el servidor...", progress = 10 },
    { text = "Descargando núcleo del menú...", progress = 30 },
    { text = "Cargando core.lua...", progress = 50 },
    { text = "Descargando módulos...", progress = 70 },
    { text = "Cargando modules.lua...", progress = 85 },
    { text = "Inicializando menú...", progress = 100 }
}

local currentStep = 1
local loadingProgress = 0
local loadingActive = true
local loadSuccess = false

-- Función para dibujar la pantalla de carga
local function drawLoadingScreen(stepText, progress)
    -- Fondo general
    DrawRect(0.5, 0.5, 0.6, 0.4, 0, 0, 0, 200)
    
    -- Borde decorativo
    DrawRect(0.5, 0.5, 0.58, 0.38, 225, 17, 79, 50)
    
    -- Logo / Título
    SetTextFont(1)
    SetTextScale(0.8, 0.8)
    SetTextColour(225, 17, 79, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("SENTEX MENU")
    DrawText(0.5, 0.35)
    
    -- Versión
    SetTextFont(0)
    SetTextScale(0.3, 0.3)
    SetTextColour(200, 200, 200, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("v3.7 Security Edition")
    DrawText(0.5, 0.39)
    
    -- Línea divisoria
    DrawRect(0.5, 0.42, 0.4, 0.002, 225, 17, 79, 150)
    
    -- Mensaje de estado actual
    SetTextFont(0)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(stepText)
    DrawText(0.5, 0.48)
    
    -- Barra de progreso (fondo)
    DrawRect(0.5, 0.55, 0.4, 0.03, 30, 30, 30, 200)
    -- Barra de progreso (relleno)
    local barWidth = 0.4 * (progress / 100)
    DrawRect(0.5 - (0.4/2) + (barWidth/2), 0.55, barWidth, 0.03, 225, 17, 79, 255)
    
    -- Porcentaje
    SetTextFont(0)
    SetTextScale(0.25, 0.25)
    SetTextColour(200, 200, 200, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(progress .. "%")
    DrawText(0.5, 0.59)
    
    -- Créditos
    SetTextFont(0)
    SetTextScale(0.2, 0.2)
    SetTextColour(150, 150, 150, 200)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("github.com/Sentexz/localhostmenu")
    DrawText(0.5, 0.72)
    
    -- Aviso de pruebas
    SetTextFont(4)
    SetTextScale(0.25, 0.25)
    SetTextColour(255, 100, 100, 200)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("MODO PRUEBAS - SEGURIDAD")
    DrawText(0.5, 0.78)
end

-- Función para actualizar la pantalla de carga
local function updateLoading(stepIndex, customProgress)
    if stepIndex <= #steps then
        currentStep = stepIndex
        loadingProgress = customProgress or steps[stepIndex].progress
    end
end

-- Función para descargar y ejecutar scripts con reporte de progreso
local function loadScript(url, stepIndex, successMessage)
    updateLoading(stepIndex, steps[stepIndex].progress - 5)
    Citizen.Wait(100)
    
    local status, code = Susano.HttpGet(url)
    if status ~= 200 or not code then
        print("[SENTEX] Error HTTP " .. status .. " descargando: " .. url)
        return false
    end
    
    updateLoading(stepIndex, steps[stepIndex].progress)
    Citizen.Wait(100)
    
    local func, err = load(code)
    if not func then
        print("[SENTEX] Error compilando: " .. tostring(err))
        return false
    end
    
    local ok, execErr = pcall(func)
    if not ok then
        print("[SENTEX] Error ejecutando: " .. tostring(execErr))
        return false
    end
    
    print("[SENTEX] " .. successMessage)
    return true
end

-- Hilo principal de carga con pantalla visual
Citizen.CreateThread(function()
    -- Mostrar pantalla de carga
    while loadingActive do
        Citizen.Wait(0)
        drawLoadingScreen(steps[currentStep].text, loadingProgress)
    end
end)

-- Hilo de carga real
Citizen.CreateThread(function()
    -- Paso 1: Conectando
    updateLoading(1)
    Citizen.Wait(500)
    
    -- Paso 2 y 3: core.lua
    updateLoading(2)
    Citizen.Wait(300)
    local coreOk = loadScript(CORE_URL, 3, "Núcleo cargado correctamente")
    if not coreOk then
        loadingActive = false
        print("[SENTEX] Error fatal: no se pudo cargar core.lua")
        return
    end
    
    -- Pequeña pausa para que core se estabilice
    updateLoading(3, 55)
    Citizen.Wait(500)
    
    -- Paso 4 y 5: modules.lua
    updateLoading(4)
    Citizen.Wait(300)
    local modulesOk = loadScript(MODULES_URL, 5, "Módulos cargados correctamente")
    if not modulesOk then
        loadingActive = false
        print("[SENTEX] Error fatal: no se pudo cargar modules.lua")
        return
    end
    
    -- Paso 6: Finalizando
    updateLoading(6, 95)
    Citizen.Wait(500)
    
    -- Carga completada
    loadingProgress = 100
    updateLoading(6, 100)
    Citizen.Wait(800)
    
    -- Ocultar pantalla de carga
    loadingActive = false
    
    -- Limpiar pantalla (dibujar un frame negro para borrar)
    for i = 1, 3 do
        DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 0)
        Citizen.Wait(0)
    end
    
    print("[SENTEX] ========================================")
    print("[SENTEX] SENTEX MENU v3.7 CARGADO COMPLETAMENTE")
    print("[SENTEX] Presiona PAGEDOWN para abrir el menú")
    print("[SENTEX] ========================================")
    
    -- Notificación final (si el core ya tiene Notify, la usa; si no, no pasa nada)
    pcall(function()
        Notify("~g~SENTEX MENU v3.7 cargado. Usa PAGEDOWN.")
    end)
end)
