RegisterNetEvent('it-drugs:client:showAdminAlertBox', function(args)

    local userLicense = args.userLicense
    local username = args.username

    local alert = lib.alertDialog({
        header = 'NO PERMISSION',
        content = 'Add this your server.cfg file to give permission to this user:  \n add_ace '..userLicense..' it-drugs allow #'..username..' License  \n And restart your server to apply the changes',
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
        lib.setClipboard('add_ace '..userLicense..' it-drugs allow #'..username..' License')
        ShowNotification(nil, _U('NOTIFICATION__COPY__CLIPBOARD'):format('User License'), "success")
    end
end)

RegisterNetEvent('it-drugs:client:addAllAdminBlips', function(args)
    local type = args.type

    if type == 'plants' then
        local allPlants = lib.callback.await('it-drugs:server:getPlants', false)
        for _, data in pairs(allPlants) do
            AddAdminBlip(data.id, data.coords, Config.Plants[data.type].label, 'plant')
        end
    elseif type == 'tables' then
        local allTables = lib.callback.await('it-drugs:server:getTables', false)
        for _, data in pairs(allTables) do
            AddAdminBlip(data.id, data.coords, 'Proccessing Table: '..Config.ProcessingTables[data.type].type, 'processing')
        end
    end
end)

RegisterNetEvent('it-drugs:client:addAdminBlip', function(args)
    local id = args.id
    local coords = args.coords
    local plantType = args.plantType
    local type = args.type

    if type == 'plant' then
        AddAdminBlip(id, coords, Config.Plants[plantType].label, 'plant')
    elseif type == 'table' then
        AddAdminBlip(id, coords, 'Proccessing Table: '..Config.ProcessingTables[args.tableType].type, 'processing')
    end
end)

RegisterNetEvent('it-drugs:client:removeAllAdminBlips', function(args)
    local type = args.type

    if type == 'plants' then
        local allPlants = lib.callback.await('it-drugs:server:getPlants', false)
        for _, data in pairs(allPlants) do
            RemoveAdminBlip(data.id)
        end
    elseif type == 'tables' then
        local allTables = lib.callback.await('it-drugs:server:getTables', false)
        for _, data in pairs(allTables) do
            RemoveAdminBlip(data.id)
        end
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
            entity = data.entity,
            type = data.type,
            label = Config.Plants[data.type].label,
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
            type = data.type,
            label = 'Proccessing Table: '..Config.ProcessingTables[data.type].type,
            distance = distance,
            entity = data.entity
        }
        table.insert(tableList, temp)
    end

    table.sort(tableList, function(a, b) return a.distance < b.distance end)
    TriggerEvent('it-drugs:client:showTableListMenu', {tableList = tableList})
end)