--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
-- Client-side planting system for the drugs resource
-- Handles plant placement, interaction, and management

if Config.Debug then lib.print.info('[cl_planting] - Initializing planting system') end

-- Cache for grow zones and zone results for performance optimization
local growZones = {}
local cachedZoneResults = {}

-- Internal state tracking
local activeAnimations = {}
local activeParticles = {}
local activeProps = {}

-- Initialize grow zones from config
-- These are areas where plants can be grown with specific properties
for k, v in pairs(Config.Zones) do
    if v.points and #v.points > 0 then
        local coords = {}
        for _, point in ipairs(v.points) do
            if point.x and point.y and point.z then
                table.insert(coords, vector3(point.x, point.y, point.z))
            else
                if Config.Debug then lib.print.warn('[cl_planting] - Invalid point data in zone:', k, 'point:', point) end
            end
        end

        if #coords >= 3 then -- Minimum 3 points needed for a polygon
            growZones[k] = lib.zones.poly({
                points = coords,
                thickness = v.thickness or 4.0,
                debug = Config.DebugPoly,
            })
            if Config.Debug then lib.print.info('[cl_planting] - Created zone:', k, 'with', #coords, 'points') end
        else
            if Config.Debug then lib.print.error('[cl_planting] - Insufficient valid points for zone:', k, 'need at least 3, got:', #coords) end
        end
    else
        if Config.Debug then lib.print.error('[cl_planting] - No valid points found for zone:', k) end
    end
end

--- Apply custom animation data to the player
--- @param ped number Player ped ID
--- @param animationSettings table Table with animation settings
--- @return boolean animationApplied if animations were applied successfully
--- @return number|nil propObject prop entity ID if applicable
--- @return table|nil particles with loaded particles or nil if none
local function loadCustomAnimationData(ped, animationSettings)
    if Config.Debug then lib.print.info('[loadCustomAnimationData] - Processing animation settings for ped:', ped) end
    
    local animationApplied = false
    local createdObject = nil
    local particles = {}

    -- Validate input parameters
    if not ped or not DoesEntityExist(ped) then
        if Config.Debug then lib.print.error('[loadCustomAnimationData] - Invalid ped entity:', ped) end
        return false, nil, {}
    end

    if not animationSettings then
        if Config.Debug then lib.print.error('[loadCustomAnimationData] - No animation settings provided') end
        return false, nil, {}
    end

    -- Apply animations if available
    if animationSettings.animations and #animationSettings.animations > 0 then
        for _, animationData in pairs(animationSettings.animations) do
            if animationData.dict and animationData.anim then
                if Config.Debug then lib.print.debug('[loadCustomAnimationData] - Loading animation:', animationData.dict, animationData.anim) end
                
                lib.playAnim(
                    ped,
                    animationData.dict,
                    animationData.anim,
                    8.0,
                    8.0,
                    -1,
                    animationData.flag or 49,
                    0,
                    false,
                    0,
                    false
                )
                animationApplied = true
            else
                if Config.Debug then lib.print.warn('[loadCustomAnimationData] - Invalid animation data:', animationData) end
            end
        end
    end

    -- Attach model prop if defined
    if animationSettings.prop and animationSettings.prop.model then
        local coords = GetEntityCoords(ped)
        local propModel = animationSettings.prop.model
        
        if Config.Debug then lib.print.debug('[loadCustomAnimationData] - Creating prop:', propModel) end
        
        lib.requestModel(propModel)
        createdObject = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, true)
        
        if DoesEntityExist(createdObject) then
            AttachEntityToEntity(
                createdObject,
                ped,
                GetPedBoneIndex(ped, animationSettings.prop.boneId),
                animationSettings.prop.position.x,
                animationSettings.prop.position.y,
                animationSettings.prop.position.z,
                animationSettings.prop.rotation.x,
                animationSettings.prop.rotation.y,
                animationSettings.prop.rotation.z,
                true, true, false, true, 1, true
            )
            SetModelAsNoLongerNeeded(propModel)
            
            if Config.Debug then lib.print.debug('[loadCustomAnimationData] - Prop created and attached successfully') end
        else
            if Config.Debug then lib.print.error('[loadCustomAnimationData] - Failed to create prop object') end
            createdObject = nil
        end
    
        -- Attach particle effects if defined
        if animationSettings.particles and #animationSettings.particles > 0 and createdObject then
            for _, particleData in pairs(animationSettings.particles) do
                if particleData.asset and particleData.name then
                    if Config.Debug then lib.print.debug('[loadCustomAnimationData] - Loading particle effect:', particleData.name) end
                    
                    RequestNamedPtfxAsset(particleData.asset)
                    while not HasNamedPtfxAssetLoaded(particleData.asset) do
                        Wait(0)
                    end
                    
                    SetPtfxAssetNextCall(particleData.asset)
                    local effect = StartParticleFxLoopedOnEntity(
                        particleData.name,
                        createdObject,
                        particleData.offset.x or 0.0, particleData.offset.y or 0.0,  particleData.offset.z or 0.0,
                        particleData.rotation.x or 0.0,particleData.rotation.y or 0.0, particleData.rotation.z or 0.0,
                        particleData.scale or 1.0,
                        false, false, false
                    )
                    
                    if effect then
                        table.insert(particles, effect)
                        if Config.Debug then lib.print.debug('[loadCustomAnimationData] - Particle effect started successfully') end
                    else
                        if Config.Debug then lib.print.error('[loadCustomAnimationData] - Failed to start particle effect:', particleData.name) end
                    end
                else
                    if Config.Debug then lib.print.warn('[loadCustomAnimationData] - Invalid particle data:', particleData) end
                end
            end
        end
    end
    
    if Config.Debug then
        lib.print.info('[loadCustomAnimationData] - Animation applied:', animationApplied, 'Prop created:', createdObject ~= nil, 'Particles loaded:', #particles)
    end

    return animationApplied, createdObject, particles
end

--- Get the ground material hash at a location
---@param coords vector3 Position to check
---@return integer Ground material hash
local GetGroundHash = function(coords)
    if Config.Debug then lib.print.debug('[GetGroundHash] - Checking ground at coordinates:', coords.x, coords.y, coords.z) end
    
    local shapeTestCapsule = StartShapeTestCapsule(
        coords.x, coords.y, coords.z + 4, 
        coords.x, coords.y, coords.z - 2.0, 
        2, 1, 0, 7
    )
    
    local _, _, _, _, groundHash = GetShapeTestResultEx(shapeTestCapsule)
    
    if Config.Debug then lib.print.debug('[GetGroundHash] - Found ground hash:', groundHash) end
    return groundHash
end

--- Check if coordinates are within a specified grow zone
---@param coords vector3 Position to check
---@param targetZones table Array of zone names to check
---@return string|nil Zone ID if found, nil otherwise
local function checkforZones(coords, targetZones)
    if not targetZones or #targetZones == 0 then 
        if Config.Debug then lib.print.debug('[checkforZones] - No target zones provided') end
        return nil 
    end
    
    -- Create cache key for performance
    local cacheKey = tostring(coords.x)..tostring(coords.y)..tostring(coords.z)
    
    -- Check cache for recent results (10 second cache)
    if cachedZoneResults[cacheKey] then
        if GetGameTimer() - cachedZoneResults[cacheKey].time < 10000 then
            if Config.Debug then lib.print.debug('[checkforZones] - Using cached result for:', cacheKey) end
            return cachedZoneResults[cacheKey].result
        end
    end
    
    -- Check if coords are in any target zone
    for _, targetZone in pairs(targetZones) do
        if growZones[targetZone] then
            if growZones[targetZone]:contains(vector3(coords.x, coords.y, coords.z)) then
                if Config.Debug then lib.print.info('[checkforZones] - Position is in zone:', targetZone) end
                cachedZoneResults[cacheKey] = {result = targetZone, time = GetGameTimer()}
                return targetZone
            end
        else
            if Config.Debug then lib.print.warn('[checkforZones] - Target zone not found:', targetZone) end
        end
    end
    
    if Config.Debug then lib.print.debug('[checkforZones] - Position is not in any target zone') end
    cachedZoneResults[cacheKey] = {result = nil, time = GetGameTimer()}
    return nil
end

--- Plant a new seed at the specified coordinates
---@param ped number Current player ped
---@param plantItem string Plant item name
---@param coords vector3 Plant coordinates
---@param metadata table|nil Plant metadata
function PlantSeed(ped, plantItem, coords, metadata)
    if Config.Debug then lib.print.info('[PlantSeed] - Attempting to plant:', plantItem, 'at coordinates:', coords.x, coords.y, coords.z) end

    -- Validate input parameters
    if not ped or not DoesEntityExist(ped) then
        if Config.Debug then lib.print.error('[PlantSeed] - Invalid ped entity:', ped) end
        ShowNotification(nil, _U('NOTIFICATION__INVALID__PLAYER'), "Error")
        return
    end

    if not plantItem or plantItem == "" then
        if Config.Debug then lib.print.error('[PlantSeed] - Invalid plant item:', plantItem) end
        ShowNotification(nil, _U('NOTIFICATION__INVALID__PLANT'), "Error")
        return
    end

    if not coords then
        if Config.Debug then lib.print.error('[PlantSeed] - Invalid coordinates provided') end
        ShowNotification(nil, _U('NOTIFICATION__INVALID__LOCATION'), "Error")
        return
    end

    local plantInfos = Config.Plants[plantItem]
    if not plantInfos then
        if Config.Debug then lib.print.error('[PlantSeed] - Unknown plant item:', plantItem) end
        ShowNotification(nil, _U('NOTIFICATION__INVALID__PLANT'), "Error")
        return
    end

    -- Check plant limits per player
    local ownedPlants = lib.callback.await('it-drugs:server:getPlantByOwner', false)
    if Config.Debug then lib.print.debug('[PlantSeed] - Player has:', (ownedPlants and #ownedPlants or 0), 'owned plants') end

    if ownedPlants ~= nil then
        local plantCount = 0
        for _, plant in pairs(ownedPlants) do
            if plant.seed == plantItem then
                plantCount = plantCount + 1
            end
        end

        if plantCount >= Config.PlayerPlantLimit then
            if Config.Debug then lib.print.warn('[PlantSeed] - Player has reached plant limit:', plantCount, '/', Config.PlayerPlantLimit) end
            ShowNotification(nil, _U('NOTIFICATION__MAX__PLANTS'), "Error")
            return
        end
    end

    -- Check for nearby plants to prevent overlapping
    local plants = lib.callback.await('it-drugs:server:getPlants', false)
    if Config.Debug then lib.print.debug('[PlantSeed] - Got:', (plants and #plants or 0), 'existing plants from server') end

    -- Validate minimum distance from other plants
    if plants ~= nil then
        for _, v in pairs(plants) do
            local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(v.coords.x, v.coords.y, v.coords.z))
            if distance <= Config.PlantDistance then
                if Config.Debug then lib.print.warn('[PlantSeed] - Too close to another plant, distance:', distance, 'minimum required:', Config.PlantDistance) end
                ShowNotification(nil, _U('NOTIFICATION__TO__NEAR'), "Error")
                return
            end
        end
    end

    -- Check if the ground is valid for planting
    if plantInfos.allowedGrounds and #plantInfos.allowedGrounds > 0 then
        local groundHash = GetGroundHash(coords)
        local canPlant = false
        if Config.Debug then lib.print.info('[PlantSeed] - Ground hash:', groundHash, 'checking against allowed grounds') end
        
        for _, allowedGround in pairs(plantInfos.allowedGrounds) do
            if groundHash == allowedGround then
                canPlant = true
                if Config.Debug then lib.print.debug('[PlantSeed] - Ground is allowed for this plant') end
                break
            end
        end

        if not canPlant then
            if Config.Debug then lib.print.warn('[PlantSeed] - Invalid ground type for this plant') end
            ShowNotification(nil, _U('NOTIFICATION__CANT__PLACE'), "Error")
            return
        end
    elseif Config.OnlyAllowedGrounds and #Config.AllowedGrounds > 1 then
        local groundHash = GetGroundHash(coords)
        local canplant = false
        if Config.Debug then lib.print.info('[PlantSeed] - Ground hash:', groundHash, 'checking against global allowed grounds') end
        
        for _, ground in pairs(Config.AllowedGrounds) do
            if groundHash == ground then
                canplant = true
                if Config.Debug then lib.print.debug('[PlantSeed] - Ground is globally allowed for planting') end
                break
            end
        end

        if not canplant then
            if Config.Debug then lib.print.warn('[PlantSeed] - Invalid ground type for planting') end
            ShowNotification(nil, _U('NOTIFICATION__CANT__PLACE'), "Error")
            return
        end
    end

    -- Check if the location is in a valid grow zone
    local zone = checkforZones(coords, plantInfos.zones)
    if Config.Debug then lib.print.info('[PlantSeed] - Current zone:', (zone or "none")) end
    
    if plantInfos.onlyZone and zone == nil then
        if Config.Debug then lib.print.warn('[PlantSeed] - This plant requires a specific grow zone') end
        ShowNotification(nil, _U('NOTIFICATION__CANT__PLACE'), "Error")
        return
    end

    -- Verify required items for planting
    if plantInfos.reqItems and plantInfos.reqItems["planting"] ~= nil then
        for item, itemData in pairs(plantInfos.reqItems["planting"]) do
            if Config.Debug then lib.print.debug('[PlantSeed] - Checking for required item:', item, 'amount:', (itemData.amount or 1)) end
            if not exports.it_bridge:HasItem(item, itemData.amount or 1) then
                if Config.Debug then lib.print.warn('[PlantSeed] - Missing required item:', item) end
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")
                TriggerEvent('it-drugs:client:syncRestLoop', false)
                return
            end
        end
    end

    -- Load animation dictionaries
    if Config.Debug then lib.print.debug('[PlantSeed] - Starting planting animations') end

    local animationApplied = false
    local loadedParticles = nil
    local currentObject = nil
    
    -- Load custom animations if defined in the plant configuration
    if plantInfos.animationSettings then
        animationApplied, currentObject, loadedParticles = loadCustomAnimationData(ped, plantInfos.animationSettings)
        if not animationApplied then
            if Config.Debug then lib.print.debug('[PlantSeed] - Custom animations failed, using default animations') end
            lib.playAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, 0, false)
            lib.playAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, 0, false)
        end
    else
        -- Load default animations
        if Config.Debug then lib.print.debug('[PlantSeed] - Using default planting animations') end
        lib.playAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, 0, false)
        lib.playAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, 0, false)
    end
    
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
        if Config.Debug then lib.print.info('[PlantSeed] - Planting successful, creating on server') end
        TriggerServerEvent('it-drugs:server:createNewPlant', coords, plantItem, zone, metadata)
    else
        if Config.Debug then lib.print.info('[PlantSeed] - Planting cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
    end

    -- Cleanup
    ClearPedTasks(ped)

    if currentObject then
        if Config.Debug then lib.print.debug('[PlantSeed] - Cleaning up created object') end
        DeleteEntity(currentObject)
    end
    
    -- Stop any loaded particle effects
    if loadedParticles then
        if Config.Debug then lib.print.debug('[PlantSeed] - Cleaning up particle effects:', #loadedParticles) end
        for _, effect in pairs(loadedParticles) do
            StopParticleFxLooped(effect, false)
        end
    end
    
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end

--- Handle harvesting a plant
RegisterNetEvent('it-drugs:client:harvestPlant', function(args)
    if Config.Debug then lib.print.info('[harvestPlant] - Attempting to harvest plant') end
    
    -- Validate input parameters
    if not args or not args.plantData then
        if Config.Debug then lib.print.error('[harvestPlant] - Invalid arguments provided') end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    local plantData = args.plantData
    local clientData = GetPlantData(plantData.id)
    
    if not clientData or not clientData.entity then
        if Config.Debug then lib.print.error('[harvestPlant] - Plant entity not found for ID:', plantData.id) end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    local entity = clientData.entity

    -- Check for required harvesting items
    plantData.reqItems = Config.Plants[plantData.seed].reqItems
    if plantData.reqItems and plantData.reqItems["harvesting"] ~= nil then
        for item, itemData in pairs(plantData.reqItems["harvesting"]) do
            if Config.Debug then lib.print.debug('[harvestPlant] - Checking for required item:', item, 'amount:', (itemData.amount or 1)) end
            if not exports.it_bridge:HasItem(item, itemData.amount or 1) then
                if Config.Debug then lib.print.warn('[harvestPlant] - Missing required item:', item) end
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")
                TriggerEvent('it-drugs:client:syncRestLoop', false)
                return
            end
        end
    end

    -- Position player to face the plant
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        if Config.Debug then lib.print.error('[harvestPlant] - Invalid player ped') end
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)

    -- Load animation dictionaries
    if Config.Debug then lib.print.debug('[harvestPlant] - Loading animations') end
    local animationApplied = false
    local loadedParticles = nil
    local currentObject = nil
    
    -- Load custom animations if defined in the plant configuration
    if plantData.animationSettings then
        animationApplied, currentObject, loadedParticles = loadCustomAnimationData(ped, plantData.animationSettings)
        if not animationApplied then
            if Config.Debug then lib.print.debug('[harvestPlant] - Custom animations failed, using default animations') end
            lib.playAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, 0, false)
            lib.playAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, 0, false)
        end
    else
        -- Load default animations
        if Config.Debug then lib.print.debug('[harvestPlant] - Using default harvesting animations') end
        lib.playAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, 0, false)
        lib.playAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, 0, false)
    end

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
        if Config.Debug then lib.print.info('[harvestPlant] - Harvest successful for plant ID:', plantData.id) end
        TriggerServerEvent('it-drugs:server:harvestPlant', plantData.id)
    else
        if Config.Debug then lib.print.info('[harvestPlant] - Harvest cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
    end

    -- Cleanup
    if currentObject then
        if Config.Debug then lib.print.debug('[harvestPlant] - Cleaning up created object') end
        DeleteEntity(currentObject)
    end
    if loadedParticles then
        if Config.Debug then lib.print.debug('[harvestPlant] - Cleaning up particle effects:', #loadedParticles) end
        for _, effect in pairs(loadedParticles) do
            StopParticleFxLooped(effect, false)
        end
    end
    ClearPedTasks(ped)
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end)

--- Apply water to a plant
---@param args table Contains plant data and item used
local giveWater = function(args)
    if Config.Debug then lib.print.info('[giveWater] - Starting water application') end
    
    -- Validate input parameters
    if not args or not args.item or not args.plantData then
        if Config.Debug then lib.print.error('[giveWater] - Invalid arguments provided') end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        return
    end
    
    local item = args.item
    local plantData = args.plantData

    local itemData = Config.Items[item]
    if not itemData or itemData.water == 0 then
        if Config.Debug then lib.print.error('[giveWater] - Invalid item for watering:', item) end
        ShowNotification(nil, _U('NOTIFICATION__INVALID__ITEM'), "Error")
        return
    end
    
    if Config.Debug then lib.print.info('[giveWater] - Applying water to plant ID:', plantData.id, 'with item:', item) end
    
    local clientData = GetPlantData(plantData.id)
    if not clientData or not clientData.entity then
        if Config.Debug then lib.print.error('[giveWater] - Plant entity not found for ID:', plantData.id) end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        return
    end
    
    local entity = clientData.entity

    -- Position player and prepare props
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        if Config.Debug then lib.print.error('[giveWater] - Invalid player ped') end
        return
    end
    
    local coords = GetEntityCoords(ped)
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)

    local animationApplied = false
    local loadedParticles = nil
    local currentObject = nil
    
    -- Load custom animations if defined in the plant configuration
    if itemData.animationSettings then
        animationApplied, currentObject, loadedParticles = loadCustomAnimationData(ped, itemData.animationSettings)
        if not animationApplied then
            if Config.Debug then lib.print.debug('[giveWater] - Custom animations failed, using default animations') end
            lib.playAnim(ped, 'weapon@w_sp_jerrycan', 'fire', 8.0, 8.0, -1, 1, 0, false, 0, false)
        end
    else
        -- Load default animations
        if Config.Debug then lib.print.debug('[giveWater] - Using default watering animations') end
        
        local model = 'prop_wateringcan'
        lib.requestModel(model)
        RequestNamedPtfxAsset('core')
        while not HasNamedPtfxAssetLoaded('core') do Wait(0) end
    
        -- Create watering can prop and attach to player
        SetPtfxAssetNextCall('core')
        currentObject = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        
        if DoesEntityExist(currentObject) then
            AttachEntityToEntity(currentObject, ped, GetPedBoneIndex(ped, 28422), 0.4, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
            
            -- Start water particle effect
            local effect = StartParticleFxLoopedOnEntity('ent_sht_water', currentObject, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)
            if effect then
                loadedParticles = loadedParticles or {}
                table.insert(loadedParticles, effect)
                if Config.Debug then lib.print.debug('[giveWater] - Water particle effect started') end
            else
                if Config.Debug then lib.print.warn('[giveWater] - Failed to start water particle effect') end
            end
        else
            if Config.Debug then lib.print.error('[giveWater] - Failed to create watering can object') end
        end
        
        lib.playAnim(ped, 'weapon@w_sp_jerrycan', 'fire', 8.0, 8.0, -1, 1, 0, false, 0, false)
    end

    -- Show progress bar and process if successful
    if ShowProgressBar({
        duration = Config.Plants[plantData.seed].time,
        label = _U('PROGRESSBAR__SOAK__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true,
        },
    }) then
        if Config.Debug then lib.print.info('[giveWater] - Successfully watered plant ID:', plantData.id) end
        TriggerServerEvent('it-drugs:server:plantTakeCare', plantData.id, item)
    else
        if Config.Debug then lib.print.info('[giveWater] - Watering cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
    end

    -- Cleanup
    if currentObject then
        if Config.Debug then lib.print.debug('[giveWater] - Cleaning up created object') end
        DeleteEntity(currentObject)
    end
    if loadedParticles and #loadedParticles > 0 then
        if Config.Debug then lib.print.debug('[giveWater] - Cleaning up particle effects:', #loadedParticles) end
        for _, effect in pairs(loadedParticles) do
            StopParticleFxLooped(effect, false)
        end
    end
    ClearPedTasks(ped)
end

--- Apply fertilizer to a plant
---@param args table Contains plant data and item used
local giveFertilizer = function(args)
    if Config.Debug then lib.print.info('[giveFertilizer] - Starting fertilizer application') end
    
    -- Validate input parameters
    if not args or not args.item or not args.plantData then
        if Config.Debug then lib.print.error('[giveFertilizer] - Invalid arguments provided') end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        return
    end
    
    local item = args.item
    local plantData = args.plantData

    local itemData = Config.Items[item]
    if not itemData or itemData.fertilizer == 0 then
        if Config.Debug then lib.print.error('[giveFertilizer] - Invalid item for fertilizing:', item) end
        ShowNotification(nil, _U('NOTIFICATION__INVALID__ITEM'), "Error")
        return
    end
    
    if Config.Debug then lib.print.info('[giveFertilizer] - Applying fertilizer to plant ID:', plantData.id, 'with item:', item) end
    
    local clientData = GetPlantData(plantData.id)
    if not clientData or not clientData.entity then
        if Config.Debug then lib.print.error('[giveFertilizer] - Plant entity not found for ID:', plantData.id) end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        return
    end
    
    local entity = clientData.entity

    -- Position player and prepare props
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        if Config.Debug then lib.print.error('[giveFertilizer] - Invalid player ped') end
        return
    end
    
    local coords = GetEntityCoords(ped)
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)

    local animationApplied = false
    local loadedParticles = nil
    local currentObject = nil
    
    -- Load custom animations if defined in the plant configuration
    if itemData.animationSettings then
        animationApplied, currentObject, loadedParticles = loadCustomAnimationData(ped, itemData.animationSettings)
        if not animationApplied then
            if Config.Debug then lib.print.debug('[giveFertilizer] - Custom animations failed, using default animations') end
            lib.playAnim(ped, 'weapon@w_sp_jerrycan', 'fire', 8.0, 8.0, -1, 1, 0, false, 0, false)
        end
    else
        -- Load default animations
        if Config.Debug then lib.print.debug('[giveFertilizer] - Using default fertilizer animations') end

        local model = 'w_am_jerrycan_sf'
        lib.requestModel(model)
        RequestNamedPtfxAsset('core')
        while not HasNamedPtfxAssetLoaded('core') do Wait(0) end
    
        -- Create fertilizer can prop and attach to player
        SetPtfxAssetNextCall('core')
        currentObject = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        
        if DoesEntityExist(currentObject) then
            AttachEntityToEntity(currentObject, ped, GetPedBoneIndex(ped, 28422), 0.4, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
            
            -- Start fertilizer particle effect
            local effect = StartParticleFxLoopedOnEntity('ent_sht_water', currentObject, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)
            if effect then
                loadedParticles = loadedParticles or {}
                table.insert(loadedParticles, effect)
                if Config.Debug then lib.print.debug('[giveFertilizer] - Fertilizer particle effect started') end
            else
                if Config.Debug then lib.print.warn('[giveFertilizer] - Failed to start fertilizer particle effect') end
            end
        else
            if Config.Debug then lib.print.error('[giveFertilizer] - Failed to create fertilizer can object') end
        end
        
        lib.playAnim(ped, 'weapon@w_sp_jerrycan', 'fire', 8.0, 8.0, -1, 1, 0, false, 0, false)
    end

    -- Show progress bar and process if successful
    if ShowProgressBar({
        duration = Config.Plants[plantData.seed].time,
        label = _U('PROGRESSBAR__FERTILIZE__PLANT'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true,
        },
    }) then
        if Config.Debug then lib.print.info('[giveFertilizer] - Successfully fertilized plant ID:', plantData.id) end
        TriggerServerEvent('it-drugs:server:plantTakeCare', plantData.id, item)
    else
        if Config.Debug then lib.print.info('[giveFertilizer] - Fertilizing cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
    end
    
    -- Cleanup
    if currentObject then
        if Config.Debug then lib.print.debug('[giveFertilizer] - Cleaning up created object') end
        DeleteEntity(currentObject)
    end
    if loadedParticles and #loadedParticles > 0 then
        if Config.Debug then lib.print.debug('[giveFertilizer] - Cleaning up particle effects:', #loadedParticles) end
        for _, effect in pairs(loadedParticles) do
            StopParticleFxLooped(effect, false)
        end
    end
    ClearPedTasks(ped)
end

--- Handle using items on plants (water or fertilizer)
RegisterNetEvent('it-drugs:client:useItem', function (args)
    if Config.Debug then lib.print.info('[useItem] - Starting item usage on plant') end
    
    -- Validate input parameters
    if not args or not args.item or not args.plantData then
        if Config.Debug then lib.print.error('[useItem] - Invalid arguments provided') end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    local item = args.item
    
    if Config.Debug then lib.print.info('[useItem] - Using item:', item, 'on plant ID:', args.plantData.id) end

    -- Check if player has the item
    if not exports.it_bridge:HasItem(item, 1) then
        if Config.Debug then lib.print.warn('[useItem] - Player does not have item:', item) end
        ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end

    -- Determine item type and apply appropriate function
    local itemInfos = Config.Items[item]
    if not itemInfos then
        if Config.Debug then lib.print.error('[useItem] - Invalid item configuration:', item) end
        ShowNotification(nil, _U('NOTIFICATION__INVALID__ITEM'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    if itemInfos.water and itemInfos.water ~= 0 then
        if Config.Debug then lib.print.debug('[useItem] - Item is a water item') end
        giveWater(args)
    elseif itemInfos.fertilizer and itemInfos.fertilizer ~= 0 then
        if Config.Debug then lib.print.debug('[useItem] - Item is a fertilizer item') end
        giveFertilizer(args)
    else
        if Config.Debug then lib.print.warn('[useItem] - Item is neither water nor fertilizer:', item) end
        ShowNotification(nil, _U('NOTIFICATION__INVALID__ITEM'), "Error")
    end
    
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end)

--- Handle destroying a plant
RegisterNetEvent('it-drugs:client:destroyPlant', function(args)
    if Config.Debug then lib.print.info('[destroyPlant] - Attempting to destroy plant') end
    
    -- Validate input parameters
    if not args or not args.plantData then
        if Config.Debug then lib.print.error('[destroyPlant] - Invalid arguments provided') end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    -- Check for required destroy item if configured
    if Config.ItemToDestroyPlant and not exports.it_bridge:HasItem(Config.DestroyItemName, 1) then
        if Config.Debug then lib.print.warn('[destroyPlant] - Missing required item to destroy:', Config.DestroyItemName) end
        ShowNotification(nil, _U('NOTIFICATION__NEED_LIGHTER'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    local plantData = args.plantData
    local type = plantData.seed
    local plantInfos = Config.Plants[type]
    
    if not plantInfos then
        if Config.Debug then lib.print.error('[destroyPlant] - Invalid plant type:', type) end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end

    local clientData = GetPlantData(plantData.id)
    if not clientData or not clientData.entity then
        if Config.Debug then lib.print.error('[destroyPlant] - Plant entity not found for ID:', plantData.id) end
        ShowNotification(nil, _U('NOTIFICATION__ERROR'), "Error")
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    local entity = clientData.entity

    -- Position player to face the plant
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        if Config.Debug then lib.print.error('[destroyPlant] - Invalid player ped') end
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end
    
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(200)

    local animationApplied = false
    local loadedParticles = nil
    local currentObject = nil
    
    -- Load custom animations if defined in the plant configuration
    if plantInfos.animationSettings then
        animationApplied, currentObject, loadedParticles = loadCustomAnimationData(ped, plantInfos.animationSettings)
        if not animationApplied then
            if Config.Debug then lib.print.debug('[destroyPlant] - Custom animations failed, using default animations') end
            lib.playAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, 0, false)
            lib.playAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, 0, false)
        end
    else
        -- Load default animations
        if Config.Debug then lib.print.debug('[destroyPlant] - Using default destruction animations') end
        lib.playAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, 0, false)
        lib.playAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 49, 0, false, 0, false)
    end

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
        if Config.Debug then lib.print.info('[destroyPlant] - Successfully destroyed plant ID:', plantData.id) end
        TriggerServerEvent('it-drugs:server:destroyPlant', {plantId = plantData.id})
    else
        if Config.Debug then lib.print.info('[destroyPlant] - Destruction cancelled by user') end
        ShowNotification(nil, _U('NOTIFICATION__CANCELED'), "Error")
    end

    -- Cleanup
    if currentObject then
        if Config.Debug then lib.print.debug('[destroyPlant] - Cleaning up created object') end
        DeleteEntity(currentObject)
    end
    if loadedParticles and #loadedParticles > 0 then
        if Config.Debug then lib.print.debug('[destroyPlant] - Cleaning up particle effects:', #loadedParticles) end
        for _, effect in pairs(loadedParticles) do
            StopParticleFxLooped(effect, false)
        end
    end
    ClearPedTasks(ped)
    
    TriggerEvent('it-drugs:client:syncRestLoop', false)
end)

--- Create fire effect for destroyed plants
RegisterNetEvent('it-drugs:client:startPlantFire', function(coords)
    if Config.Debug then lib.print.info('[startPlantFire] - Creating fire effect at coordinates:', coords.x, coords.y, coords.z) end
    
    -- Validate input parameters
    if not coords or type(coords) ~= "table" then
        if Config.Debug then lib.print.error('[startPlantFire] - Invalid coordinates provided') end
        return
    end
    
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    
    -- Only show fire if player is within range (performance optimization)
    local distance = #(pedCoords - vector3(coords.x, coords.y, coords.z))
    if distance > 300 then 
        if Config.Debug then lib.print.debug('[startPlantFire] - Player too far from fire location, distance:', distance) end
        return 
    end

    -- Load fire particle effect
    RequestNamedPtfxAsset('core')
    local timeout = 0
    while not HasNamedPtfxAssetLoaded('core') and timeout < 5000 do 
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasNamedPtfxAssetLoaded('core') then
        if Config.Debug then lib.print.error('[startPlantFire] - Failed to load particle asset within timeout') end
        return
    end
    
    -- Start the fire effect
    SetPtfxAssetNextCall('core')
    local effect = StartParticleFxLoopedAtCoord('ent_ray_paleto_gas_flames', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.6, false, false, false, false)
    
    if effect then
        if Config.Debug then lib.print.debug('[startPlantFire] - Fire effect created successfully, will burn for:', Config.FireTime, 'ms') end
        
        -- Burn for configured duration then stop
        Wait(Config.FireTime)
        
        StopParticleFxLooped(effect, false)
        if Config.Debug then lib.print.debug('[startPlantFire] - Fire effect stopped after duration') end
    else
        if Config.Debug then lib.print.error('[startPlantFire] - Failed to create fire particle effect') end
    end
end)
