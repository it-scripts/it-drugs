--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
if not Config.EnableProcessing then return end
--- Method to setup all the weedplants, fetched from the database
--- @return nil
local setupTables = function()
    local result = MySQL.query.await('SELECT * FROM drug_processing')

    if not result then return false end
    
    if Config.Debug then lib.print.info('[setupTables] - Found', #result, 'tables in the database') end

    for i = 1, #result do
        local v = result[i]

        if not Config.ProcessingTables[v.type] then
            MySQL.query('DELETE FROM drug_processing WHERE id = :id', {
                ['id'] = v.id
            }, function()
                lib.print.info('[setupTables] - Table with ID:', v.id, 'has a invalid type, deleting it from the database') 
            end)
        elseif not v.owner then
            MySQL.query('DELETE FROM drug_processing WHERE id = :id', {
                ['id'] = v.id
            }, function()
                lib.print.info('[setupTables] - Table with ID:', v.id, 'has no owner, deleting it from the database')
            end)
        else
            local coords = json.decode(v.coords)
            local currentTable = ProcessingTable:new(v.id, {
                coords = vector3(coords.x, coords.y, coords.z),
                rotation = v.rotation + .0,
                owner = v.owner,
                tableType = v.type
            })

            local recipes = Config.ProcessingTables[v.type].recipes
            for recipeId, recipeData in pairs(recipes) do
                if currentTable:getRecipeData(recipeId) then
                    if Config.Debug then lib.print.info('[setupTables] - Table with ID:', v.id, 'already has recipe with ID:', recipeId) end
                else
                    local recipe = Recipe:new(recipeId, recipeData)
                    currentTable:addRecipe(recipeId, recipe)
                end
            end
        end
    end
    TriggerClientEvent('it-drugs:client:syncTables', -1, ProcessingTables)
    return true
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    while not DatabaseSetuped do
        Wait(100)
    end
    if Config.Debug then lib.print.info('Setting up Processing Tables') end
    while not setupTables() do
        Wait(100)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for _, processingTable in pairs(ProcessingTables) do
        processingTable:delete()
    end
end)

RegisterNetEvent('it-drugs:server:processDrugs', function(data)

    if not ProcessingTables[data.tableId] then return end
    local processingTable = ProcessingTables[data.tableId]
    local recipe = processingTable:getRecipeData(data.recipeId)
    if #(GetEntityCoords(GetPlayerPed(source)) - processingTable.coords) > 10 then return end

    local givenItems = {}

    local failChance = math.random(1, 100)
    if failChance <= recipe.failChance then
        ShowNotification(source, _U('NOTIFICATION__PROCESS__FAIL'), 'Error')
        for k,v in pairs(recipe.ingrediants) do
            exports.it_bridge:RemoveItem(source, k, v.amount)
        end
        return
    end

    for k, v in pairs(recipe.ingrediants) do
        if v.remove then
            if not exports.it_bridge:RemoveItem(source, k, v.amount) then
                ShowNotification(source, _U('NOTIFICATION__MISSING__INGIDIANT'), 'Error')
                if #givenItems > 0 then
                    for _, x in pairs(givenItems) do
                        exports.it_bridge:GiveItem(source, x.name, x.amount)
                    end
                end
                return
            else
                table.insert(givenItems, {name = k, amount = v.amount})
            end
        end
    end
    SendToWebhook(source, 'table', 'process', processingTable:getData())
    
    for k, v in pairs(recipe.outputs) do
        exports.it_bridge:GiveItem(source, k, v)
    end
end)


RegisterNetEvent('it-drugs:server:removeTable', function(args)

    if not ProcessingTables[args.tableId] then return end

    local processingTable = ProcessingTables[args.tableId]

    if not args.extra then
        if #(GetEntityCoords(GetPlayerPed(source)) - processingTable.coords) > 10 then return end
        exports.it_bridge:GiveItem(source, processingTable.tableType, 1)
    end

    MySQL.query('DELETE from drug_processing WHERE id = :id', {
        ['id'] = args.tableId
    })

    local tableData = processingTable:getData()
    SendToWebhook(source, 'table', 'remove', tableData)

    processingTable:delete()
    TriggerClientEvent('it-drugs:client:syncTables', -1, ProcessingTables)
end)

RegisterNetEvent('it-drugs:server:createNewTable', function(coords, type, rotation, metadata)
    local src = source
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then return end
    
    if exports.it_bridge:RemoveItem(src, type, 1, metadata) then

        local id = exports.it_bridge:GenerateCustomID(8)
        while ProcessingTables[id] do
            id = exports.it_bridge:GenerateCustomID(8)
        end

        local currentDimension = GetPlayerRoutingBucket(src)
        
        MySQL.insert('INSERT INTO `drug_processing` (id, coords, type, rotation, dimension, owner) VALUES (:id, :coords, :type, :rotation, :dimension, :owner)', {
            ['id'] = id,
            ['coords'] = json.encode(coords),
            ['type'] = type,
            ['rotation'] = rotation,
            ['dimension'] = currentDimension,
            ['owner'] = exports.it_bridge:GetCitizenId(src)
        }, function()
            local currentTable = ProcessingTable:new(id, {
                coords = coords,
                rotation = rotation,
                dimension = currentDimension,
                owner = exports.it_bridge:GetCitizenId(src),
                tableType = type
            })


            local recipes = Config.ProcessingTables[type].recipes
            for recipeId, recipeData in pairs(recipes) do
                if currentTable:getRecipeData(recipeId) then
                    if Config.Debug then lib.print.info('[setupTables] - Table with ID:', v.id, 'already has recipe with ID:', recipeId) end
                else
                    local recipe = Recipe:new(recipeId, recipeData)
                    currentTable:addRecipe(recipeId, recipe)
                end
            end

            TriggerClientEvent('it-drugs:client:syncTables', -1, ProcessingTables)
            local tableData = currentTable:getData()
            SendToWebhook(src, 'table', 'place', tableData)
        end)
    else
        if Config.Debug then lib.print.error("Can not remove item") end
    end
end)


RegisterNetEvent('it-drugs:server:syncparticlefx', function(status, tableId, netId, particlefx)
    TriggerClientEvent('it-drugs:client:syncparticlefx',-1, status, tableId, netId, particlefx)
end)
