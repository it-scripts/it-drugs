--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
math = lib.math
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
                    Plant:new(v.id, {
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
                end
            else
                local coords = json.decode(v.coords)
                Plant:new(v.id, {
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
            end
        end
    end
    TriggerClientEvent('it-drugs:client:syncPlants', -1, Plants)
    return true
end

--- Function to update the plant stats (fertilizer, water, health) every minute
updatePlantNeeds = function ()
    for plantId, plant in pairs(Plants) do
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
                TriggerClientEvent('it-drugs:client:it-drugs:client:plantUpdate', -1, plantId)
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
    TriggerClientEvent('it-drugs:client:syncPlants', -1)
    SendToWebhook(0, 'message', nil, {description = 'Started '..GetCurrentResourceName()..' logger'})
    updatePlantNeeds()

    if Config.Debug then lib.print.info('[resoucesStart] Finished Setup...') end

end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for plantId, plant in pairs(Plants) do
        local plantData = plant:getData()
        MySQL.update('UPDATE drug_plants SET health = (:health), water = (:water), fertilizer = (:fertilizer) WHERE id = (:id)', {
            ['health'] = plant:calcHealth(),
            ['water'] = json.encode(plantData.water),
            ['fertilizer'] = json.encode(plantData.fertilizer),
            ['id'] = plantId,
        })
    end

    for _, plant in pairs(Plants) do
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
        while Plants[id] do
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
            TriggerClientEvent('it-drugs:client:syncPlants', -1, Plants)
            SendToWebhook(src, 'plant', 'plant', Plants[id]:getData())
        end)
    end
end)

--- Event to take care of a plant (Gets triggered when the player uses a item on the plant)
---@param plantId string: the plant Id
---@param item string: name of the item used
RegisterNetEvent('it-drugs:server:plantTakeCare', function(plantId, item)

    if not Plants[plantId] then return end
    local plant = Plants[plantId]
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
    if not Plants[plantId] then return end
    local plant = Plants[plantId]
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
        TriggerClientEvent('it-drugs:client:syncPlants', -1, Plants)
        SendToWebhook(src, 'plant', 'harvest', plantData)
    end
end)

--- Event to destroy a plant
---@param args table: the event arguments
RegisterNetEvent('it-drugs:server:destroyPlant', function(args)
    local plant = Plants[args.plantId]
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
        TriggerClientEvent('it-drugs:client:syncPlants', -1, Plants)
    end
end)