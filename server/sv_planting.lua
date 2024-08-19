---@type table: List of all the plants
local plants = {}


---@section Plant Class
-- Class to handle the plant object and its methods

--- @class Plant : OxClass
--- @field id string
Plant = lib.class('Plant')

--- Plant constructor
---@param id string
---@param plantData table
function Plant:constructor(id, plantData)

    if Config.Debug then lib.print.info('[Plant:constructor] - Start constructing plant with ID:', id) end

    ---@type string: the plant ID
    self.id = id
    ---@type number: the plant entity
    self.entity = plantData.entity
    ---@type vector3: the plant coords
    self.coords = plantData.coords
    ---@type string: the plant owner
    self.owner = plantData.owner
    ---@type number: the plant time
    self.plantTime = plantData.plantTime
    ---@type string: the plant type
    self.plantType = plantData.type
    ---@type number: the plant fertilizer
    self.fertilizer = plantData.fertilizer
    ---@type number: the plant water
    self.water = plantData.water
    ---@type number: the plant health
    self.health = plantData.health

    self.growtime = plantData.growtime
    self.stage = self:calcStage()

    --self.metadata = plantData.metadata -- Experimental feature / can only used with ox_inventory

    if Config.Debug then lib.print.info('[Plant:constructor] - Plant constructed with ID:', id) end
end

--- Method to delete the plant object
---@return nil
function Plant:delete()
    self:destroyProp()
    plants[self.id] = nil
end

--- Method to update the plant prop on the map
---@return nil
function Plant:spawn()

    if Config.Debug then lib.print.info('[Plant:spawn] - Try to spawning plant with ID:', self.id) end

    ---@type number: the plant stage
    local stage = self:calcStage()
    ---@type string: the plant type
    local plantType = self.plantType

    ---@type string: the plant model hash
    local modelHash = Config.PlantTypes[plantType][stage][1]

    ---@type number: the plant z offset
    local zOffest = Config.PlantTypes[plantType][stage][2]

    ---@type number: the plant entity
    local plantEntity = CreateObjectNoOffset(modelHash, self.coords.x, self.coords.y, self.coords.z + zOffest, true, true, false)
    FreezeEntityPosition(plantEntity, true)

    self.entity = plantEntity
    plants[self.id] = self

    if Config.Debug then lib.print.info('[Plant:spawn] - Plant spawned with ID:', self.id) end
end

--- Method to destroy the plant prop on the map
---@return nil
function Plant:destroyProp()
    if not DoesEntityExist(self.entity) then return end
    DeleteEntity(self.entity)
    plants[self.id].entity = nil
end

--- Method to update the plant prop on the map
---@return nil
function Plant:updateProps()
    local stage = self:calcStage()
    local plantType = self.plantType

    local modelHash = Config.PlantTypes[plantType][stage][1]

    local zOffest = Config.PlantTypes[plantType][stage][2]

    DeleteEntity(self.entity)
    local plantEntity = CreateObjectNoOffset(modelHash, self.coords.x, self.coords.y, self.coords.z + zOffest, true, true, false)
    FreezeEntityPosition(plantEntity, true)

    self.entity = plantEntity
    plants[self.id] = self
end

--- Method to update the plant entity
---@param entity number
---@return nil
function Plant:updateEntity(entity)
    self.entity = entity

    -- Update the plant entity in the plants table
    plants[self.id] = self
end

--- Method to update the plant fertilizer
---@param fertilizer number
---@return nil
function Plant:updateFertilizer(fertilizer)
    self.fertilizer = fertilizer

    -- Update the plant fertilizer in the plants table
    plants[self.id].fertilizer = fertilizer
end

--- Method to update the plant water
---@param water number
---@return nil
function Plant:updateWater(water)
    self.water = water

    -- Update the plant water in the plants table
    plants[self.id].water = water
end

--- Method to update the plant health
---@param health number
---@return nil
function Plant:updateHealth(health)
    self.health = health

    -- Update the plant health in the plants table
    plants[self.id].health = health
end

--- Method to get the plant data
---@return table
function Plant:getData()
    return {
        id = self.id,
        entity = self.entity,
        coords = self.coords,
        owner = self.owner,
        plantType = self.plantType,
        fertilizer = self.fertilizer,
        water = self.water,
        health = self.health,
        growtime = self.growtime,
        stage = self.stage
    }
end

-- Method to calculate the health percentage for a given WeedPlants index
---@return integer: health percentage
function Plant:calcHealth()

    if not plants[self.entity] then return 0 end

    -- Getting plant data to calculate current plant health
    ---@type number
    local health = self.health
    ---@type number
    local fertilizer_amount = self.fertilizer
    ---@type number
    local water_amount = self.water

    if fertilizer_amount == 0 and water_amount == 0 then
        health -= math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    elseif fertilizer_amount < Config.FertilizerThreshold or water_amount < Config.WaterThreshold then
        health -= math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    end

    if fertilizer_amount == 0 or water_amount == 0 then
        health -= math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    elseif fertilizer_amount < Config.FertilizerThreshold or water_amount < Config.WaterThreshold then
         health -= math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    end

    return math.max(health, 0.0)
end

--- Method to calculate the growth percentage for a given WeedPlants index
---@return integer: growth percentage
function Plant:calcGrowth()
    if not plants[self.entity] then return 0 end
    -- If the plant is dead the growth doesnt change anymore
    if self.health <= 0 then return 0 end
    local current_time = os.time()
    local growTime = self.growtime * 60
    local progress = os.difftime(current_time, self.plantTime)
    local growth = it.round(progress * 100 / growTime, 2)
    local retval = math.min(growth, 100.00)
    return retval
end

--- Method to calculate the growth stage for a given WeedPlants index
---@return integer: growth stage
function Plant:calcStage()
    local growth = self:calcGrowth()
    local stage = math.floor(growth / 33) + 1
    if stage > 3 then stage = 3 end
    return stage
end


--- Callback to get the plant data by ID
---@param source number | nil: the source player
---@param plantId string: the plant ID
---@return Plant | nil: the plant object
lib.callback.register('it-drugs:server:getPlantById', function(source, plantId)

    if Config.Debug then lib.print.info('[getPlantById] - Try to get plant with ID:', plantId) end

    if not plants[plantId] then 
        lib.print.error('[getPlantById] - Plant with ID:', plantId, 'does not exist')
        return nil
    end

    if Config.Debug then lib.print.info('[getPlantById] - Successfully get Plant with ID:', plantId) end
    return Plant:getData()
end)

--- Callback to get the plant data by entity
---@param source number | nil: the source player
---@param entity number: the entity of the plant
---@return Plant | nil: the plant object
lib.callback.register('it-drugs:server:getPlantByEntity', function(source, entity)

    if Config.Debug then lib.print.info('[getPlantByEntity] - Try to get plant with entity:', entity) end
   
    for _, v in pairs(plants) do
        if v.entity == entity then
            if Config.Debug then lib.print.info('[getPlantByEntity] - Successfully get Plant with entity:', entity) end
            return Plant:getData()
        end
    end

    lib.print.error('[getPlantByEntity] - Plant with entity:', entity, 'does not exist')
    return nil
end)

--- Callback to get all plants owned by a player
---@param source number: the source player
---@return table | nil: the list of plants
lib.callback.register('it-drugs:server:getPlantsOwned', function(source)

    if Config.Debug then lib.print.info('[getPlantsOwned] - Try to get all plants owned by player:', source) end

    ---@type number: the player citizen ID
    local src = source
    ---@type number | boolean: the player citizen ID 
    -- TODO: Check why this is a boolean
    local citId = it.getCitizenId(src)
    ---@type table: the temporary table to store the plants
    local temp = {}

    -- Loop through all the plants and check if the player owns them
    for k, v in pairs(plants) do
        if v.owner == citId then
            table.insert(temp, v)
        end
    end
    
    -- If the player does not own any plants, return nil
    if #temp == 0 then
        if Config.Debug then lib.print.info('[getPlantsOwned] - Player:', src, 'does not own any plants') end
        return nil
    end

    if Config.Debug then lib.print.info('[getPlantsOwned] - Successfully get all plants owned by player:', src) end
    return temp

end)

--- Callback to get all plants
---@param source number: the source player
---@return table | nil: the list of plants
lib.callback.register('it-drugs:server:getPlants', function(source)
    return plants
end)

--------------------------------------------------
--- @section local functions

--- Function to generate a random plant ID
---@return string
local function generatePlantId()
    ---@type string: the generated UUID
    local longId = it.generateUUID()

    ---@type string: the short ID
    local shortId = string.sub(longId, 1, 8)

    return shortId
end

--- Method to setup all the weedplants, fetched from the database
--- @return nil
local setupPlants = function()
    local result = MySQL.Sync.fetchAll('SELECT * FROM drug_plants')
    local current_time = os.time()

    for k, v in pairs(result) do

        if not Config.Plants[v.type] then
            MySQL.query('DELETE from drug_plants WHERE id = :id', {
                ['id'] = v.id
            }, function()
                lib.print.info('PLANT ID: '.. v.id ..' has an invalid plant type, deleting it from the database')
            end)
        elseif v.owner == nil then
            MySQL.query('DELETE from drug_plants WHERE id = :id', {
                ['id'] = v.id
            }, function()
                lib.print.info('PLANT ID: '.. v.id ..' has no owner, deleting it from the database')
            end)
        else
            local plantType = Config.Plants[v.type].plantType

            local growTime = v.growtime * 60
            local progress = os.difftime(current_time, v.time)
            local growth = math.min(it.round(progress * 100 / growTime, 2), 100.00)
            local stage = calcStage(growth)
            local modelHash = Config.PlantTypes[plantType][stage][1]
            local coords = json.decode(v.coords)
            local plant = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z + Config.PlantTypes[plantType][stage][2], true, true, false)
            FreezeEntityPosition(plant, true)
            plants[plant] = {
                id = v.id,
                owner = v.owner,
                coords = vector3(coords.x, coords.y, coords.z),
                time = v.time,
                type = v.type,
                entity = plant,
                fertilizer = v.fertilizer,
                water = v.water,
                growtime = v.growtime,
                health = v.health,
                stage = stage
            }
        end
    end
end

--- Method to delete all cached weed plants and their entities
--- @return nil
local destroyAllPlants = function()
    for k, v in pairs(plants) do
        if DoesEntityExist(k) then
            DeleteEntity(k)
            plants[k] = nil
        end
    end
end

--- Method to update a plant object, removing the existing one and placing a new object
--- @param k number - WeedPlants table index
--- @param stage number - Stage number
--- @return nil
local updatePlantProp = function(k, stage)
    if not plants[k] then return end
    if not DoesEntityExist(k) then return end
    if plants[k].health <= 0 then return end

    local plantType = Config.Plants[plants[k].type].plantType

    local modelHash = Config.PlantTypes[plantType][stage][1]
    DeleteEntity(k)
    local plant = CreateObjectNoOffset(modelHash, plants[k].coords.x, plants[k].coords.y, plants[k].coords.z + Config.PlantTypes[plantType][stage][2], true, true, false)
    FreezeEntityPosition(plant, true)
    plants[plant] = plants[k]
    plants[plant].entity = plant
    plants[k] = nil
end

updatePlantNeeds = function ()
    for k, v in pairs(plants) do
        local fertilizer = v.fertilizer
        local water = v.water

        local time = os.time()
        local planted = v.time

        local elapsed = os.difftime(time, planted)
        -- if elapsed is < 1 minute, skip this plant
        if elapsed >= 60 then
            if fertilizer - Config.FertilizerDecay >= 0 then
                plants[k].fertilizer = it.round(fertilizer - Config.FertilizerDecay, 2)
            else
                plants[k].fertilizer = 0
            end
    
            if water - Config.WaterDecay >= 0 then
                plants[k].water = it.round(water - Config.WaterDecay, 2)
            else
                plants[k].water = 0
            end
            local health = calcHealth(k)
            MySQL.update('UPDATE drug_plants SET water = (:water), fertilizer = (:fertilizer), health = (:health) WHERE id = (:id)', {
                ['water'] = v.water,
                ['fertilizer'] = v.fertilizer,
                ['health'] = health,
                ['id'] = v.id,
            })
        end

        if not DoesEntityExist(k) then
            lib.print.info('Plant ID: '.. v.id ..' does not exist, respawning it coords:', v.coords.x)
            -- Respawn the plant
            local modelHash = Config.PlantTypes[Config.Plants[v.type].plantType][v.stage][1]
            local plant = CreateObjectNoOffset(modelHash, v.coords.x, v.coords.y, v.coords.z + Config.PlantTypes[Config.Plants[v.type].plantType][v.stage][2], true, true, false)
            FreezeEntityPosition(plant, true)
            plants[plant] = plants[k]
            plants[plant].entity = plant
            plants[k] = nil
            v = plants[plant]

            local stage = calcStage(calcGrowth(plant))
            if stage ~= v.stage then
                plants[plant].stage = stage
                updatePlantProp(plant, stage)
            end
        else
            local stage = calcStage(calcGrowth(k))
            if stage ~= v.stage then
                plants[k].stage = stage
                updatePlantProp(k, stage)
            end
        end
    end

    SetTimeout(60 * 1000, updatePlantNeeds)
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    while not DatabaseSetuped do
        lib.print.info('Waiting for Database to be setup')
        Wait(100)
    end
    if Config.Debug then lib.print.info('Setup Plants') end
    setupPlants()
    if Config.ClearOnStartup then
        Wait(5000) -- Wait 5 seconds to allow all functions to be executed on startup
        for k, v in pairs(plants) do
            if plants[k].health == 0 then
                DeleteEntity(k)
                MySQL.query('DELETE from drug_plants WHERE id = :id', {
                    ['id'] = plants[k].id
                })
                plants[k] = nil
            end
        end
    end
    TriggerClientEvent('it-drugs:client:syncPlantList', -1)
    SendToWebhook(0, 'message', nil, 'Started '..GetCurrentResourceName()..' logger')

end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for k, v in pairs(plants) do
        MySQL.update('UPDATE drug_plants SET water = (:water), fertilizer = (:fertilizer) WHERE id = (:id)', {
            ['water'] = json.encode(v.water),
            ['fertilizer'] = json.encode(v.fertilizer),
        })
    end
    
    destroyAllPlants()

end)

--- Events

RegisterNetEvent('it-drugs:server:destroyPlant', function(args)
    local entity = args.entity
    if not plants[entity] then return end
    
    if args.extra == nil then
        if #(GetEntityCoords(GetPlayerPed(source)) - plants[entity].coords) > 10 then return end
    end
    SendToWebhook(source, 'plant', 'destroy', plants[entity])

    if Config.Debug then lib.print.info('Does Entity Exists:', DoesEntityExist(entity)) end
    if DoesEntityExist(entity) then
        MySQL.query('DELETE from drug_plants WHERE id = :id', {
            ['id'] = plants[entity].id
        })

        TriggerClientEvent('it-drugs:client:startPlantFire', -1, plants[entity].coords, stage)
        Wait(Config.FireTime / 2)
        DeleteEntity(entity)

        plants[entity] = nil
        TriggerClientEvent('it-drugs:client:syncPlantList', -1)
    end
end)

RegisterNetEvent('it-drugs:server:harvestPlant', function(entity)

    if not plants[entity] then return end
    local src = source
    local player = it.getPlayer(src)
    if not player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - plants[entity].coords) > 10 then return end
    if calcGrowth(entity) ~= 100 then return end

    if DoesEntityExist(entity) then
        for k, v in pairs(Config.Plants[plants[entity].type].products) do
            local product = k
            local minAmount = v.min
            local maxAmount = v.max
            local amount = math.random(minAmount, maxAmount)
            it.giveItem(src, product, amount)
        end
        if math.random(1, 100) <= Config.Plants[plants[entity].type].seed.chance then
            local seed = plants[entity].type

            if Config.Plants[plants[entity].type].seed.max > 1 then
                local seedAmount = math.random(Config.Plants[seed].seed.min, Config.Plants[seed].seed.max)
                it.giveItem(src, seed, seedAmount)
            end
        end
    
        DeleteEntity(entity)
        SendToWebhook(src, 'plant', 'harvest', plants[entity])
  
        MySQL.query('DELETE from drug_plants WHERE id = :id', {
            ['id'] = plants[entity].id
        })
        plants[entity] = nil
        TriggerClientEvent('it-drugs:client:syncPlantList', -1)
    end
end)


RegisterNetEvent('it-drugs:server:plantTakeCare', function(entity, item)

    if not plants[entity] then return end
    local src = source
    local player = it.getPlayer(src)
    if not player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - plants[entity].coords) > 10 then return end

    if it.removeItem(src, item, 1) then
        local itemData = Config.Items[item]
        if itemData.water ~= 0 then
            local itemStrength = itemData.water
            local currentWater = plants[entity].water
            if currentWater + itemStrength >= 100 then
                plants[entity].water = 100
            else
                plants[entity].water = currentWater + itemStrength
            end

            MySQL.update('UPDATE drug_plants SET water = (:water) WHERE id = (:id)', {
                ['water'] = json.encode(plants[entity].water),
                ['id'] = plants[entity].id,
            })
            SendToWebhook(src, 'plant', 'water', plants[entity])
        end

        if itemData.fertilizer ~= 0 then
            local itemStrength = itemData.fertilizer
            local currentFertilizer = plants[entity].fertilizer
            if currentFertilizer + itemStrength >= 100 then
                plants[entity].fertilizer = 100
            else
                plants[entity].fertilizer = currentFertilizer + itemStrength
            end

            MySQL.update('UPDATE drug_plants SET fertilizer = (:fertilizer) WHERE id = (:id)', {
                ['fertilizer'] = json.encode(plants[entity].fertilizer),
                ['id'] = plants[entity].id,
            })
            SendToWebhook(src, 'plant', 'fertilize', plants[entity])
        end
        if itemData.itemBack ~= nil then
            it.giveItem(src, itemData.itemBack, 1)
        end
    end
end)

RegisterNetEvent('it-drugs:server:giveWater', function(entity, item)
    if not plants[entity] then return end
    local src = source
    local player = it.getPlayer(src)
    if not player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - plants[entity].coords) > 10 then return end

    if it.removeItem(src, item, 1) then

        SendToWebhook(src, 'plant', 'water', plants[entity])

        local itemStrength = Config.Items[item].water
        local currentWater = plants[entity].water
        if currentWater + itemStrength >= 100 then
            plants[entity].water = 100
        else
            plants[entity].water = currentWater + itemStrength
        end

        MySQL.update('UPDATE drug_plants SET water = (:water) WHERE id = (:id)', {
            ['water'] = json.encode(plants[entity].water),
            ['id'] = plants[entity].id,
        })
    end
end)

RegisterNetEvent('it-drugs:server:giveFertilizer', function(entity, item)
    if not plants[entity] then return end
    local src = source
    local player = it.getPlayer(src)
    if not player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - plants[entity].coords) > 10 then return end

    if it.removeItem(src, item, 1) then
        SendToWebhook(src, 'plant', 'fertilize', plants[entity])
        
        local itemStrength = Config.Items[item].fertilizer
        local currentFertilizer = plants[entity].fertilizer
        if currentFertilizer + itemStrength >= 100 then
            plants[entity].fertilizer = 100
        else
            plants[entity].fertilizer = currentFertilizer + itemStrength
        end
        
        MySQL.update('UPDATE drug_plants SET fertilizer = (:fertilizer) WHERE id = (:id)', {
            ['fertilizer'] = json.encode(plants[entity].fertilizer),
            ['id'] = plants[entity].id,
        })
    end
end)

RegisterNetEvent('it-drugs:server:createNewPlant', function(coords, plantItem, zone, metadata)
    local src = source
    local player = it.getPlayer(src)
    local plantInfos = Config.Plants[plantItem]

    if not player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then return end

    if it.removeItem(src, plantItem, 1, metadata) then
        local modelHash = GetHashKey(Config.PlantTypes[plantInfos.plantType][1][1])
        local plant = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z + Config.PlantTypes[plantInfos.plantType][1][2], true, true, false)
        FreezeEntityPosition(plant, true)
        local time = os.time()
        local owner = it.getCitizenId(src)

        local growTime = Config.GlobalGrowTime
        if plantInfos.growthTime then
            growTime = plantInfos.growthTime
        end
        if Config.Zones[zone] ~= nil and Config.Zones[zone].growMultiplier then
            growTime = (growTime / Config.Zones[zone].growMultiplier)
        end

        MySQL.insert('INSERT INTO `drug_plants` (owner, coords, time, type, water, fertilizer, health, growtime) VALUES (:owner, :coords, :time, :type, :water, :fertilizer, :health, :growtime)', {
            ['owner'] = owner,
            ['coords'] = json.encode(coords),
            ['time'] = time,
            ['type'] = plantItem,
            ['water'] = 0.0,
            ['fertilizer'] = 0.0,
            ['health'] = 100.0,
            ['growtime'] = growTime,
        }, function(id)
            plants[plant] = {
                id = id,
                owner = owner,
                coords = coords,
                time = time,
                type = plantItem,
                water = 0.0,
                fertilizer = 0.0,
                health = 100.0,
                growtime = growTime,
                entity = plant,
                stage = 1
            }
            TriggerClientEvent('it-drugs:client:syncPlantList', -1)
            SendToWebhook(src, 'plant', 'plant', plants[plant])
        end)
    end
end)


lib.callback.register('it-drugs:server:getPlants', function(source)
    return plants
end)

--- Threads
CreateThread(function()
    Wait(1000) -- Wait 5 seconds to allow all functions to be executed on startup
    updatePlantNeeds()
end)