--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
if exports.it_bridge:GetServerInteraction() then return end
local serverFramework = exports.it_bridge:GetServerFramework()
if Config.Debug then lib.print.info('[cl_noTarget] - Initialized with framework:', serverFramework) end

local updateLoopStarted = false

local serverPlants = {}
local serverTables = {}
local serverDealers = {}
local lastCoordinates = nil
local checkFrequency = Config.CheckFrequency -- Configurable check frequency
local restLoop = false

--- Get the closest plant to the given coords
---@param coords vector3: The coords to check from
---@return table | nil, integer: The closest plant and the distance to it
local function getClosestPlant(coords)
    if Config.Debug then lib.print.info('[getClosestPlant] - Finding closest plant to player coords') end
    
    local closestPlant = nil
    local closestDistance = 20

    for plantId, plantData in pairs(serverPlants) do
        if plantData and plantData.coords then
            local distance = #(coords - plantData.coords)
            if distance < closestDistance then
                closestDistance = distance
                closestPlant = plantData
            end
        end
    end

    return closestPlant, closestDistance
end

local function getClosestProcessingTable(coords)
    if Config.Debug then lib.print.info('[getClosestProcessingTable] - Finding closest table to player coords') end
    
    local closestTable = nil
    local closestDistance = 20

    for tableId, tableData in pairs(serverTables) do
        if tableData and tableData.coords then
            local distance = #(coords - tableData.coords)
            if distance < closestDistance then
                closestDistance = distance
                closestTable = tableData
            end
        end
    end

    return closestTable, closestDistance
end

local function getClosestDealer(coords)
    if Config.Debug then lib.print.info('[getClosestDealer] - Finding closest dealer to player coords') end
    
    local closestDealer = nil
    local closestDistance = 20

    for dealerId, dealerData in pairs(serverDealers) do
        if dealerData and dealerData.position then
            local vec3 = vector3(dealerData.position.x, dealerData.position.y, dealerData.position.z)
            local distance = #(coords - vec3)
            if distance < closestDistance then
                closestDistance = distance
                closestDealer = dealerData
            end
        end
    end

    return closestDealer, closestDistance
end

-- Process the entities in view based on player position
local function processEntitiesInView()
    if Config.Debug then lib.print.info('[processEntitiesInView] - Processing entities in view') end
    
    -- Only update if the player has moved significantly
    local currentPlayerCoords = GetEntityCoords(PlayerPedId())
    local playerHasMoved = not lastCoordinates or #(currentPlayerCoords - lastCoordinates) > 10
    
    if not playerHasMoved then
        if Config.Debug then lib.print.info('[processEntitiesInView] - Player has not moved significantly, skipping update') end
        return
    end
    
    if Config.Debug then lib.print.info('[processEntitiesInView] - Player moved from previous position') end
    lastCoordinates = currentPlayerCoords
end

-- Event handlers
RegisterNetEvent('it-drugs:client:syncRestLoop', function(status)
    if Config.Debug then lib.print.info('[syncRestLoop] - Updating rest loop status:', status) end
    restLoop = status
end)

AddEventHandler('it-drugs:client:syncPlants', function(plants)
    if not plants then
        if Config.Debug then lib.print.error('[syncPlants] - No plants received from server') end
        return
    end
    
    if Config.Debug then lib.print.info('[syncPlants] - Syncing plants from server') end
    serverPlants = plants
    
    if not updateLoopStarted then
        UpdateLoop()
    end
end)

AddEventHandler('it-drugs:client:syncTables', function(tables)
    if not tables then
        if Config.Debug then lib.print.error('[syncTables] - No tables received from server') end
        return
    end
    
    if Config.Debug then lib.print.info('[syncTables] - Syncing tables from server') end
    serverTables = tables
    
    if not updateLoopStarted then
        UpdateLoop()
    end
end)

function UpdateLoop()
    updateLoopStarted = true
    if Config.Debug then lib.print.info('[UpdateLoop] - Running update loop') end
    
    -- Skip if rest loop is active
    if restLoop then
        if Config.Debug then lib.print.info('[UpdateLoop] - Rest loop active, skipping update') end
        SetTimeout(checkFrequency, UpdateLoop)
        return
    end
    
    -- Check for entities in view
    processEntitiesInView()
    
    local coords = GetEntityCoords(PlayerPedId())
    local closestPlant, plantDistance = getClosestPlant(coords)
    local closestTable, tableDistance = getClosestProcessingTable(coords)
    local closestDealer, dealerDistance = getClosestDealer(coords)
    
    -- Process interactions based on closest entity
    if closestDealer and dealerDistance <= 2.0 then
        DrawText3D(closestDealer.position.x, closestDealer.position.y, closestDealer.position.z + 0.5, _U('3DTEXT__DEALER__LABLE'))
        if IsControlJustPressed(0, 38) then
            TriggerEvent('it-drugs:client:showDealerActionMenu', closestDealer.id)
        end
    else
        if plantDistance > tableDistance then
            if closestTable and tableDistance <= 2.0 then
                DrawText3D(closestTable.coords.x, closestTable.coords.y, closestTable.coords.z + 0.5, _U('3DTEXT__TABLE__LABLE'))
                if IsControlJustPressed(0, 38) then
                    TriggerEvent('it-drugs:client:showRecipesMenu', {tableId = closestTable.id})
                end
            end
        elseif closestPlant and plantDistance <= 2.0 then
            DrawText3D(closestPlant.coords.x, closestPlant.coords.y, closestPlant.coords.z + 0.5, _U('3DTEXT__PLANT__LABLE'))
            if IsControlJustPressed(0, 38) then
                TriggerEvent('it-drugs:client:showPlantMenu', closestPlant)
            end
        end
    end
    
    -- Adaptive timing: check less frequently when not moving
    local currentCoords = GetEntityCoords(PlayerPedId())
    local stationary = lastCoordinates and #(currentCoords - lastCoordinates) < 0.5
    local interval = 0 -- More responsive intervals for interaction UI
    
    if Config.Debug then 
        lib.print.info('[UpdateLoop] - Next update in', interval, 'ms')
    end
    
    SetTimeout(interval, UpdateLoop)
end

-- Request data from server
local function requestAllDataFromServer()
    if Config.Debug then lib.print.info('[requestAllDataFromServer] - Requesting all data from server') end
    
    -- Get all entities from server
    serverPlants = lib.callback.await('it-drugs:server:getPlants', false)
    serverTables = lib.callback.await('it-drugs:server:getTables', false)
    serverDealers = lib.callback.await('it-drugs:server:getDealers', false)
    
    if Config.Debug then 
        local plantCount = 0
        local tableCount = 0
        local dealerCount = 0
        
        for _ in pairs(serverPlants) do plantCount = plantCount + 1 end
        for _ in pairs(serverTables) do tableCount = tableCount + 1 end
        for _ in pairs(serverDealers) do dealerCount = dealerCount + 1 end
        
        lib.print.info('[requestAllDataFromServer] - Retrieved', plantCount, 'plants from server')
        lib.print.info('[requestAllDataFromServer] - Retrieved', tableCount, 'tables from server')
        lib.print.info('[requestAllDataFromServer] - Retrieved', dealerCount, 'dealers from server')
    end
    
    -- Initialize the position and start the update loop
    lastCoordinates = GetEntityCoords(PlayerPedId())
    if not updateLoopStarted then
        UpdateLoop()
    end
end

-- Get handler data for exports
function GetNoTargetPlantData(plantId)
    return serverPlants[plantId]
end

function GetNoTargetTableData(tableId)
    return serverTables[tableId]
end

function GetNoTargetDealerData(dealerId)
    return serverDealers[dealerId]
end

-- Initialize no target handler
local function initializeNoTargetHandler()
    Wait(2000) -- Wait a bit before requesting data
    requestAllDataFromServer()
end

-- Framework-specific initialization
if serverFramework == 'es_extended' then
    AddEventHandler('esx:playerLoaded', function(_, _, _)
        if Config.Debug then lib.print.info('[cl_noTarget] - ESX player loaded event triggered') end
        initializeNoTargetHandler()
    end)
elseif serverFramework == 'qb-core' or serverFramework == 'qbx_core' then
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        if Config.Debug then lib.print.info('[cl_noTarget] - QBCore player loaded event triggered') end
        initializeNoTargetHandler()
    end)
elseif serverFramework == 'ND_Core' then
    AddEventHandler("ND:characterLoaded", function()
        if Config.Debug then lib.print.info('[cl_noTarget] - ND player loaded event triggered') end
        initializeNoTargetHandler()
    end)
else
    if Config.Debug then lib.print.error('[cl_noTarget] - Unknown framework:', serverFramework) end
    lib.print.error('[cl_noTarget] Unable to load player please check cl_notarget.lua')
end
