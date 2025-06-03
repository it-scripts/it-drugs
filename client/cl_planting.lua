--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
-- Client-side planting system for the drugs resource
-- Handles plant placement, interaction, and management

local growZones = {}
local cachedZoneResults = {}

-- Initialize grow zones from config
-- These are areas where plants can be grown with specific properties
for k, v in pairs(Config.Zones) do
    local coords = {}
    for _, point in ipairs(v.points) do
        table.insert(coords, vector3(point.x, point.y, point.z))
    end

    growZones[k] = lib.zones.poly({
        points = coords,
        thickness = v.thickness,
        debug = Config.DebugPoly,
    })
    if Config.Debug then lib.print.info('[Planting] Created zone: ' .. k .. ' with ' .. #coords .. ' points') end
end

--- Get the ground material hash at a location
---@param coords vector3 Position to check
---@return integer Ground material hash
local GetGroundHash = function(coords)
    if Config.Debug then lib.print.debug('[Planting:GetGroundHash] Checking ground at: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z) end
    local shapeTestCapsule =
        StartShapeTestCapsule(coords.x, coords.y, coords.z + 4, coords.x, coords.y, coords.z - 2.0, 2, 1, 0, 7)
    local _, _, _, _, groundHash = GetShapeTestResultEx(shapeTestCapsule)
    if Config.Debug then lib.print.debug('[Planting:GetGroundHash] Found hash: ' .. groundHash) end
    return groundHash
end

--- Check if coordinates are within a specified grow zone
---@param coords vector3 Position to check
---@param targetZones table Array of zone names to check
---@return string|nil Zone ID if found, nil otherwise
local function checkforZones(coords, targetZones)
    if not targetZones or #targetZones == 0 then return nil end
    
    -- Create cache key for performance
    local cacheKey = tostring(coords.x)..tostring(coords.y)..tostring(coords.z)
    
    -- Check cache for recent results (10 second cache)
    if cachedZoneResults[cacheKey] then
        if GetGameTimer() - cachedZoneResults[cacheKey].time < 10000 then
            if Config.Debug then lib.print.debug('[Planting:checkforZones] Using cached result for: ' .. cacheKey) end
            return cachedZoneResults[cacheKey].result
        end
    end
    
    -- Check if coords are in any target zone
    for _, targetZone in pairs(targetZones) do
        for id, zone in pairs(growZones) do
            if zone:contains(vector3(coords.x, coords.y, coords.z)) and id == targetZone then
                if Config.Debug then lib.print.info('[Planting:checkforZones] Position is in zone: ' .. id) end
                cachedZoneResults[cacheKey] = {result = id, time = GetGameTimer()}
                return id
            end
        end      
    end
    
    if Config.Debug then lib.print.debug('[Planting:checkforZones] Position is not in any target zone') end
    cachedZoneResults[cacheKey] = {result = nil, time = GetGameTimer()}
    return nil
end

--- Plant a new seed at the specified coordinates
---@param ped number Current player ped
---@param plantItem string Plant item name
---@param coords vector3 Plant coordinates
---@param metadata table|nil Plant metadata
function PlantSeed(ped, plantItem, coords, metadata)
    if Config.Debug then lib.print.info('[Planting:plantSeed] Attempting to plant ' .. plantItem .. ' at ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z) end

    local plantInfos = Config.Plants[plantItem]
    if not plantInfos then
        if Config.Debug then lib.print.error('[Planting:plantSeed] Unknown plant item: ' .. plantItem) end
        ShowNotification(nil, _U('NOTIFICATION__INVALID__PLANT'), "Error")
        return
    end

    -- Check plant limits per player
    local ownedPlants = lib.callback.await('it-drugs:server:getPlantByOwner', false)
    if Config.Debug then lib.print.debug('[Planting:useSeed] Player has ' .. (ownedPlants and #ownedPlants or 0) .. ' owned plants') end

    if ownedPlants ~= nil then
        local plantCount = 0
        for _, plant in pairs(ownedPlants) do
            if plant.seed == plantItem then
                plantCount = plantCount + 1
            end
        end

        if plantCount >= Config.PlayerPlantLimit then
            if Config.Debug then lib.print.warn('[Planting:useSeed] Player has reached plant limit: ' .. plantCount .. '/' .. Config.PlayerPlantLimit) end
            ShowNotification(nil, _U('NOTIFICATION__MAX__PLANTS'), "Error")
            return
        end
    end

    -- Check for nearby plants to prevent overlapping
    local plants = lib.callback.await('it-drugs:server:getPlants', false)
    if Config.Debug then lib.print.debug('[Planting:plantSeed] Got ' .. (plants and #plants or 0) .. ' existing plants from server') end

    -- Validate minimum distance from other plants
    if plants ~= nil then
        for _, v in pairs(plants) do
            local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(v.coords.x, v.coords.y, v.coords.z))
            if distance <= Config.PlantDistance then
                if Config.Debug then lib.print.warn('[Planting:plantSeed] Too close to another plant: ' .. distance .. ' units') end
                ShowNotification(nil, _U('NOTIFICATION__TO__NEAR'), "Error")
                return
            end
        end
    end

    -- Check if the ground is valid for planting
    if Config.OnlyAllowedGrounds then
        local groundHash = GetGroundHash(coords)
        local canplant = false
        if Config.Debug then lib.print.info('[Planting:plantSeed] Ground hash: ' .. groundHash) end
        
        for _, ground in pairs(Config.AllowedGrounds) do
            if groundHash == ground then
                canplant = true
                break
            end
        end

        if not canplant then
            if Config.Debug then lib.print.warn('[Planting:plantSeed] Invalid ground type for planting') end
            ShowNotification(nil, _U('NOTIFICATION__CANT__PLACE'), "Error")
            return
        end
    end

    -- Check if the location is in a valid grow zone
    local zone = checkforZones(coords, plantInfos.zones)
    if Config.Debug then lib.print.info('[Planting:plantSeed] Current zone: ' .. (zone or "none")) end
    
    if plantInfos.onlyZone and zone == nil then
        if Config.Debug then lib.print.warn('[Planting:plantSeed] This plant requires a specific grow zone') end
        ShowNotification(nil, _U('NOTIFICATION__CANT__PLACE'), "Error")
        return
    end

    -- Verify required items for planting
    if plantInfos.reqItems and plantInfos.reqItems["planting"] ~= nil then
        for item, itemData in pairs(plantInfos.reqItems["planting"]) do
            if Config.Debug then lib.print.debug('[Planting:plantSeed] Checking for required item: ' .. item) end
            if not exports.it_bridge:HasItem(item, itemData.amount or 1) then
                if Config.Debug then lib.print.warn('[Planting:plantSeed] Missing required item: ' .. item) end
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")

                TriggerEvent('it-drugs:client:syncRestLoop', false)
                return
            end
        end
    end

    -- Load animation dictionaries
    if Config.Debug then lib.print.debug('[Planting:plantSeed] Loading animation dictionaries') end
    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do
        Wait(0)
    end

    -- Play planting animation
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, false, false)

    -- Show progress bar and plant if successful
    if ShowProgressBar({
        duration = plantInfos.time,
        label = _U('PROGRESSBAR__SPAWN__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true,
        },
    }) then
        if Config.Debug then lib.print.info('[Planting:plantSeed] Planting successful, creating on server') end
        TriggerServerEvent('it-drugs:server:createNewPlant', coords, plantItem, zone, metadata)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        if Config.Debug then lib.print.info('[Planting:plantSeed] Planting cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end

    TriggerEvent('it-drugs:client:syncRestLoop', false)
end

--- Handle harvesting a plant
RegisterNetEvent('it-drugs:client:harvestPlant', function(args)
    if Config.Debug then lib.print.info('[Planting:harvestPlant] Attempting to harvest plant') end
    
    local plantData = args.plantData
    local clientData = GetPlantData(plantData.id)
    local entity = clientData.entity

    -- Check for required harvesting items
    plantData.reqItems = Config.Plants[plantData.seed].reqItems
    if plantData.reqItems and plantData.reqItems["harvesting"] ~= nil then
        for item, itemData in pairs(plantData.reqItems["harvesting"]) do
            if Config.Debug then lib.print.debug('[Planting:harvestPlant] Checking for required item: ' .. item) end
            if not exports.it_bridge:HasItem(item, itemData.amount or 1) then
                if Config.Debug then lib.print.warn('[Planting:harvestPlant] Missing required item: ' .. item) end
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")
                TriggerEvent('it-drugs:client:syncRestLoop', false)
                return
            end
        end
    end

    -- Position player to face the plant
    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)

    -- Load animation dictionaries
    if Config.Debug then lib.print.debug('[Planting:harvestPlant] Loading animation dictionaries') end
    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while 
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do 
        Wait(0)
    end
    
    -- Play harvesting animations
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, false, false)

    -- Show progress bar and harvest if successful
    if ShowProgressBar({
        duration = Config.Plants[plantData.seed].time,
        label = _U('PROGRESSBAR__HARVEST__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true,
        },
    }) then
        if Config.Debug then lib.print.info('[Planting:harvestPlant] Harvest successful for plant ID: ' .. plantData.id) end
        TriggerServerEvent('it-drugs:server:harvestPlant', plantData.id)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        if Config.Debug then lib.print.info('[Planting:harvestPlant] Harvest cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end
    
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end)

--- Apply water to a plant
---@param args table Contains plant data and item used
local giveWater = function(args)
    local item = args.item
    local plantData = args.plantData
    
    if Config.Debug then lib.print.info('[Planting:giveWater] Applying water to plant ID: ' .. plantData.id .. ' with item: ' .. item) end
    
    local clientData = GetPlantData(plantData.id)
    local entity = clientData.entity

    -- Position player and prepare props
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local model = 'prop_wateringcan'
    
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)
    
    -- Load model and particle effects
    if Config.Debug then lib.print.debug('[Planting:giveWater] Loading model and effects') end
    lib.requestModel(model)
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end
    
    -- Create watering can prop and attach to player
    SetPtfxAssetNextCall('core')
    local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.4, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
    
    -- Start water particle effect
    local effect = StartParticleFxLoopedOnEntity('ent_sht_water', created_object, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)

    -- Show progress bar and process if successful
    if ShowProgressBar({
        duration = Config.Plants[plantData.seed].time,
        label = _U('PROGRESSBAR__SOAK__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true,
        },
        anim = {
            dict = 'weapon@w_sp_jerrycan',
            clip = 'fire',
        },
    }) then
        if Config.Debug then lib.print.info('[Planting:giveWater] Successfully watered plant ID: ' .. plantData.id) end
        TriggerServerEvent('it-drugs:server:plantTakeCare', plantData.id, item)
        ClearPedTasks(ped)
        DeleteEntity(created_object)
        StopParticleFxLooped(effect, false)
    else
        if Config.Debug then lib.print.info('[Planting:giveWater] Watering cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        DeleteEntity(created_object)
        StopParticleFxLooped(effect, false)
    end
end

--- Apply fertilizer to a plant
---@param args table Contains plant data and item used
local giveFertilizer = function(args)
    local item = args.item
    local plantData = args.plantData
    
    if Config.Debug then lib.print.info('[Planting:giveFertilizer] Applying fertilizer to plant ID: ' .. plantData.id .. ' with item: ' .. item) end
    
    local clientData = GetPlantData(plantData.id)
    local entity = clientData.entity

    -- Position player and prepare props
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local model = 'w_am_jerrycan_sf'
    
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)
    
    -- Load model
    if Config.Debug then lib.print.debug('[Planting:giveFertilizer] Loading model: ' .. model) end
    lib.requestModel(model)
    
    -- Create fertilizer prop and attach to player
    local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.3, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)

    -- Show progress bar and process if successful
    if ShowProgressBar({
        duration = Config.Plants[plantData.seed].time,
        label = _U('PROGRESSBAR__FERTILIZE__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true,
        },
        anim = {
            dict = 'weapon@w_sp_jerrycan',
            clip = 'fire',
        },
    }) then
        if Config.Debug then lib.print.info('[Planting:giveFertilizer] Successfully fertilized plant ID: ' .. plantData.id) end
        TriggerServerEvent('it-drugs:server:plantTakeCare', plantData.id, item)
        ClearPedTasks(ped)
        DeleteEntity(created_object)
    else
        if Config.Debug then lib.print.info('[Planting:giveFertilizer] Fertilizing cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        DeleteEntity(created_object)
    end
end

--- Handle using items on plants (water or fertilizer)
RegisterNetEvent('it-drugs:client:useItem', function (args)
    local item = args.item
    
    if Config.Debug then lib.print.info('[Planting:useItem] Using item: ' .. item .. ' on plant ID: ' .. args.plantData.id) end

    -- Check if player has the item
    if not exports.it_bridge:HasItem(item, 1) then
        if Config.Debug then lib.print.warn('[Planting:useItem] Player does not have item: ' .. item) end
        ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")
        return
    end

    -- Determine item type and apply appropriate function
    local itemInfos = Config.Items[item]
    if itemInfos.water ~= 0 then
        giveWater(args)
    elseif itemInfos.fertilizer ~= 0 then
        giveFertilizer(args)
    end
    
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end)

--- Handle destroying a plant
RegisterNetEvent('it-drugs:client:destroyPlant', function(args)
    if Config.Debug then lib.print.info('[Planting:destroyPlant] Attempting to destroy plant') end
    
    -- Check for required destroy item if configured
    if Config.ItemToDestroyPlant and not exports.it_bridge:HasItem(Config.DestroyItemName, 1) then
        if Config.Debug then lib.print.warn('[Planting:destroyPlant] Missing required item to destroy: ' .. Config.DestroyItemName) end
        ShowNotification(nil, _U('NOTIFICATION__NEED_LIGHTER'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    local plantData = args.plantData
    local type = plantData.seed

    local clientData = GetPlantData(plantData.id)
    local entity = clientData.entity

    -- Position player to face the plant
    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)

    -- Load animation dictionaries
    if Config.Debug then lib.print.debug('[Planting:destroyPlant] Loading animation dictionaries') end
    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while 
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do 
        Wait(0)
    end
    
    -- Play destroy animations
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, false, false)

    -- Show progress bar and destroy if successful
    if ShowProgressBar({
        duration = Config.Plants[type].time,
        label = _U('PROGRESSBAR__DESTROY__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true,
        },
    }) then
        if Config.Debug then lib.print.info('[Planting:destroyPlant] Successfully destroyed plant ID: ' .. plantData.id) end
        TriggerServerEvent('it-drugs:server:destroyPlant', {plantId = plantData.id})
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        if Config.Debug then lib.print.info('[Planting:destroyPlant] Destruction cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end
    
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end)

--- Create fire effect for destroyed plants
RegisterNetEvent('it-drugs:client:startPlantFire', function(coords)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    
    -- Only show fire if player is within range (performance optimization)
    if #(pedCoords - vector3(coords.x, coords.y, coords.z)) > 300 then return end
    
    if Config.Debug then lib.print.info('[Planting:startPlantFire] Creating fire effect at: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z) end

    -- Load fire particle effect
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end
    
    -- Start the fire effect
    SetPtfxAssetNextCall('core')
    local effect = StartParticleFxLoopedAtCoord('ent_ray_paleto_gas_flames', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.6, false, false, false, false)
    
    -- Burn for configured duration then stop
    Wait(Config.FireTime)
    if Config.Debug then lib.print.debug('[Planting:startPlantFire] Stopping fire effect after ' .. Config.FireTime .. 'ms') end
    StopParticleFxLooped(effect, false)
end)
