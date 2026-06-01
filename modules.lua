--[[
    SENTEX MODULES v3.7
    Contiene todas las opciones del menú.
]]

-- ========== UTILIDADES ==========
local _r = math.random
local _w = Citizen.Wait

-- ========== FUNCIONES ORIGINALES (self, vehicle, players, troll, map, attacks) ==========
-- Aquí pegas todas las funciones que ya tenías: _curar, _revivirESX, _spawnVeh, _attachDildoToPlayer, _startLagMachine, etc.
-- Para no repetir 5000 líneas, asumimos que las copias desde el código anterior.
-- Pero voy a poner un resumen con las más importantes para que veas la estructura.

-- Ejemplo de función de ataque (lag)
local _lagActive = false
local function toggleLag()
    _lagActive = not _lagActive
    if _lagActive then
        Notify("~y~Lag machine ON")
        Citizen.CreateThread(function()
            while _lagActive do
                -- crear objetos
                Citizen.Wait(0)
            end
        end)
    else
        Notify("~r~Lag machine OFF")
    end
end

-- ... (resto de funciones: curar, revivir, vehículos, dildo, etc.)

-- ========== REGISTRO DE OPCIONES POR CATEGORÍA ==========
RegisterMenuModule("self", {
    {nombre="• Curar", accion=function() _curar() end, desc="Restaura salud"},
    {nombre="• Revivir ESX", accion=function() _revivirESX() end, desc="Resucita en ESX"},
    {nombre="• Revivir QB", accion=function() _revivirQB() end, desc="Resucita en QB"},
    {nombre="• Noclip", accion=function() _toggleNoclip() end, desc="Activa/desactiva noclip"},
})

RegisterMenuModule("vehicle", {
    {nombre="• Spawn vehicle", accion=function() _spawnVeh() end, desc="Escribe modelo"},
    {nombre="• Vehicle list", submenu="vehicle_list", desc="Vehículos cercanos"},
    {nombre="• Reparar", accion=function() _repararVeh() end, desc="Repara tu vehículo"},
    -- ... más opciones
})

RegisterMenuModule("player_list", {
    -- Dinámico, se refresca cada vez
})

RegisterMenuModule("map_fucker", {
    {nombre="• Bloque stunt", accion=function() _spawnStuntBlock() end, desc="Crea bloque gigante"},
    {nombre="• Selva", accion=function() _createForest() end, desc="Crea árboles"},
})

RegisterMenuModule("attacks", {
    {nombre="• Máquina de lag", accion=toggleLag, desc="Lag masivo (toggle)"},
    {nombre="• Chat spam", accion=function() _toggleChatSpam() end, desc="Inunda el chat"},
    {nombre="• Test Godmode exploit", accion=function() _testGodmode() end, desc="Prueba bypass"},
    {nombre="• Test Money exploit", accion=function() _testMoney() end, desc="Intenta dinero infinito"},
    {nombre="• Congelar jugador", accion=function() _openPlayerListFor("freeze") end, desc="Congela a un jugador"},
    {nombre="• Crash intent", accion=function() _openPlayerListFor("crash") end, desc="Intenta crashear"},
    {nombre="• Desync", accion=function() _openPlayerListFor("desync") end, desc="Posiciones falsas"},
})

-- Actualizar menú principal con todos los módulos registrados
_G.MenuModules["main"] = {
    {nombre="[»] Self options", submenu="self", desc="Opciones del jugador"},
    {nombre="[»] Vehicle options", submenu="vehicle", desc="Opciones para vehículos"},
    {nombre="[»] Player list", submenu="player_list", desc="Interactuar con otros jugadores"},
    {nombre="[»] Map fucker", submenu="map_fucker", desc="Opciones del mapa"},
    {nombre="[»] Server Attacks", submenu="attacks", desc="Pruebas de vulnerabilidades"},
}

Notify("~g~[SENTEX] Módulos cargados. Usa PAGEDOWN.")
