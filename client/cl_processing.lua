--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
if not Config.EnableProcessing then return end

local proccessing = false

local processingFx = {}


function PlaceProcessingTable(ped, tableItem, coords, rotation, metadata)
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
        duration = 5000,
        label = _U('PROGRESSBAR__PLACE__TABLE'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    }) then
        TriggerServerEvent('it-drugs:server:createNewTable', coords, tableItem, rotation, metadata)

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

RegisterNetEvent('it-drugs:client:processDrugs', function(args)
    
    local tableData = lib.callback.await('it-drugs:server:getTableById', false, args.tableId)
    local recipe = lib.callback.await('it-drugs:server:getRecipeById', false, args.tableId, args.recipeId)
    if proccessing then return end

    local input = lib.inputDialog(_U('INPUT__AMOUNT__HEADER'), {
        {type = 'number', label = _U('INPUT__AMOUNT__TEXT'), description = _U('INPUT__AMOUNT__DESCRIPTION'), require = true, min = 1}
    })

    if not input then
        ShowNotification(nil, _U('NOTIFICATION__NO__AMOUNT'), 'Error')
        return
    end

    local amount = tonumber(input[1])
    for item, itemData in pairs(recipe.ingrediants) do
        if not exports.it_bridge:HasItem(item, itemData.amount * amount) then
            ShowNotification(nil, _U('NOTIFICATION__MISSING__INGIDIANT'), 'Error')
            proccessing = false
            TriggerEvent('it-drugs:client:syncRestLoop', false)
            return
        end
    end

    local clientData = GetTableData(tableData.id)
    local entity = clientData.entity
    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)

    proccessing = true

    RequestAnimDict(recipe.animation.dict)
    while not HasAnimDictLoaded(recipe.animation.dict) do
        Wait(0)
    end
    TaskPlayAnim(ped, recipe.animation.dict, recipe.animation.anim, 8.0, 8.0, -1, 1, 0, false, false, false)

    if recipe.particlefx then
        if Config.Debug then lib.print.info('Calling ParticleFX Sync [start]') end
        TriggerServerEvent("it-drugs:server:syncparticlefx", true, tableData.id, tableData.netId, recipe.particlefx)
    end

    if Config.ProcessingSkillCheck then
        for i = 1, amount do
            local success = lib.skillCheck(Config.SkillCheck.difficulty, Config.SkillCheck.keys)
            if success then
                ShowNotification(nil, _U('NOTIFICATION__SKILL__SUCCESS'), 'Success')
                TriggerServerEvent('it-drugs:server:processDrugs', {tableId = args.tableId, recipeId = args.recipeId})
            else
                proccessing = false
                ShowNotification(nil, _U('NOTIFICATION__SKILL__ERROR'), 'Error')
                ClearPedTasks(ped)
                RemoveAnimDict(recipe.animation.dict)
                return
            end
            Wait(1000)
        end
        proccessing = false
        ClearPedTasks(ped)
        RemoveAnimDict(recipe.animation.dict)
    else
        for i = 1, amount do
            if lib.progressBar({
                duration = recipe.processTime * 1000,
                label = _U('PROGRESSBAR__PROCESS__DRUG'),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                },
            }) then
                TriggerServerEvent('it-drugs:server:processDrugs', {tableId = args.tableId, recipeId = args.recipeId})
            else
                ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
                ClearPedTasks(ped)
                RemoveAnimDict(recipe.animation.dict)
                proccessing = false
                return
            end
            Wait(1000)
        end
        proccessing = false
        ClearPedTasks(ped)
        RemoveAnimDict(recipe.animation.dict)
    end
    if recipe.particlefx then
        if Config.Debug then lib.print.info('Calling ParticleFX Sync [stop]') end
        TriggerServerEvent("it-drugs:server:syncparticlefx", false, tableData.id, nil, nil)
    end
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end)

RegisterNetEvent('it-drugs:client:removeTable', function(args)

    local tableData = lib.callback.await('it-drugs:server:getTableById', false, args.tableId)


    local clientData = GetTableData(tableData.id)
    local entity = clientData.entity

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

    if ShowProgressBar({
        duration = 5000,
        label = _U('PROGRESSBAR__REMOVE__TABLE'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    }) then
        TriggerServerEvent('it-drugs:server:removeTable', {tableId = args.tableId})
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

local getTableCenter = function(tableEntity)
    -- Get the table's position
    local tablePos = GetEntityCoords(tableEntity)
    
    -- Get the table's dimensions
    local min, max = GetModelDimensions(GetEntityModel(tableEntity))
    
    -- Calculate the center of the table
    local centerX = (min.x + max.x) / 2
    local centerY = (min.y + max.y) / 2
    local centerZ = (min.z + max.z) / 2
    
    -- Calculate the world coordinates of the center
    local centerPos = vector3(tablePos.x + centerX, tablePos.y + centerY, tablePos.z + centerZ)
    
    -- Get the table's rotation
    local tableRot = GetEntityRotation(tableEntity)
    
    return centerPos, tableRot
end

local function CreateSmokeEffect(status, tableId, netId, particleFx)
    if status then
        local entity = NetworkGetEntityFromNetworkId(netId)
        
        local entityCenterCoords, entityRotation = getTableCenter(entity)

        RequestNamedPtfxAsset(particleFx.dict)
        while not HasNamedPtfxAssetLoaded(particleFx.dict) do
            Wait(0)
        end
        UseParticleFxAssetNextCall(particleFx.dict)
   
        local offsetX = 0.0
        local offsetY = -0.5

        -- Adjust the offset based on the table's rotation
        if math.abs(entityRotation.z) > 45 and math.abs(entityRotation.z) < 135 then
            offsetX = -0.5
            offsetY = 0.0
        end

        processingFx[tableId] = StartParticleFxLoopedAtCoord(particleFx.particle, entityCenterCoords.x + offsetX, entityCenterCoords.y + offsetY, entityCenterCoords.z, entityRotation.x, entityRotation.y, entityRotation.z, particleFx.scale, false, false, false, 0)

        SetParticleFxLoopedColour(processingFx[tableId], particleFx.color.r, particleFx.color.g, particleFx.color.b, 0)
    else
        if processingFx[tableId] ~= nil then
            if Config.Debug then print('Stopping ParticleFX') end
            StopParticleFxLooped(processingFx[tableId], 0)
            processingFx[tableId] = nil
        end
    end
end

RegisterNetEvent('it-drugs:client:syncparticlefx', function(status, tableId, netId, particlefx)
    if status then
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local targetEntity = NetworkGetEntityFromNetworkId(netId)

        local targetCoords  = GetEntityCoords(targetEntity)
        local distance = #(playerCoords - targetCoords)
        if distance <= 100 then
            CreateSmokeEffect(status, tableId, netId, particlefx)
        end
    else
        CreateSmokeEffect(status, tableId, netId, particlefx)
    end
end)
