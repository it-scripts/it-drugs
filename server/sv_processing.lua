if not Config.EnableProcessing then return end
local processingTables = {}

---@section Process Tables Class
--- Class to handle the processing table object and its methods


---@class Recipe : OxClass
---@field id string
local Recipe = lib.class('Recipe')

function Recipe:constructor(id, recipeData)
    self.id = id
    self.label = recipeData.label
    self.ingrediants = recipeData.ingrediants
    self.outputs = recipeData.outputs
    self.failChance = recipeData.failChance
    self.processTime = recipeData.processTime
    self.showIngrediants = recipeData.showIngrediants
    self.animation = recipeData.animation or {dict = 'anim@amb@drug_processors@coke@female_a@idles', name = 'idle_a',}
    self.particlefx = recipeData.particlefx or nil
end

function Recipe:getData()
    return {
        id = self.id,
        label = self.label,
        ingrediants = self.ingrediants,
        outputs = self.outputs,
        failChance = self.failChance,
        processTime = self.processTime,
        showIngrediants = self.showIngrediants,
        animation = self.animation,
        particlefx = self.particlefx
    }
end

lib.callback.register('it-drugs:server:getRecipeById', function(source, tableId, recipeId)

    if Config.Debug then lib.print.info('[getRecipeById] - Try to get Recipe with ID:', recipeId, 'from Table with ID:', tableId) end

    if not processingTables[tableId] then
        if Config.Debug then lib.print.error('[getRecipeById] - Table with ID:', tableId, 'not found') end
        return nil
    end

    local currenTable = processingTables[tableId]

    local recipe = currenTable:getRecipeData(recipeId)

    if not recipe then
        if Config.Debug then lib.print.error('[getRecipeById] - Recipe with ID:', recipeId, 'not found') end
        return nil
    end

    if Config.Debug then lib.print.info('[getRecipeById] - Recipe with ID:', recipeId, 'from Table with ID:', tableId, 'found') end
    return recipe
end)

---@class ProcessingTable : OxClass
---@field id string
ProcessingTable = lib.class('ProcessingTable')

function ProcessingTable:constructor(id, tableData)

    if Config.Debug then lib.print.info('[ProcessingTable:constructor] - Start constructing ProcessingTable with ID:', id) end

    ---@type string: The ID of the processing table
    self.id = id
    ---@type number: The entity of the processing table
    self.entity = nil
    ---@type string: The netId of the processing table
    self.netId = nil
    ---@type vector3: The coords of the processing table
    self.coords = tableData.coords
    ---@type number: The rotation of the processing table
    self.rotation = tableData.rotation
    ---@type number: The dimension of the processing table
    self.dimension = tableData.dimension
    ---@type string: The owner of the processing table
    self.owner = tableData.owner
    ---@type string: The type of the processing table
    self.tableType = tableData.tableType

    ---@type table: The recipe of the processing table
    self.recipes = {}

    processingTables[self.id] = self

    if Config.Debug then lib.print.info('[ProcessingTable:constructor] - Finished constructing ProcessingTable with ID:', id) end
end

function ProcessingTable:delete()
    self:destroyProp()
    processingTables[self.id] = nil
end

function ProcessingTable:spawn()

    if Config.Debug then lib.print.info('[ProcessingTable:spawn] - Spawning ProcessingTable with ID:', self.id) end
    local modelHash = Config.ProcessingTables[self.tableType].model

    local tableEntity = CreateObjectNoOffset(modelHash, self.coords.x, self.coords.y, self.coords.z, true, true, false)
    Wait(20)
    SetEntityHeading(tableEntity, self.rotation)
    SetEntityRoutingBucket(tableEntity, self.dimension)
    FreezeEntityPosition(tableEntity, true)

    self.entity = tableEntity
    self.netId = NetworkGetNetworkIdFromEntity(tableEntity)

    processingTables[self.id] = self

    if Config.Debug then lib.print.info('[ProcessingTable:spawn] - Finished spawning ProcessingTable with ID:', self.id) end
end

function ProcessingTable:destroyProp()

    if Config.Debug then lib.print.info('[ProcessingTable:destroyProp] - Destroying ProcessingTable with ID:', self.id) end
    if not DoesEntityExist(self.entity) then return end
    DeleteEntity(self.entity)

    self.entity = nil
    self.netId = nil

    processingTables[self.id] = self
end

function ProcessingTable:getData()
    return {
        id = self.id,
        entity = self.entity,
        netId = self.netId,
        coords = self.coords,
        rotation = self.rotation,
        dimension = self.dimension,
        owner = self.owner,
        tableType = self.tableType,
        recipes = self.recipes
    }
end

--- Method to add a recipe to the processing table
---@param recipeid string: The ID of the recipe
---@param recipe Recipe: The recipe object
function ProcessingTable:addRecipe(recipeid, recipe)
    self.recipes[recipeid] = recipe
    processingTables[self.id] = self
end

--- Method to remove a recipe from the processing table
--- @param recipeid string: The ID of the recipe
function ProcessingTable:removeRecipe(recipeid)
    self.recipes[recipeid] = nil
    processingTables[self.id] = self
end

--- Method to get the recipe data from the processing table
--- @param recipeid string: The ID of the recipe
function ProcessingTable:getRecipeData(recipeid)
    local recipe = self.recipes[recipeid]
    if not recipe then return nil end
    return recipe:getData()
end

function ProcessingTable:getRecipes()
    local temp = {}

    for k, v in pairs(self.recipes) do
        temp[k] = v:getData()
    end

    return temp
end

lib.callback.register('it-drugs:server:getTableRecipes', function(source, id)
    if Config.Debug then lib.print.info('[getTableRecipes] - Try to get Recipes from Table with ID:', id) end

    if not processingTables[id] then
        if Config.Debug then lib.print.error('[getTableRecipes] - Table with ID:', id, 'not found') end
        return nil
    end

    if Config.Debug then lib.print.info('[getTableRecipes] - Recipes from Table with ID:', id, 'found') end
    return processingTables[id]:getRecipes()
end)

lib.callback.register('it-drugs:server:getTableById', function(source, id)
    
    if Config.Debug then lib.print.info('[getTableById] - Try to get Table with ID:', id) end

    if not processingTables[id] then
        if Config.Debug then lib.print.error('[getTableById] - Table with ID:', id, 'not found') end
        return nil
    end

    if Config.Debug then lib.print.info('[getTableById] - Table with ID:', id, 'found') end
    return processingTables[id]:getData()
end)

lib.callback.register('it-drugs:server:getTableByNetId', function(source, netId)
        
    if Config.Debug then lib.print.info('[getTableByNetId] - Try to get Table with NetID:', netId) end

    for _, processingTable in pairs(processingTables) do
        if processingTable.netId == netId then
            if Config.Debug then lib.print.info('[getTableByNetId] - Table with NetID:', netId, 'found') end
            return processingTable:getData()
        end
    end

    if Config.Debug then lib.print.error('[getTableByNetId] - Table with NetID:', netId, 'not found') end
    return nil
end)

lib.callback.register('it-drugs:server:getTableByOwner', function(source)

    if Config.Debug then lib.print.info('[getTableByOwner] - Try to get Table with Owner:', source) end

    local src = source
    local citId = exports.it_bridge:GetCitizenId(src)

    local temp = {}

    for k, v in pairs(processingTables) do
        if v.owner == citId then
            temp[k] = v:getData()
        end
    end

    if #temp == 0 then
        if Config.Debug then lib.print.error('[getTableByOwner] - Table with Owner:', source, 'not found') end
        return nil
    end

    if Config.Debug then lib.print.info('[getTableByOwner] - Table with Owner:', source, 'found') end
    return temp
end)

lib.callback.register('it-drugs:server:getTables', function(source)
    local temp = {}

    for k, v in pairs(processingTables) do
        temp[k] = v:getData()
    end

    return temp
end)

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
                entity = nil,
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

            currentTable:spawn()
        end
    end
    TriggerClientEvent('it-drugs:client:syncTables', -1, processingTables)
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

    updateThread()
end)

--- Thread to check if the entities are still valid
function updateThread()
    for _, processingTable in pairs(processingTables) do
        if processingTable.entity then
            -- Check if entity is still valid
            if not DoesEntityExist(processingTable.entity) then
                if Config.Debug then lib.print.warn('[updateThread] - Table with ID:', table.id, 'entity does not exist. Try to respawn') end
                processingTable:destroyProp()
                processingTable:spawn()
            end
        end
    end

    SetTimeout(1000 * 60, updateThread)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for _, processingTable in pairs(processingTables) do
        processingTable:delete()
    end
end)

RegisterNetEvent('it-drugs:server:processDrugs', function(data)

    if not processingTables[data.tableId] then return end
    local processingTable = processingTables[data.tableId]
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

    if not processingTables[args.tableId] then return end

    local processingTable = processingTables[args.tableId]

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
    TriggerClientEvent('it-drugs:client:syncTables', -1, processingTables)
end)

RegisterNetEvent('it-drugs:server:createNewTable', function(coords, type, rotation, metadata)
    local src = source
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then return end
    
    if exports.it_bridge:RemoveItem(src, type, 1, metadata) then

        local id = exports.it_bridge:GenerateCustomID(8)
        while processingTables[id] do
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
                entity = nil,
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

            currentTable:spawn()
            TriggerClientEvent('it-drugs:client:syncTables', -1, processingTables)
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
