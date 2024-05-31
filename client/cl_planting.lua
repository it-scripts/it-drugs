local growZones = {}

for k, v in pairs(Config.Zones) do
    growZones[k] = PolyZone:Create(v.coords, {
        name= k,
        minZ = 0.0,
        maxZ = 200.0,
        debugPoly = Config.DebugPoly,
    })
end

-- Functions
local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

local RayCastCamera = function(dist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * dist)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

local GetGroundHash = function(ped)
    local posped = GetEntityCoords(ped)
    local num =
        StartShapeTestCapsule(posped.x, posped.y, posped.z + 4, posped.x, posped.y, posped.z - 2.0, 2, 1, ped, 7)
    local arg1, arg2, arg3, arg4, arg5 = GetShapeTestResultEx(num)
    return arg5
end

local getCurrentZone = function(coords, plantItem)
    for k, v in pairs(growZones) do
        if growZones[k]:isPointInside(vector3(coords.x, coords.y, coords.z)) then
            if Config.Debug then lib.print.info('Inside Zone: ', k) end -- DEBUG
            for _, drug in ipairs(Config.Zones[k].exclusive) do
                if Config.Debug then lib.print.info('Drugs: ', Config.Zones[k].exclusive) end -- DEBUG
                if drug == plantItem then
                    if Config.Debug then lib.print.info('Zone: ', k) end -- DEBUG
                    return k
                end
            end
        end
    end
    return nil
end

local plantSeed = function(ped, plant, plantInfos, plantItem, coords, metadata)

    -- check for near plants
    local plants = lib.callback.await('it-drugs:server:getPlants', false)

    if plants ~= nil then
        for k, v in pairs(plants) do
            if #(vector3(coords.x, coords.y, coords.z) - vector3(v.coords.x, v.coords.y, v.coords.z)) <= Config.PlantDistance then
                ShowNotification(nil, _U('NOTIFICATION__TO__NEAR'), "error")
                DeleteObject(plant)
                return
            end
        end
    end

    if Config.OnlyAllowedGrounds then
        local groundHash = GetGroundHash(plant)
        local canplant = false
        if Config.Debug then lib.print.info('Current Ground Hash: ' .. groundHash) end -- DEBUG 
        for _, ground in pairs(Config.AllowedGrounds) do
            if groundHash == ground then
                canplant = true
            end
        end

        if not canplant then
            ShowNotification(nil, _U('NOTIFICATION__CANT__PLACE'), "error")
            DeleteObject(plant)
            return
        end
    end

    local zone = getCurrentZone(coords, plantItem)
    if Config.OnlyZones then
        if zone == nil then
            ShowNotification(nil, _U('NOTIFICATION__CANT__PLACE'), "error")
            DeleteObject(plant)
            return
        end
    end

    DeleteObject(plant)

    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while 
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do 
        Wait(0) 
    end

    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)


    if lib.progressBar({
        duration = plantInfos.time,
        label = _U('PROGRESSBAR__SPAWN__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    }) then
        TriggerServerEvent('it-drugs:server:createNewPlant', coords, plantItem, zone, metadata)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')

    end
end

-- Events
RegisterNetEvent('it-drugs:client:useSeed', function(plantItem, metadata)

    if Config.Debug then lib.print.info('Planting: ', plantItem) end -- DEBUG 

    local ped = PlayerPedId()
    local plantInfos = Config.Plants[plantItem]
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then
        ShowNotification(nil, _U('NOTIFICATION__IN__VEHICLE'), "error")
        return
    end

    local ownedPlants = lib.callback.await('it-drugs:server:getPlantsOwned', false)
    if ownedPlants ~= nil then
        if #ownedPlants >= Config.PlayerPlantLimit then
            ShowNotification(nil, _U('NOTIFICATION__MAX__PLANTS'), "error")
            return
        end
    end

    local hashModel = GetHashKey(Config.PlantTypes[plantInfos.plantType][1][1])
    local customOffset = Config.PlantTypes[plantInfos.plantType][1][2]
    RequestModel(hashModel)
    while not HasModelLoaded(hashModel) do Wait(0) end

    lib.showTextUI(_U('INTERACTION__PLACING__TEXT'), {
        position = "left-center",
        icon = "spoon",
    })

    -- Placing the plant on the ground and waiting for the player to press [E] to plant it
    local hit, dest, _, _ = RayCastCamera(Config.rayCastingDistance)
    local coords = GetEntityCoords(ped)
    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)

    local plant = CreateObject(hashModel, coords.x, coords.y, groundZ + customOffset, false, false, false)
    SetEntityCollision(plant, false, false)
    SetEntityAlpha(plant, 150, true)
    
    local planted = false
    while not planted do
        Wait(0)
        hit, dest, _, _ = RayCastCamera(Config.rayCastingDistance)
        if hit == 1 then
            SetEntityCoords(plant, dest.x, dest.y, dest.z + customOffset)
        
        -- [E] To spawn plant
            if IsControlJustPressed(0, 38) then
                if Config.Debug then lib.print.info('Control 38 pressed') end -- DEBUG 
                planted = true
                lib.hideTextUI()

                plantSeed(ped, plant, plantInfos, plantItem, dest, metadata)
                return
            end

            -- [G] To destroy plant
            if IsControlJustPressed(0, 47) then
                if Config.Debug then lib.print.info('Control 47 pressed') end -- DEBUG
                lib.hideTextUI()
                planted = true
                DeleteObject(plant)
                return
            end
        else

            coords = GetEntityCoords(ped)
            local forardVector = GetEntityForwardVector(ped)
            _, groundZ = GetGroundZFor_3dCoord(coords.x + (forardVector.x * .5), coords.y + (forardVector.y * .5), coords.z + (forardVector.z * .5), true)
            
            SetEntityCoords(plant, coords.x + (forardVector.x * .5), coords.y + (forardVector.y * .5), groundZ + customOffset)
            if IsControlJustPressed(0, 38) then
                planted = true
                local coords = GetEntityCoords(plant)
                plantSeed(ped, plant, plantInfos, plantItem, vector3(coords.x, coords.y, coords.z + (math.abs(customOffset))), metadata)
                lib.hideTextUI()
                return
            end
            if IsControlJustPressed(0, 47) then
                if Config.Debug then lib.print.info('Control 47 pressed') end -- DEBUG
                planted = true
                lib.hideTextUI()
                DeleteObject(plant)
                return
            end
        end
    end
end)

RegisterNetEvent('it-drugs:client:checkPlant', function(data)
    local netId = NetworkGetNetworkIdFromEntity(data.entity)
    lib.callback('it-drugs:server:getPlantData', false, function(result)
        if not result then return end
        if Config.Debug then lib.print.info('Checking Data:', result) end -- DEBUG
        -- Find event in client/cl_menus.lua
        TriggerEvent('it-drugs:client:showPlantMenu', result)
    end, netId)
end)

RegisterNetEvent('it-drugs:client:harvestPlant', function(args)

    local type = args.type
    local entity = args.entity

    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)

    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while 
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do 
        Wait(0) 
    end
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)

    if lib.progressBar({
        duration = Config.Plants[type].time,
        label = _U('PROGRESSBAR__HARVEST__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    }) then
        TriggerServerEvent('it-drugs:server:harvestPlant', entity)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        ShowNotification(nil, _U('NOTIFICATION_CANCELED'), "error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')

    end
end)

local giveWater = function(args)
    local item = args.item
    local type = args.type
    local entity = args.entity

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local model = 'prop_wateringcan'
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)
    RequestModel(model)
    RequestNamedPtfxAsset('core')
    while not HasModelLoaded(model) or not HasNamedPtfxAssetLoaded('core') do Wait(0) end
    SetPtfxAssetNextCall('core')
    local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.4, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
    local effect = StartParticleFxLoopedOnEntity('ent_sht_water', created_object, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)

    if lib.progressBar({
        duration = Config.Plants[type].time,
        label = _U('PROGRESSBAR__SOAK__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'weapon@w_sp_jerrycan',
            clip = 'fire',
        },
    }) then
        TriggerServerEvent('it-drugs:server:plantTakeCare', entity, item)
        ClearPedTasks(ped)
        DeleteEntity(created_object)
        StopParticleFxLooped(effect, 0)
    else
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "error")
        ClearPedTasks(ped)
        DeleteEntity(created_object)
        StopParticleFxLooped(effect, 0)
    end
end

local giveFertilizer = function(args)
    local item = args.item
    local type = args.type
    local entity = args.entity

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local model = 'w_am_jerrycan_sf'
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.3, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
    
    if lib.progressBar({
        duration = Config.Plants[type].time,
        label = _U('PROGRESSBAR__FERTILIZE__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'weapon@w_sp_jerrycan',
            clip = 'fire',
        },
    }) then
        TriggerServerEvent('it-drugs:server:plantTakeCare', entity, item)
        ClearPedTasks(ped)
        DeleteEntity(created_object)
    else
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "error")
        ClearPedTasks(ped)
        DeleteEntity(created_object)
    end
end

RegisterNetEvent('it-drugs:client:useItem', function (args)
    local item = args.item

    if not it.hasItem(item, 1 ) then
        ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "error")
        return
    end

    local itemInfos = Config.Items[item]
    if itemInfos.water ~= 0 then
        giveWater(args)
    elseif itemInfos.fertilizer ~= 0 then
        giveFertilizer(args)
    end
end)

RegisterNetEvent('it-drugs:client:destroyPlant', function(args)

    local type = args.type
    local entity = args.entity

    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)

    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while 
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do 
        Wait(0) 
    end
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)

    if lib.progressBar({
        duration = Config.Plants[type].time,
        label = _U('PROGRESSBAR__DESTROY__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    }) then
        TriggerServerEvent('it-drugs:server:destroyPlant', {entity = entity})
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end
end)

RegisterNetEvent('it-drugs:client:startPlantFire', function(coords)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    if #(pedCoords - vector3(coords.x, coords.y, coords.z)) > 300 then return end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end
    SetPtfxAssetNextCall('core')
    local effect = StartParticleFxLoopedAtCoord('ent_ray_paleto_gas_flames', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.6, false, false, false, false)
    Wait(Config.FireTime)
    StopParticleFxLooped(effect, 0)
end)