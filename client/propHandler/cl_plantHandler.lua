--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
local serverFramework = exports.it_bridge:GetServerFramework()
local serverInteraction = exports.it_bridge:GetServerInteraction()

local updateLoopStarted = false

local serverPlants = {}
local spawnedPlants = {}
local lastCoordinates = nil
local lastBucket = nil
local checkFrequency = Config.CheckFrequency -- Configurable check frequency

-- Performance optimizations
local modelCache = {} -- Cache für geladene Models
local playerPed = PlayerPedId()
local lastPlayerUpdate = 0
local PLAYER_UPDATE_INTERVAL = 1000 -- Update PlayerPed alle 1 Sekunde
local DISTANCE_CHECK_THRESHOLD = 10.0 -- Schwellenwert für Distanzcheck

-- Optimierte Model Loading mit Cache
local function loadModel(hash)
    if Config.Debug then lib.print.info('[loadModel] - Loading model hash:', hash) end
    
    -- Prüfe ob Model bereits im Cache ist
    if modelCache[hash] then
        if Config.Debug then lib.print.info('[loadModel] - Model bereits im Cache:', hash) end
        return hash
    end
    
    local timeout = 500
    lib.requestModel(hash, timeout)
    modelCache[hash] = true -- Model in Cache speichern
    
    if Config.Debug then lib.print.info('[loadModel] - Model loaded successfully:', hash) end
    return hash
end

-- Cache PlayerPed für bessere Performance
local function getPlayerPed()
    local currentTime = GetGameTimer()
    if currentTime - lastPlayerUpdate > PLAYER_UPDATE_INTERVAL then
        playerPed = PlayerPedId()
        lastPlayerUpdate = currentTime
    end
    return playerPed
end

local function generatePlantTargetData(plantData, plantModel, entity)
    if Config.Debug then lib.print.info('[generatePlantTargetData] - Generating target data for plant:', plantData) end

    local minSize, maxSize = GetModelDimensions(plantModel)
    local size = vector3(maxSize.x - minSize.x, maxSize.y - minSize.y, maxSize.z - minSize.z)

    local plantCoords = GetEntityCoords(entity)
    local plantRotation = GetEntityHeading(entity)

    if exports.it_bridge:GetServerInteraction() == 'qb-target' then
        plantRotation = plantRotation + 90.0
    end

    local targetData = {
        id = plantData.id,
        coords = vector3(plantCoords.x, plantCoords.y, plantCoords.z + plantData.zOffset),
        size = size,
        rotation = plantRotation,
        drawSprite = true,
        interactDistance = 1.5,
        minZ = plantCoords.z + plantData.zOffset,
        maxZ = plantCoords.z + (size.z / 2),
        debug = Config.Debug,
    }

    local target = CreatePlantBoxTarget(targetData)
    return target
end

local function spawnPlant(plantId)
    if Config.Debug then lib.print.info('[spawnPlant] - Try to spawning plant with ID:', plantId) end
    
    -- Don't respawn already spawned plants
    if spawnedPlants[plantId] then
        if Config.Debug then lib.print.info('[spawnPlant] - Plant already spawned, skipping:', plantId) end
        return
    end
    
    local plantData = lib.callback.await('it-drugs:server:getPlantById', false, plantId)
    if not plantData then
        if Config.Debug then lib.print.error('[spawnPlant] - Plant data not found for ID:', plantId) end
        return
    end
    if Config.Debug then lib.print.info('[spawnPlant] - Received plant data for ID:', plantId, 'Type:', plantData.plantType, 'Stage:', plantData.stage) end

    local plantType = plantData.plantType
    local stage = plantData.stage
    local coords = plantData.coords
    
    -- Use cached model hash
    local modelHash = Config.PlantTypes[plantType][stage][1]
    local zOffset = Config.PlantTypes[plantType][stage][2]

    plantData.zOffset = zOffset -- Store zOffset in plantData for later use
    if Config.Debug then lib.print.info('[spawnPlant] - Using model hash:', modelHash, 'with zOffset:', zOffset) end

    -- Request model with timeout
    modelHash = loadModel(modelHash)

    -- Create entity after model is loaded
    if Config.Debug then lib.print.info('[spawnPlant] - Creating object at position:', coords.x, coords.y, coords.z + zOffset) end
    local plantEntity = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z + zOffset, false, true, false)
    if not DoesEntityExist(plantEntity) then
        if Config.Debug then lib.print.error('[spawnPlant] - Failed to create plant entity:', plantId) end
        return
    end
    if Config.Debug then lib.print.info('[spawnPlant] - Entity created successfully with handle:', plantEntity) end
    
    FreezeEntityPosition(plantEntity, true)
    if Config.Debug then lib.print.info('[spawnPlant] - Entity position frozen') end

    -- Create Plant target
    local plantTaget = nil
    if serverInteraction ~= nil then
        plantTaget = generatePlantTargetData(plantData, modelHash, plantEntity)
    end
    
    -- Store plant data
    spawnedPlants[plantId] = {
        entity = plantEntity,
        coords = coords,
        modelHash = modelHash,
        target = plantTaget,
    }
    if Config.Debug then lib.print.info('[spawnPlant] - Plant stored in cache with entity:', plantEntity) end
    
    SetModelAsNoLongerNeeded(modelHash)

    if Config.Debug then lib.print.info('[spawnPlant] - Plant spawned with ID:', plantId) end
end

local function deletePlant(plantId)
    if Config.Debug then lib.print.info('[deletePlant] - Try to deleting plant with ID:', plantId) end
    
    local plant = spawnedPlants[plantId]
    if not plant then
        if Config.Debug then lib.print.info('[deletePlant] - Plant not found in cache, nothing to delete:', plantId) end
        return
    end
    
    if DoesEntityExist(plant.entity) then
        if Config.Debug then lib.print.info('[deletePlant] - Deleting entity:', plant.entity, 'for plant:', plantId) end
        
        if plant.target then
            exports.it_bridge:RemoveBoxZone(plant.target)
        end
        DeleteObject(plant.entity)
        
        if Config.Debug then lib.print.info('[deletePlant] - Plant deleted with ID:', plantId) end
    else
        if Config.Debug then lib.print.warn('[deletePlant] - Entity does not exist for plant:', plantId) end
    end
    
    spawnedPlants[plantId] = nil
    if Config.Debug then lib.print.info('[deletePlant] - Removed plant from cache:', plantId) end
end

local function updatePlant(plantId)
    if Config.Debug then lib.print.info('[updatePlant] - Try to updating plant with ID:', plantId) end
    
    -- Check if plant exists in cache before updating
    if not spawnedPlants[plantId] then
        if Config.Debug then lib.print.info('[updatePlant] - Plant not found in cache, skipping update:', plantId) end
        return
    end
    
    -- Get the latest plant data
    local plantData = lib.callback.await('it-drugs:server:getPlantById', false, plantId)
    if not plantData then
        if Config.Debug then lib.print.error('[updatePlant] - Failed to get plant data from server:', plantId) end
        return
    end
    if Config.Debug then lib.print.info('[updatePlant] - Received updated data for plant:', plantId, 'Type:', plantData.plantType, 'Stage:', plantData.stage) end
    
    local plantType = plantData.plantType
    local stage = plantData.stage
    local coords = plantData.coords
    
    -- Use cached model if available
    local modelHash = Config.PlantTypes[plantType][stage][1]
    local zOffset = Config.PlantTypes[plantType][stage][2]
    
    -- Check if model is different from current plant to avoid unnecessary updates
    local plant = spawnedPlants[plantId]
    if plant.modelHash == modelHash then
        if Config.Debug then lib.print.info('[updatePlant] - Model unchanged, only updating position for plant:', plantId) end
        -- Only update position if needed
        SetEntityCoords(plant.entity, coords.x, coords.y, coords.z + zOffset, false, false, false, false)
        return
    end
    
    if Config.Debug then lib.print.info('[updatePlant] - Model changed from', plant.modelHash, 'to', modelHash, 'for plant:', plantId) end
    
    -- If model is different, delete and recreate
    modelHash = loadModel(modelHash)
    
    if DoesEntityExist(plant.entity) then
        if Config.Debug then lib.print.info('[updatePlant] - Deleting old entity:', plant.entity) end
        DeleteEntity(plant.entity)
    else
        if Config.Debug then lib.print.warn('[updatePlant] - Old entity does not exist for plant:', plantId) end
    end
    
    if Config.Debug then lib.print.info('[updatePlant] - Creating new entity at:', coords.x, coords.y, coords.z + zOffset) end
    local plantEntity = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z + zOffset, false, true, false)
    FreezeEntityPosition(plantEntity, true)
    
    -- Update plant data
    spawnedPlants[plantId] = {
        entity = plantEntity,
        coords = coords,
        modelHash = modelHash
    }
    if Config.Debug then lib.print.info('[updatePlant] - Updated cache with new entity:', plantEntity) end
    
    SetModelAsNoLongerNeeded(modelHash)
    
    if Config.Debug then lib.print.info('[updatePlant] - Plant updated with ID:', plantId) end
end

-- Batch distance calculation für bessere Performance
local function calculateDistancesBatch(playerCoords, plants)
    local results = {}
    local x1, y1, z1 = playerCoords.x, playerCoords.y, playerCoords.z
    
    for plantId, plantData in pairs(plants) do
        if plantData and plantData.coords then
            local x2, y2, z2 = plantData.coords.x, plantData.coords.y, plantData.coords.z
            -- Optimierte Distanzberechnung ohne Wurzel für erste Filterung
            local distanceSquared = (x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2
            local distanceThresholdSquared = Config.MinPropDistance^2
            
            results[plantId] = {
                distance = distanceSquared <= distanceThresholdSquared and math.sqrt(distanceSquared) or nil,
                inRange = distanceSquared <= distanceThresholdSquared,
                dimension = plantData.dimension
            }
        end
    end
    
    return results
end

-- Effiziente Batch-Verarbeitung von Pflanzen
local function processPlantsInView()
    if Config.Debug then lib.print.info('[processPlantsInView] - Processing plants in view') end
    
    local currentPlayerCoords = GetEntityCoords(getPlayerPed())
    local currentBucket = lib.callback.await('it-drugs:server:getPlayerBucket', false)
    
    -- Prüfe ob Player sich bedeutend bewegt hat
    local playerHasMoved = not lastCoordinates or #(currentPlayerCoords - lastCoordinates) > DISTANCE_CHECK_THRESHOLD
    
    if lastBucket ~= currentBucket then
        if Config.Debug then lib.print.info('[processPlantsInView] - Player bucket changed from', lastBucket, 'to', currentBucket) end
        lastBucket = currentBucket
        playerHasMoved = true -- Force update if bucket changes
    end
    
    if not playerHasMoved then
        if Config.Debug then lib.print.info('[processPlantsInView] - Player has not moved significantly, skipping update') end
        return
    end
    
    if Config.Debug then lib.print.info('[processPlantsInView] - Player moved from previous position, distance:', not lastCoordinates and "n/a" or #(currentPlayerCoords - lastCoordinates)) end
    lastCoordinates = currentPlayerCoords
    
    -- Batch distance calculation
    local distanceResults = calculateDistancesBatch(currentPlayerCoords, serverPlants)
    
    -- Collect plants to process
    local plantsToSpawn = {}
    local plantsToDelete = {}
    local plantsCount = 0
    
    for plantId, result in pairs(distanceResults) do
        plantsCount = plantsCount + 1
        
        if result.inRange and result.dimension == currentBucket and not spawnedPlants[plantId] then
            plantsToSpawn[plantId] = true
        elseif (not result.inRange or result.dimension ~= currentBucket) and spawnedPlants[plantId] then
            plantsToDelete[plantId] = true
        end
    end
    
    local spawnCount = 0
    local deleteCount = 0
    for _ in pairs(plantsToSpawn) do spawnCount = spawnCount + 1 end
    for _ in pairs(plantsToDelete) do deleteCount = deleteCount + 1 end
    
    if Config.Debug then 
        lib.print.info('[processPlantsInView] - Total plants:', plantsCount)
        lib.print.info('[processPlantsInView] - Plants to spawn:', spawnCount)
        lib.print.info('[processPlantsInView] - Plants to delete:', deleteCount)
    end
    
    -- Execute actions on collected plants
    for plantId in pairs(plantsToSpawn) do
        spawnPlant(plantId)
    end
    
    for plantId in pairs(plantsToDelete) do
        deletePlant(plantId)
    end
    
    if Config.Debug then
        local currentSpawned = 0
        for _ in pairs(spawnedPlants) do currentSpawned = currentSpawned + 1 end
        lib.print.info('[processPlantsInView] - Current spawned plants count:', currentSpawned)
    end
end

function PlantUpdateLoop()
    updateLoopStarted = true
    if Config.Debug then lib.print.info('[UpdateLoop] - Running update loop') end
    processPlantsInView()
    
    -- Adaptive timing: weniger häufig prüfen wenn Player sich nicht bewegt
    local currentCoords = GetEntityCoords(getPlayerPed())
    local currentBucket = lib.callback.await('it-drugs:server:getPlayerBucket', false)
    local stationary = lastCoordinates and #(currentCoords - lastCoordinates) < 2.0 -- Erhöhter Threshold
    
    -- Dynamisches Intervall basierend auf Aktivität
    local interval = checkFrequency
    if stationary then
        interval = math.min(checkFrequency * 3, 15000) -- Bis zu 15 Sekunden wenn stationär
    elseif currentBucket ~= lastBucket then
        interval = 100 -- Sofortiges Update bei Bucket-Wechsel
    end
    
    if Config.Debug then 
        lib.print.info('[UpdateLoop] - Player stationary:', stationary)
        lib.print.info('[UpdateLoop] - Next update in', interval, 'ms')
    end
    
    SetTimeout(interval, PlantUpdateLoop)
end

local function requestAllPlantsFromServer()
    if Config.Debug then lib.print.info('[requestAllPlantsFromServer] - Requesting all plants from server') end
    local plants = lib.callback.await('it-drugs:server:getPlants', false)
    if not plants then
        if Config.Debug then lib.print.error('[requestAllPlantsFromServer] - Failed to get plants from server') end
        return
    end
    
    -- Create a properly structured serverPlants table
    local plantCount = 0
    serverPlants = {}
    for k, v in pairs(plants) do
        serverPlants[k] = v -- Store full plant data, not just boolean
        plantCount = plantCount + 1
    end
    
    if Config.Debug then lib.print.info('[requestAllPlantsFromServer] - Received', plantCount, 'plants from server') end
    
    -- Begin update loop after data is received
    lastCoordinates = GetEntityCoords(PlayerPedId())
    if not updateLoopStarted then
        PlantUpdateLoop()
    end
end

-- Cleanup-Funktion für bessere Memory-Verwaltung
local function cleanupUnusedModels()
    local usedModels = {}
    
    -- Sammle alle aktuell verwendeten Models
    for _, plant in pairs(spawnedPlants) do
        if plant.modelHash then
            usedModels[plant.modelHash] = true
        end
    end
    
    -- Entferne nicht verwendete Models aus dem Cache
    for hash in pairs(modelCache) do
        if not usedModels[hash] then
            SetModelAsNoLongerNeeded(hash)
            modelCache[hash] = nil
            if Config.Debug then lib.print.info('[cleanupUnusedModels] - Removed unused model from cache:', hash) end
        end
    end
end

-- Periodische Cleanup alle 5 Minuten
CreateThread(function()
    while true do
        Wait(300000) -- 5 Minuten
        cleanupUnusedModels()
    end
end)

function GetPlantData(plantId)
    if Config.Debug then lib.print.info('[GetPlantData] - Getting data for plant ID:', plantId) end
    return serverPlants[plantId]
end

-- Optimierte Plant Sync mit weniger Callback-Aufrufen
RegisterNetEvent('it-drugs:client:syncPlants', function(plants)
    if not plants then
        if Config.Debug then lib.print.warn('[it-drugs:client:syncPlants] - Received nil plants data') end
        return
    end
    if Config.Debug then lib.print.info('[it-drugs:client:syncPlants] - Syncing plants') end
    
    local playerCoords = GetEntityCoords(getPlayerPed())
    local newPlants = {}
    local removedPlants = {}
    
    -- Find new and removed plants
    for k, v in pairs(plants) do
        if not serverPlants[k] then
            newPlants[k] = v
        end
    end
    
    for k in pairs(serverPlants) do
        if not plants[k] then
            removedPlants[k] = true
        end
    end
    
    local newCount = 0
    local removedCount = 0
    for _ in pairs(newPlants) do newCount = newCount + 1 end
    for _ in pairs(removedPlants) do removedCount = removedCount + 1 end
    
    if Config.Debug then
        lib.print.info('[it-drugs:client:syncPlants] - New plants:', newCount)
        lib.print.info('[it-drugs:client:syncPlants] - Removed plants:', removedCount)
    end
    
    -- Update the server plants cache
    serverPlants = plants
    
    -- Handle removed plants first
    for plantId in pairs(removedPlants) do
        deletePlant(plantId)
    end
    
    -- Handle new plants that are in range - nur einmal Bucket abfragen
    if newCount > 0 then
        local currentPlayerBucket = lib.callback.await('it-drugs:server:getPlayerBucket', false)
        lastBucket = currentPlayerBucket -- Update last bucket for next checks
        
        -- Batch distance calculation für neue Pflanzen
        local distanceResults = calculateDistancesBatch(playerCoords, newPlants)
        
        for plantId, result in pairs(distanceResults) do
            if result.inRange and result.dimension == currentPlayerBucket then
                if Config.Debug then lib.print.info('[it-drugs:client:syncPlants] - New plant', plantId, 'is in range (', result.distance, 'm), spawning') end
                spawnPlant(plantId)
            else
                if Config.Debug then lib.print.info('[it-drugs:client:syncPlants] - New plant', plantId, 'is out of range or wrong dimension, not spawning') end
            end
        end
    end

    if not updateLoopStarted then
        PlantUpdateLoop()
    end
end)

RegisterNetEvent('it-drugs:client:plantUpdate', function(plantId)
    if Config.Debug then lib.print.info('[it-drugs:client:plantUpdate] - Received update for plant:', plantId) end
    if not spawnedPlants[plantId] then
        if Config.Debug then lib.print.info('[it-drugs:client:plantUpdate] - Plant not spawned, skipping update:', plantId) end
        return
    end
    updatePlant(plantId)
end)

-- Initialize when player loads
local function initializePlantHandler()
    Wait(500) -- Reduced delay
    requestAllPlantsFromServer()
end

if serverFramework == 'es_extended' then
    AddEventHandler('esx:playerLoaded', function(_, _)
        if Config.Debug then lib.print.info('[cl_plantHandler] - ESX player loaded event triggered') end
        initializePlantHandler()
    end)
elseif serverFramework == 'qb-core' or serverFramework == 'qbx_core' then
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        if Config.Debug then lib.print.info('[cl_plantHandler] - QBCore player loaded event triggered') end
        initializePlantHandler()
    end)
elseif serverFramework == 'ND_Core' then
    AddEventHandler("ND:characterLoaded", function()
        if Config.Debug then lib.print.info('[cl_plantHandler] - ND player loaded event triggered') end
        initializePlantHandler()
    end)
else
    if Config.Debug then lib.print.error('[cl_plantHandler] - Unknown framework:', serverFramework) end
    lib.print.error('[cl_plantHandler] Unable to load player please check cl_plantHandler.lua')
end