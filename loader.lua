--[[
    SENTEX LOADER v3.7 - Stealth Enhanced
]]

local function part(url)
    local p1 = string.sub(url, 1, 40)
    local p2 = string.sub(url, 41)
    return p1 .. p2
end

local CORE_URL = part("https://raw.githubusercontent.com/Sentexz/localhostmenu/refs/heads/main/core.lua")
local MODULES_URL = part("https://raw.githubusercontent.com/Sentexz/localhostmenu/refs/heads/main/modules.lua")

if not Susano or not Susano.HttpGet then
    print("[SENTEX] Error: entorno no soportado")
    return
end

local function randomDelay(min, max)
    Citizen.Wait(math.random(min, max))
end

local function loadingMessage(step, total)
    local msgs = {
        "[*] Estableciendo conexión segura...",
        "[*] Autenticando módulos...",
        "[*] Descomprimiendo librerías...",
        "[*] Verificando integridad...",
        "[*] Cargando interfaces...",
        "[*] Inyectando componentes...",
        "[*] Sincronizando con el servidor...",
        "[*] Preparando entorno gráfico..."
    }
    print(msgs[math.random(#msgs)])
    randomDelay(300, 1000)
end

Citizen.CreateThread(function()
    print("[SENTEX] Inicializando sistema...")
    randomDelay(500, 1500)
    
    loadingMessage(1, 2)
    local status, coreCode = Susano.HttpGet(CORE_URL)
    if status ~= 200 or not coreCode then
        print("[SENTEX] Error crítico (CORE). Código: " .. status)
        return
    end
    local coreFunc, err = load(coreCode)
    if not coreFunc then
        print("[SENTEX] Error compilación core: " .. err)
        return
    end
    pcall(coreFunc)
    print("[SENTEX] Núcleo cargado.")
    randomDelay(400, 900)
    
    loadingMessage(2, 2)
    local status2, modulesCode = Susano.HttpGet(MODULES_URL)
    if status2 ~= 200 or not modulesCode then
        print("[SENTEX] Error crítico (MODULES). Código: " .. status2)
        return
    end
    local modulesFunc, err2 = load(modulesCode)
    if not modulesFunc then
        print("[SENTEX] Error compilación modules: " .. err2)
        return
    end
    pcall(modulesFunc)
    print("[SENTEX] Módulos cargados.")
    
    randomDelay(200, 600)
    print("[SENTEX] Sistema listo. Usa PAGEDOWN.")
end)
