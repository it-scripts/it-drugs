local growZones = {}

--- Create the zones for the plants 
for k, v in pairs(Config.Zones) do
    local coords = {}
    for _, point in ipairs(v.points) do
        table.insert(coords, vector3(point.x, point.y, point.z))
    end

    growZones[k] = lib.zones.poly({
        points = coords,
        thickness = v.thickness,
        debug = Config.DebugPoly,
    })
end

--- Math function to convert rotation to direction
---@param rot vector3
---@return vector3
local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

--- Create a new raycast camera
---@param dist number
---@return boolean|integer: 0 = hit, 1 = no hit
---@return vector3: end position
---@return integer: entity hit
---@return vector3: surface normal
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

--- Get the ground hash for a location
---@param coords vector3
---@return integer
local GetGroundHash = function(coords)
    local shapeTestCapsule =
        StartShapeTestCapsule(coords.x, coords.y, coords.z + 4, coords.x, coords.y, coords.z - 2.0, 2, 1, 0, 7)
    local _, _, _, _, groundHash = GetShapeTestResultEx(shapeTestCapsule)
    return groundHash
end

local function checkforZones(coords, targetZones)
    if not targetZones or #targetZones == 0 then return nil end
    for _, targetZone in pairs(targetZones) do
        for id, zone in pairs(growZones) do
            if zone:contains(vector3(coords.x, coords.y, coords.z)) then
                if id == targetZone then
                    return id
                end
            end
        end      
    end
    return nil
end

--- Plant a new seed
---@param ped number: Current player ped
---@param plant number: Current plant object
---@param plantInfos table: Plant infos
---@param plantItem string: Plant item
---@param coords vector3: Plant coords
---@param metadata table|nil: Plant metadata
local function plantSeed(ped, plant, plantInfos, plantItem, coords, metadata)

    -- check for near plants
    local plants = lib.callback.await('it-drugs:server:getPlants', false)

    -- Check if the current plant is near another plant
    if plants ~= nil then
        for _, v in pairs(plants) do
            local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(v.coords.x, v.coords.y, v.coords.z))
            if distance <= Config.PlantDistance then
                ShowNotification(nil, _U('NOTIFICATION__TO__NEAR'), "Error")
                DeleteObject(plant)
                return
            end
        end
    end

    if Config.OnlyAllowedGrounds then
        local groundHash = GetGroundHash(coords)
        local canplant = false
        if Config.Debug then lib.print.info('Current Ground Hash: ' .. groundHash) end -- DEBUG 
        for _, ground in pairs(Config.AllowedGrounds) do
            if groundHash == ground then
                canplant = true
            end
        end

        if not canplant then
            ShowNotification(nil, _U('NOTIFICATION__CANT__PLACE'), "Error")
            DeleteObject(plant)
            return
        end
    end

    local zone = checkforZones(coords, plantInfos.zones)
    if Config.Debug then lib.print.info('[plantSeed] - current Zone:', zone) end -- DEBUG
    if plantInfos.onlyZone then
        if zone == nil then
            ShowNotification(nil, _U('NOTIFICATION__CANT__PLACE'), "Error")
            DeleteObject(plant)
            return
        end
    end

    if plantInfos.reqItems and plantInfos.reqItems["planting"] ~= nil then
        for item, itemData in pairs(plantInfos.reqItems["planting"]) do
            if Config.Debug then lib.print.info('Checking for item: ' .. item) end -- DEBUG
            if not exports.it_bridge:HasItem(item, itemData.amount or 1) then
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")
                DeleteObject(plant)
                TriggerEvent('it-drugs:client:syncRestLoop', false)
                return
            end
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
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, false, false)


    if ShowProgressBar({
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
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end

    TriggerEvent('it-drugs:client:syncRestLoop', false)
end

-- Events
RegisterNetEvent('it-drugs:client:useSeed', function(plantItem, metadata)

    --TODO: Edit debug log
    if Config.Debug then lib.print.info('Planting: ', plantItem) end -- DEBUG 

    local ped = PlayerPedId()
    local plantInfos = Config.Plants[plantItem]

    -- Check if the player is in a vehicle
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then
        ShowNotification(nil, _U('NOTIFICATION__IN__VEHICLE'), "Error")
        return
    end

    -- Get the player's owned plants
    local ownedPlants = lib.callback.await('it-drugs:server:getPlantByOwner', false)

    if Config.Debug then lib.print.info('Owned Plants: ', ownedPlants) end-- DEBUG

    if ownedPlants ~= nil then

        local plantCount = 0
        for _, plant in pairs(ownedPlants) do
            if plant.seed == plantItem then
                plantCount = plantCount + 1
            end
        end

        if plantCount >= Config.PlayerPlantLimit then
            ShowNotification(nil, _U('NOTIFICATION__MAX__PLANTS'), "Error")
            
        end
    end

    local hashModel = GetHashKey(Config.PlantTypes[plantInfos.plantType][1][1])
    local customOffset = Config.PlantTypes[plantInfos.plantType][1][2]
    RequestModel(hashModel)
    while not HasModelLoaded(hashModel) do Wait(0) end

    exports.it_bridge:ShowTextUI(_U('INTERACTION__PLACING__TEXT'), {
        position = "left",
        icon = "cannabis",
        color = "info",
        playSound = false,
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
                exports.it_bridge:CloseTextUI(_U('INTERACTION__PLACING__TEXT'))

                plantSeed(ped, plant, plantInfos, plantItem, dest, metadata)
                return
            end

            -- [G] To destroy plant
            if IsControlJustPressed(0, 47) then
                if Config.Debug then lib.print.info('Control 47 pressed') end -- DEBUG
                exports.it_bridge:CloseTextUI(_U('INTERACTION__PLACING__TEXT'))
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
                exports.it_bridge:CloseTextUI(_U('INTERACTION__PLACING__TEXT'))
                return
            end
            if IsControlJustPressed(0, 47) then
                if Config.Debug then lib.print.info('Control 47 pressed') end -- DEBUG
                planted = true
                exports.it_bridge:CloseTextUI(_U('INTERACTION__PLACING__TEXT'))
                DeleteObject(plant)
                TriggerEvent('it-drugs:client:syncRestLoop', false)
                return
            end
        end
    end
end)

RegisterNetEvent('it-drugs:client:harvestPlant', function(args)

    local plantData = args.plantData
    local entity = NetworkGetEntityFromNetworkId(plantData.netId)

    plantData.reqItems = Config.Plants[plantData.seed].reqItems

    if plantData.reqItems and plantData.reqItems["harvesting"] ~= nil then
        for item, itemData in pairs(plantData.reqItems["harvesting"]) do
            if Config.Debug then lib.print.info('Checking for item: ' .. item) end -- DEBUG
            if not exports.it_bridge:HasItem(item, itemData.amount or 1) then
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")
                TriggerEvent('it-drugs:client:syncRestLoop', false)
                return
            end
        end
    end

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
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, false, false)

    if ShowProgressBar({
        duration = Config.Plants[plantData.seed].time,
        label = _U('PROGRESSBAR__HARVEST__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    }) then
        TriggerServerEvent('it-drugs:server:harvestPlant', plantData.id)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end)

local giveWater = function(args)
    local item = args.item
    local plantData = args.plantData

    local entity = NetworkGetEntityFromNetworkId(plantData.netId)

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

    if ShowProgressBar({
        duration = Config.Plants[plantData.seed].time,
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
        TriggerServerEvent('it-drugs:server:plantTakeCare', plantData.id, item)
        ClearPedTasks(ped)
        DeleteEntity(created_object)
        StopParticleFxLooped(effect, 0)
    else
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        DeleteEntity(created_object)
        StopParticleFxLooped(effect, 0)
    end
end

local giveFertilizer = function(args)
    local item = args.item
    local plantData = args.plantData

    local entity = NetworkGetEntityFromNetworkId(plantData.netId)

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local model = 'w_am_jerrycan_sf'
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.3, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)

    if ShowProgressBar({
        duration = Config.Plants[plantData.seed].time,
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
        TriggerServerEvent('it-drugs:server:plantTakeCare', plantData.id, item)
        ClearPedTasks(ped)
        DeleteEntity(created_object)
    else
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        DeleteEntity(created_object)
    end
end

RegisterNetEvent('it-drugs:client:useItem', function (args)
    local item = args.item

    if not exports.it_bridge:HasItem(item, 1) then
        ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")
        return
    end

    local itemInfos = Config.Items[item]
    if itemInfos.water ~= 0 then
        giveWater(args)
    elseif itemInfos.fertilizer ~= 0 then
        giveFertilizer(args)
    end
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end)

RegisterNetEvent('it-drugs:client:destroyPlant', function(args)
    if Config.ItemToDestroyPlant and not exports.it_bridge:HasItem(Config.DestroyItemName, 1) then
        ShowNotification(nil, _U('NOTIFICATION__NEED_LIGHTER'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
        
    local plantData = args.plantData
    local type = plantData.seed
    local entity = NetworkGetEntityFromNetworkId(plantData.netId)

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
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, false, false)

    if ShowProgressBar({
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
        TriggerServerEvent('it-drugs:server:destroyPlant', {plantId = plantData.id})
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end
    TriggerEvent('it-drugs:client:syncRestLoop', false)
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
