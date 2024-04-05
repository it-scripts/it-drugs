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
    setupTables()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    destroyAllTables()
end)

RegisterNetEvent('it-drugs:server:processDrugs', function(entity)

    if not processingTables[entity] then return end
    if #(GetEntityCoords(GetPlayerPed(source)) - processingTables[entity].coords) > 10 then return end

    local player = it.getPlayer(source)
    local tableInfos = Config.ProcessingTables[processingTables[entity].type]
    lib.print.info('Processing Drug Info', tableInfos)

    if not player then return end
    local givenItems = {}

    for k, v in pairs(tableInfos.ingrediants) do
        if not it.removeItem(source, k, v) then
            ShowNotification('You do not have the required items', 'error')
            if #givenItems > 0 then
                for _, v in pairs(givenItems) do
                    it.giveItem(source, v.name, v.amount)
                end
            end
            return
        else
            table.insert(givenItems, {name = k, amount = v})
        end
    end

    it.giveItem(source, tableInfos.output, 1)
end)


RegisterNetEvent('it-drugs:server:removeTable', function(entity)
    if not processingTables[entity] then return end
    if #(GetEntityCoords(GetPlayerPed(source)) - processingTables[entity].coords) > 10 then return end

    local player = it.getPlayer(source)
    it.giveItem(source, processingTables[entity].type, 1)

    sendWebhook(source, 'Drug Processing', 'Player removed a drug processing table\nCoords: '..processingTables[entity].coords..'\nType: '..processingTables[entity].type, 65280, false)

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        MySQL.query('DELETE from drug_processing WHERE id = :id', {
            ['id'] = processingTables[entity].id
        })
        processingTables[entity] = nil
    end
    
end)

RegisterNetEvent('it-drugs:server:createNewTable', function(coords, type, rotation)
    local src = source
    local player = it.getPlayer(src)
    local tableInfos = Config.ProcessingTables[type]

    if not player then if Config.Debug then lib.print.error("No Player") end return end
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then return end

    if it.removeItem(src, type, 1) then
        local modelHash = GetHashKey(tableInfos.model)
        local table = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z, true, true, false)
        SetEntityHeading(table, rotation)
        FreezeEntityPosition(table, true)

        sendWebhook(src, 'Drug Processing', 'Player created a drug processing table\nCoords: '..coords..'\nType: '..type, 65280, false)

        MySQL.insert('INSERT INTO `drug_processing` (coords, type, rotation) VALUES (:coords, :type, :rotation)', {
            ['coords'] = json.encode(coords),
            ['type'] = type,
            ['rotation'] = rotation
        }, function(id)
            processingTables[table] = {
                id = id,
                coords = coords,
                type = type,
                rot = rotation
            }
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