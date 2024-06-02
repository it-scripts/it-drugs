if not Config.EnableProcessing then return end
local processingTables = {}

--- Method to setup all the weedplants, fetched from the database
--- @return nil
local setupTables = function()
    local result = MySQL.Sync.fetchAll('SELECT * FROM drug_processing')
    local current_time = os.time()

    for k, v in pairs(result) do
        local modelHash = GetHashKey(Config.ProcessingTables[v.type].model)
        local coords = json.decode(v.coords)
        local table = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z, true, true, false)
        SetEntityHeading(table, v.rotation + .0)
        Wait(100)
        FreezeEntityPosition(table, true)
        processingTables[table] = {
            id = v.id,
            coords = vector3(coords.x, coords.y, coords.z),
            type = v.type,
            rot = v.rotation + .0,
            entity = table
        }
    end
end

--- Method to delete all cached weed plants and their entities
--- @return nil
local destroyAllTables = function()    
    for k, v in pairs(processingTables) do
        if DoesEntityExist(k) then
            DeleteEntity(k)
            processingTables[k] = nil
        end
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    while not DatabaseSetuped do
        Wait(100)
    end
    if Config.Debug then lib.print.info('Setting up Processing Tables') end
    setupTables()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    destroyAllTables()
end)

RegisterNetEvent('it-drugs:server:processDrugs', function(entity, recipe)

    if not processingTables[entity] then return end
    if #(GetEntityCoords(GetPlayerPed(source)) - processingTables[entity].coords) > 10 then return end

    local player = it.getPlayer(source)
    --local tableInfos = Config.ProcessingTables[processingTables[entity].type]

    if not player then return end
    local givenItems = {}

    local failChance = math.random(1, 100)
    if failChance <= recipe.failChance then
        ShowNotification(source, _U('NOTIFICATION__PROCESS__FAIL'), 'error')
        for k,v in pairs(recipe.ingrediants) do
            it.removeItem(source, k, v)
        end
        return
    end

    for k, v in pairs(recipe.ingrediants) do
        if not it.removeItem(source, k, v) then
            ShowNotification(source, _U('NOTIFICATION__MISSING__INGIDIANT'), 'error')
            if #givenItems > 0 then
                for _, x in pairs(givenItems) do
                    it.giveItem(source, x.name, x.amount)
                end
            end
            return
        else
            table.insert(givenItems, {name = k, amount = v})
        end
    end
    SendToWebhook(source, 'table', 'process', processingTables[entity])
    
    for k, v in pairs(recipe.outputs) do
        it.giveItem(source, k, v)
    end
end)


RegisterNetEvent('it-drugs:server:removeTable', function(args)
    local entity = args.entity
    if not processingTables[entity] then return end
    
    if args.extra == nil then
        if #(GetEntityCoords(GetPlayerPed(source)) - processingTables[entity].coords) > 10 then return end
        it.giveItem(source, processingTables[entity].type, 1)
    end
    SendToWebhook(source, 'table', 'remove', processingTables[entity])

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        MySQL.query('DELETE from drug_processing WHERE id = :id', {
            ['id'] = processingTables[entity].id
        })
        processingTables[entity] = nil
    end
    
end)

RegisterNetEvent('it-drugs:server:createNewTable', function(coords, type, rotation, metadata)
    local src = source
    local player = it.getPlayer(src)
    local tableInfos = Config.ProcessingTables[type]

    if not player then if Config.Debug then lib.print.error("No Player") end return end
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then return end

    if it.removeItem(src, type, 1, metadata) then
        local modelHash = GetHashKey(tableInfos.model)
        local table = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z, true, true, false)
        SetEntityHeading(table, rotation)
        FreezeEntityPosition(table, true)

        MySQL.insert('INSERT INTO `drug_processing` (coords, type, rotation) VALUES (:coords, :type, :rotation)', {
            ['coords'] = json.encode(coords),
            ['type'] = type,
            ['rotation'] = rotation
        }, function(id)
            processingTables[table] = {
                id = id,
                coords = coords,
                type = type,
                rot = rotation,
                entity = table
            }
            SendToWebhook(src, 'table', 'place', processingTables[table])
        end)
    else
        if Config.Debug then lib.print.error("Can not remove item") end
    end
end)

-- Callbacks
lib.callback.register('it-drugs:server:getTableData', function(source, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if Config.Debug then lib.print.info('Getting Data for entity', entity) end
    if not processingTables[entity] then return nil end
    local temp = {
        id = processingTables[entity].id,
        coords = processingTables[entity].coords,
        type = processingTables[entity].type,
        rot = processingTables[entity].rot,
        entity = entity
    }
    if Config.Debug then lib.print.info('Returning Data', temp) end
    return temp
end)

lib.callback.register('it-drugs:server:getTables', function(source)
    return processingTables
end)