﻿--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
RegisterNetEvent('it-drugs:client:showAdminAlertBox', function(args)
    local userLicense = args.userLicense
    local username = args.username

    local alert = lib.alertDialog({
        header = 'NO PERMISSION',
        content = 'Add this your server.cfg file to give permission to this user:  \n add_ace identifier.'..userLicense..' it-drugs allow #'..username..' License  \n And restart your server to apply the changes',
        centered = true,
        size = 'xl',
        cancel = true,
        labels = {
            cancel = 'Exit',
            confirm = 'Copy'
        }
    })

    if alert == 'confirm' then
        -- copy content to clipboard
        lib.setClipboard('add_ace identifier.'..userLicense..' it-drugs allow #'..username..' License')
        ShowNotification(nil, _U('NOTIFICATION__COPY__CLIPBOARD'):format('User License'), "Success")
    end
end)

RegisterNetEvent('it-drugs:client:addAllAdminBlips', function(args)
    local type = args.type

    if type == 'plants' then
        local allPlants = lib.callback.await('it-drugs:server:getPlants', false)
        for _, data in pairs(allPlants) do
            AddAdminBlip(data.id, data.coords, Config.Plants[data.seed].label, 'plant')
        end
        ShowNotification(nil, _U('NOTIFICATION__ADD__BLIP'), "Success")
    elseif type == 'tables' then
        local allTables = lib.callback.await('it-drugs:server:getTables', false)
        for _, data in pairs(allTables) do
            AddAdminBlip(data.id, data.coords, 'Proccessing Table: '..Config.ProcessingTables[data.tableType].label, 'processing')
        end
        ShowNotification(nil, _U('NOTIFICATION__ADD__BLIP'), "Success")
    end
end)

RegisterNetEvent('it-drugs:client:addAdminBlip', function(args)
    local id = args.id
    local coords = args.coords
    local entityType = args.entityType
    local type = args.type

    if type == 'plant' then
        AddAdminBlip(id, coords, Config.Plants[entityType].label, 'plant')
        ShowNotification(nil, _U('NOTIFICATION__ADD__BLIP'), "Success")
    elseif type == 'table' then
        AddAdminBlip(id, coords, Config.ProcessingTables[entityType].label, 'processing')
        ShowNotification(nil, _U('NOTIFICATION__ADD__BLIP'), "Success")
    end
end)

RegisterNetEvent('it-drugs:client:removeAllAdminBlips', function(args)
    local type = args.type

    if type == 'plants' then
        local allPlants = lib.callback.await('it-drugs:server:getPlants', false)
        for _, data in pairs(allPlants) do
            RemoveAdminBlip(data.id)
        end
        ShowNotification(nil, _U('NOTIFICATION__REMOVE__BLIP'), "Success")
    elseif type == 'tables' then
        local allTables = lib.callback.await('it-drugs:server:getTables', false)
        for _, data in pairs(allTables) do
            RemoveAdminBlip(data.id)
        end
        ShowNotification(nil, _U('NOTIFICATION__REMOVE__BLIP'), "Success")
    end
end)

RegisterNetEvent('it-drugs:client:generatePlantListMenu', function()
    local currentCoords = GetEntityCoords(PlayerPedId())
    local allPlants = lib.callback.await('it-drugs:server:getPlants', false)

    -- check if there are any plants
    if not allPlants then return end

    local plantList = {}

    -- Sort plants by distance To player
    for _, data in pairs(allPlants) do
        local distance = #(currentCoords - data.coords)
        local temp = {
            id = data.id,
            owner = data.owner,
            coords = data.coords,
            netId = data.netId,
            type = data.seed,
            label = Config.Plants[data.seed].label..' ('..data.id..')',
            distance = distance
        }
        table.insert(plantList, temp)
    end

    table.sort(plantList, function(a, b) return a.distance < b.distance end)
    TriggerEvent('it-drugs:client:showPlantListMenu', {plantList = plantList})
end)

RegisterNetEvent('it-drugs:client:generateTableListMenu', function()
    local currentCoords = GetEntityCoords(PlayerPedId())
    local allTables = lib.callback.await('it-drugs:server:getTables', false)

    -- check if there are any tables
    if not allTables then return end

    local tableList = {}

    -- Sort tables by distance To player
    for _, data in pairs(allTables) do
        local distance = #(currentCoords - data.coords)
        local temp = {
            id = data.id,
            coords = data.coords,
            type = data.tableType,
            label = Config.ProcessingTables[data.tableType].label..' ('..data.id..')',
            distance = distance,
            netId = data.netId
        }
        table.insert(tableList, temp)
    end

    table.sort(tableList, function(a, b) return a.distance < b.distance end)
    TriggerEvent('it-drugs:client:showTableListMenu', {tableList = tableList})
end)


RegisterNetEvent('it-drugs:client:showGroundHash', function()
    local posped = GetEntityCoords(PlayerPedId())
    local num =
        StartShapeTestCapsule(posped.x, posped.y, posped.z + 4, posped.x, posped.y, posped.z - 2.0, 2, 1, ped, 7)
    local arg1, arg2, arg3, arg4, arg5 = GetShapeTestResultEx(num)

    local alert = lib.alertDialog({
        header = 'Ground Hash',
        content = 'GroundHash:  \n '..arg5,
        centered = true,
        cancel = true,
        labels = {
            cancel = 'Exit',
            confirm = 'Copy'
        }
    })

    if alert == 'confirm' then
        -- copy content to clipboard
        lib.setClipboard(arg5)
        ShowNotification(nil, _U('NOTIFICATION__COPY__CLIPBOARD'):format(arg5), "Success")
    end
    
end)