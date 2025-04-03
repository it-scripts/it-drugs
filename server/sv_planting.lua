math = lib.math
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
    ---@type number | nil: the plant entity
    self.entity = nil
    ---@type number | nil: the plant Network ID
    self.netId = nil
    ---@type vector3: the plant coords
    self.coords = plantData.coords
    ---@type number:
    self.dimension = nil
    ---@type string: the plant owner
    self.owner = plantData.owner
    ---@type number: the plant time
    self.plantTime = plantData.plantTime
    ---@type string: the plant type
    self.plantType = plantData.plantType
    ---@type string: the plant seed
    self.seed = plantData.seed
    ---@type number: the plant fertilizer
    self.fertilizer = plantData.fertilizer
    ---@type number: the plant water
    self.water = plantData.water
    ---@type number: the plant health
    self.health = plantData.health
    ---@type number: the plant growth
    self.growth = self:calcGrowth()

    self.growtime = plantData.growtime
    self.stage = self:calcStage()

    plants[self.id] = self

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
    SetEntityRoutingBucket(plantEntity, self.dimension)
    FreezeEntityPosition(plantEntity, true)

    self.entity = plantEntity
    self.netId = NetworkGetNetworkIdFromEntity(plantEntity)
    plants[self.id] = self

    if Config.Debug then lib.print.info('[Plant:spawn] - Plant spawned with ID:', self.id) end
end

--- Method to destroy the plant prop on the map
---@return nil
function Plant:destroyProp()
    if not DoesEntityExist(self.entity) then return end
    DeleteEntity(self.entity)

    self.entity = nil
    self.netId = nil

    plants[self.id] = self
end

--- Method to update the plant prop on the map
---@return nil
function Plant:updateProps()
    local stage = self:calcStage()
    local plantType = self.plantType

    ---@type string: the plant model hash
    local modelHash = Config.PlantTypes[plantType][stage][1]

    ---@type number: the plant z offset
    local zOffest = Config.PlantTypes[plantType][stage][2]

    DeleteEntity(self.entity)

    ---@type number: the plant entity
    local plantEntity = CreateObjectNoOffset(modelHash, self.coords.x, self.coords.y, self.coords.z + zOffest, true, true, false)
    FreezeEntityPosition(plantEntity, true)

    self.stage = stage
    self.entity = plantEntity
    self.netId = NetworkGetNetworkIdFromEntity(plantEntity)
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

    -- Send data to database
    MySQL.update('UPDATE drug_plants SET health = (:health) WHERE id = (:id)', {
        ['health'] = health,
        ['id'] = self.id,
    })
end

--- Method to get the plant data
---@return table
function Plant:getData()
    return {
        id = self.id,
        entity = self.entity,
        netId = self.netId,
        coords = self.coords,
        dimension = self.dimension,
        owner = self.owner,
        plantType = self.plantType,
        seed = self.seed,
        plantTime = self.plantTime,
        fertilizer = self.fertilizer,
        water = self.water,
        health = self.health,
        growtime = self.growtime,
        stage = self.stage,
        growth = self:calcGrowth()
    }
end

-- Method to calculate the health percentage for a given WeedPlants index
---@return integer: health percentage
function Plant:calcHealth()

    if not plants[self.id] then return 0 end

    -- Getting plant data to calculate current plant health
    ---@type number
    local health = self.health
    ---@type number
    local fertilizer_amount = self.fertilizer
    ---@type number
    local water_amount = self.water

    -- If the plant has no fertilizer and water, decrease the health
    if fertilizer_amount == 0 or water_amount == 0 then
        health = health - math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    elseif fertilizer_amount < Config.FertilizerThreshold or water_amount < Config.WaterThreshold then
        health = health - math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    end

    health = math.max(health, 0.0)

    self.health = health
    -- Return the health value with a minimum of 0
    return math.max(health, 0.0)
end

--- Method to calculate the growth percentage for a given WeedPlants index
---@return integer: growth percentage
function Plant:calcGrowth()
    if not plants[self.id] then return 0 end
    -- If the plant is dead the growth doesnt change anymore
    if self.health <= 0 then return self.growth end
    ---@type number: the current time
    local current_time = os.time()
    ---@type number: the grow time
    local growTime = self.growtime * 60
    ---@type number: the progress
    local progress = os.difftime(current_time, self.plantTime)
    ---@type number: the local growth
    local growth = math.round(progress * 100 / growTime, 2)
    ---@type number: the return value
    local retval = math.min(growth, 100.00)
    self.growth = retval
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
    return plants[plantId]:getData()
end)

--- Callback to get the plant data by entity
---@param source number | nil: the source player
---@param netId number: the net ID of the plant
---@return Plant | nil: the plant object
lib.callback.register('it-drugs:server:getPlantByNetId', function(source, netId)

    if Config.Debug then lib.print.info('[getPlantByNetId] - Try to get plant with netId:', netId) end
   
    for _, v in pairs(plants) do
        if v.netId == netId then
            if Config.Debug then lib.print.info('[getPlantByNetId] - Successfully get Plant with netId:', netId) end
            return v:getData()
        end
    end

    lib.print.error('[getPlantByNetId] - Plant with netId:', netId, 'does not exist')
    return nil
end)

--- Callback to get all plants owned by a player
---@param source number: the source player
---@return table | nil: the list of plants
lib.callback.register('it-drugs:server:getPlantByOwner', function(source)

    if Config.Debug then lib.print.info('[getPlantByOwner] - Try to get all plants owned by player:', source) end

    ---@type number: the player citizen ID
    local src = source
    ---@type number: the player citizen ID 
    local citId = exports.it_bridge:GetCitizenId(src)
    ---@type table: the temporary table to store the plants
    local temp = {}

    -- Loop through all the plants and check if the player owns them
    for k, v in pairs(plants) do
        if v.owner == citId then
            temp[k] = v:getData()
        end
    end
    
    -- If the player does not own any plants, return nil
    if next(temp) == nil then
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

    if Config.Debug then lib.print.info('[getPlants] - Try to get all plants') end

    ---@type table: the temporary table to store the plants
    local temp = {}

    -- Loop through all the plants and add them to the temporary table
    for k, v in pairs(plants) do
        temp[k] = v:getData()
    end

    if Config.Debug then lib.print.info('[getPlants] - Successfully get all plants') end
    return temp
end)

--- Method to setup all the weedplants, fetched from the database
--- @return boolean
local setupPlants = function()
    local result = MySQL.query.await('SELECT * FROM `drug_plants`')

    if Config.Debug then lib.print.info('[setupPlants] - Found', #result, 'plants in the database') end

    if not result then return true end

    for i = 1, #result do
        local v = result[i]
        if not Config.Plants[v.type] then
            MySQL.query('DELETE from drug_plants WHERE id = :id', {
                ['id'] = v.id
            }, function()
                lib.print.info('[setuPlant] Plant with ID: '..v.id..' has a invalid type, deleting it from the database')
            end)
        elseif v.owner == nil then
            MySQL.query('DELETE from drug_plants WHERE id = :id', {
                ['id'] = v.id
            }, function()
                lib.print.info('[setuPlant] Plant with ID: '..v.id..' has a invalid owner, deleting it from the database')
            end)
        else
            if Config.ClearOnStartup then
                if v.health == 0 then
                    MySQL.query('DELETE from drug_plants WHERE id = :id', {
                        ['id'] = v.id
                    }, function()
                        lib.print.info('[setuPlant] Plant with ID: '..v.id..' is dead, deleting it from the database')
                    end)
                else
                    local coords = json.decode(v.coords)
                    local currentPlant = Plant:new(v.id, {
                            entity = nil,
                            coords = vector3(coords.x, coords.y, coords.z),
                            dimension = v.dimension,
                            owner = v.owner,
                            plantTime = v.time,
                            plantType = Config.Plants[v.type].plantType,
                            fertilizer = v.fertilizer,
                            water = v.water,
                            health = v.health,
                            growtime = v.growtime,
                            seed = v.type,
                        }
                    )
                    currentPlant:spawn()
                end
            else
                local coords = json.decode(v.coords)
                local currentPlant = Plant:new(v.id, {
                        entity = nil,
                        coords = vector3(coords.x, coords.y, coords.z),
                        owner = v.owner,
                        dimension = v.dimension,
                        plantTime = v.time,
                        plantType = Config.Plants[v.type].plantType,
                        fertilizer = v.fertilizer,
                        water = v.water,
                        health = v.health,
                        growtime = v.growtime,
                        seed = v.type,
                    }
                )
                currentPlant:spawn()
            end
        end
    end
    TriggerClientEvent('it-drugs:client:syncPlantList', -1, plants)
    return true
end

--- Function to update the plant stats (fertilizer, water, health) every minute
updatePlantNeeds = function ()
    for plantId, plant in pairs(plants) do
        local plantData = plant:getData()
        local fertilizer = plantData.fertilizer
        local water = plantData.water

        local time = os.time()
        local planted = plantData.plantTime

        if Config.Debug then lib.print.info('[updatePlantNeeds] - Plant with ID:', plantId, 'Time:', time, 'Planted:', planted) end

        local elapsed = os.difftime(time, planted)
        -- if elapsed is < 1 minute, skip this plant
        if elapsed >= 60 then
            if Config.Debug then lib.print.info('[updatePlantNeeds] - Plant with ID:', plantId, 'is ready to be updated') end
            if fertilizer - Config.FertilizerDecay >= 0 then
                plant:updateFertilizer(math.round(fertilizer - Config.FertilizerDecay, 2))
            else
                plant:updateFertilizer(0)
            end
    
            if water - Config.WaterDecay >= 0 then
                plant:updateWater(math.round(water - Config.WaterDecay, 2))
            else
                plant:updateWater(0)
            end
            local health = plant:calcHealth()
            MySQL.update('UPDATE drug_plants SET water = (:water), fertilizer = (:fertilizer), health = (:health) WHERE id = (:id)', {
                ['water'] = plant.water,
                ['fertilizer'] = plant.fertilizer,
                ['health'] = health,
                ['id'] = plant.id,
            })
        end

        local entity = plantData.entity

        if not DoesEntityExist(entity) then
            if Config.Debug then lib.print.info('[updatePlantNeeds] - Plant with ID:', plantId, 'does not exist try to respawn the plant') end
            -- Respawn the plant
            plant:spawn()
        end

        local stage = plant:calcStage()
            if stage ~= plantData.stage then
                plant:updateProps()
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
    if Config.Debug then lib.print.info('[resoucesStart] Starting Plant Setup...') end
    setupPlants()
    while not setupPlants do
        Wait(100)
    end
    TriggerClientEvent('it-drugs:client:syncPlantList', -1)
    SendToWebhook(0, 'message', nil, {description = 'Started '..GetCurrentResourceName()..' logger'})
    updatePlantNeeds()

    if Config.Debug then lib.print.info('[resoucesStart] Finished Setup...') end

end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for plantId, plant in pairs(plants) do
        local plantData = plant:getData()
        MySQL.update('UPDATE drug_plants SET health = (:health), water = (:water), fertilizer = (:fertilizer) WHERE id = (:id)', {
            ['health'] = plant:calcHealth(),
            ['water'] = json.encode(plantData.water),
            ['fertilizer'] = json.encode(plantData.fertilizer),
            ['id'] = plantId,
        })
    end

    for _, plant in pairs(plants) do
        plant:delete()
    end
end)

--- Events

--- Event to create a new plant
---@param coords vector3: the plant coords
---@param plantItem string: name of the plant item
---@param zone string | nil: the plant zone
---@param metadata table | nil: the plant metadata
RegisterNetEvent('it-drugs:server:createNewPlant', function(coords, plantItem, zone, metadata)
    local src = source
    local plantInfos = Config.Plants[plantItem]
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then return end


    -- Remove reqItems on the server side instead of client side
    if plantInfos.reqItems and plantInfos.reqItems['planting'] ~= nil then
        local givenItems = {}
        for item, itemData in pairs(plantInfos.reqItems["planting"]) do
            if Config.Debug then lib.print.info('Checking for item: ' .. item) end -- DEBUG
            if not exports.it_bridge:HasItem(source, item, itemData.amount or 1) then
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")

                if #givenItems > 0 then
                    for _, item in pairs(givenItems) do
                        exports.it_bridge:GiveItem(source, item)
                    end
                end
                return
            else
                if itemData.remove then
                    if exports.it_bridge:RemoveItem(source, item, itemData.amount or 1) then
                        table.insert(givenItems, item)
                    end
                end
            end
        end
    end

    if exports.it_bridge:RemoveItem(src, plantItem, 1, metadata) then
        local time = os.time()
        local owner = exports.it_bridge:GetCitizenId(src)

        local growTime = Config.GlobalGrowTime
        if plantInfos.growthTime then
            growTime = plantInfos.growthTime
        end
        if Config.Zones[zone] ~= nil and Config.Zones[zone].growMultiplier then
            growTime = (growTime / Config.Zones[zone].growMultiplier)
        end

        local id = exports.it_bridge:GenerateCustomID(8)
        while plants[id] do
            id = exports.it_bridge:GenerateCustomID(8)
        end

        local currentDimension = GetPlayerRoutingBucket(src)

        MySQL.insert('INSERT INTO `drug_plants` (id, owner, coords, dimension, time, type, water, fertilizer, health, growtime) VALUES (:id, :owner, :coords, :dimension, :time, :type, :water, :fertilizer, :health, :growtime)', {
            ['id'] = id,
            ['owner'] = owner,
            ['coords'] = json.encode(coords),
            ['dimension'] = currentDimension,
            ['time'] = time,
            ['type'] = plantItem,
            ['water'] = 0.0,
            ['fertilizer'] = 0.0,
            ['health'] = 100.0,
            ['growtime'] = growTime,
        }, function()
            local currentPlant = Plant:new(id, {
                coords = coords,
                dimension = currentDimension,
                owner = owner,
                plantTime = time,
                plantType = Config.Plants[plantItem].plantType,
                fertilizer = 0.0,
                water = 0.0,
                health = 100.0,
                growtime = growTime,
                seed = plantItem,

            })
            currentPlant:spawn()
            TriggerClientEvent('it-drugs:client:syncPlantList', -1, plants)
            SendToWebhook(src, 'plant', 'plant', plants[id]:getData())
        end)
    end
end)

--- Event to take care of a plant (Gets triggered when the player uses a item on the plant)
---@param plantId string: the plant Id
---@param item string: name of the item used
RegisterNetEvent('it-drugs:server:plantTakeCare', function(plantId, item)

    if not plants[plantId] then return end
    local plant = plants[plantId]
    local plantData = plant:getData()

    local src = source
    if #(GetEntityCoords(GetPlayerPed(src)) - plantData.coords) > 10 then return end

    if exports.it_bridge:RemoveItem(src, item, 1) then
        local itemData = Config.Items[item]
        if itemData.water ~= 0 then
            local itemStrength = itemData.water
            local currentWater = plantData.water
            if currentWater + itemStrength >= 100 then
                plant:updateWater(100)
            else
                plant:updateWater(currentWater + itemStrength)
            end

            plantData = plant:getData()

            MySQL.update('UPDATE drug_plants SET water = (:water) WHERE id = (:id)', {
                ['water'] = json.encode(plantData.water),
                ['id'] = plantData.id,
            })
            SendToWebhook(src, 'plant', 'water', plantData)
        end

        if itemData.fertilizer ~= 0 then
            local itemStrength = itemData.fertilizer
            local currentFertilizer = plantData.fertilizer
            if currentFertilizer + itemStrength >= 100 then
                plant:updateFertilizer(100)
            else
                plant:updateFertilizer(currentFertilizer + itemStrength)
            end

            plantData = plant:getData()

            MySQL.update('UPDATE drug_plants SET fertilizer = (:fertilizer) WHERE id = (:id)', {
                ['fertilizer'] = json.encode(plantData.fertilizer),
                ['id'] = plantData.id,
            })
            SendToWebhook(src, 'plant', 'fertilize', plantData)
        end
        if itemData.itemBack ~= nil then
            exports.it_bridge:GiveItem(src, itemData.itemBack, 1)
        end
    end
end)

--- Event to harvest a plant
---@param plantId string: the plant Id
RegisterNetEvent('it-drugs:server:harvestPlant', function(plantId)

    if not plants[plantId] then return end
    local plant = plants[plantId]
    local plantData = plant:getData()
    
    local src = source
    if #(GetEntityCoords(GetPlayerPed(src)) - plantData.coords) > 10 then return end
    if plant:calcGrowth() ~= 100 then return end

    local extendedPlantData = Config.Plants[plantData.seed]

    if extendedPlantData.reqItems and extendedPlantData.reqItems["harvesting"] ~= nil then
        local givenItems = {}
        for item, itemData in pairs(extendedPlantData.reqItems["harvesting"]) do
            if Config.Debug then lib.print.info('Checking for item: ' .. item) end -- DEBUG
            if not exports.it_bridge:HasItem(source, item, itemData.amount or 1) then
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")

                if #givenItems > 0 then
                    for _, item in pairs(givenItems) do
                        exports.it_bridge:GiveItem(source, item)
                    end
                end
                return
            else
                if itemData.remove then
                    if exports.it_bridge:RemoveItem(source, item, itemData.amount or 1) then
                        table.insert(givenItems, item)
                    end
                end
            end
        end
    end

    if DoesEntityExist(plantData.entity) then
        for k, v in pairs(Config.Plants[plantData.seed].products) do
            local product = k
            local minAmount = v.min
            local maxAmount = v.max
            local amount = math.random(minAmount, maxAmount)
            exports.it_bridge:GiveItem(src, product, amount)
        end
        if math.random(1, 100) <= Config.Plants[plantData.seed].seed.chance then
            local seed = plantData.type

            if Config.Plants[plantData.seed].seed.max > 1 then
                local seedAmount = math.random(Config.Plants[plantData.seed].seed.min, Config.Plants[plantData.seed].seed.max)
                exports.it_bridge:GiveItem(src, plantData.seed, seedAmount)
            end
        end
  
        MySQL.query('DELETE from drug_plants WHERE id = :id', {
            ['id'] = plantData.id
        })

        plant:delete()
        TriggerClientEvent('it-drugs:client:syncPlantList', -1, plants)
        SendToWebhook(src, 'plant', 'harvest', plantData)
    end
end)

--- Event to destroy a plant
---@param args table: the event arguments
RegisterNetEvent('it-drugs:server:destroyPlant', function(args)
    local plant = plants[args.plantId]
    if not plant then return end
    
    if not args.extra then
        if #(GetEntityCoords(GetPlayerPed(source)) - plant.coords) > 10 then return end
    end
    
    SendToWebhook(source, 'plant', 'destroy', plant:getData())
    if DoesEntityExist(plant.entity) then
      
        TriggerClientEvent('it-drugs:client:startPlantFire', -1, plant.coords)
        Wait(Config.FireTime / 2)

        plant:delete()

        MySQL.query('DELETE from drug_plants WHERE id = :id', {
            ['id'] = plant.id
        })
        plant:delete()
        TriggerClientEvent('it-drugs:client:syncPlantList', -1, plants)
    end
end)