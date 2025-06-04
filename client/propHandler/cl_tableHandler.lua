--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
local serverFramework = exports.it_bridge:GetServerFramework()
local serverInteraction = exports.it_bridge:GetServerInteraction()
if Config.Debug then lib.print.info('[cl_tableHandler] - Initialized with framework:', serverFramework) end

local updateLoopStarted = false

local serverTables = {}
local spawnedTables = {}
local lastCoordinates = nil
local checkFrequency = Config.CheckFrequency -- Configurable check frequency

-- Improved model loading with timeout
local function loadModel(hash)
    if Config.Debug then lib.print.info('[loadModel] - Loading model hash:', hash) end
    local timeout = 500
    lib.requestModel(hash, timeout)
    if Config.Debug then lib.print.info('[loadModel] - Model loaded successfully:', hash) end
    return hash
end

local function generateTableTargetData(tableData, tableModel, entity)
    if Config.Debug then lib.print.info('[generateTableTargetData] - Generating target data for table:', tableData.id) end

    local minSize, maxSize = GetModelDimensions(tableModel)
    local size = vector3(maxSize.x - minSize.x, maxSize.y - minSize.y, maxSize.z - minSize.z)

    local tableCoords = GetEntityCoords(entity)
    local tableRotation = GetEntityHeading(entity)    if exports.it_bridge:GetServerInteraction() == 'qb-target' then
        tableRotation = tableRotation + 90.0
    end
    
    local targetData = {
        id = tableData.id,
        coords = vector3(tableCoords.x, tableCoords.y, tableCoords.z),
        size = size,
        rotation = tableRotation,
        drawSprite = true,
        interactDistance = 1.5,
        minZ = tableCoords.z - 0.5,
        maxZ = tableCoords.z + (size.z / 2),
        debug = Config.Debug,
    }

    local target = CreateTableBoxTarget(targetData)
    return target
end

local function spawnTable(tableId)
    if Config.Debug then lib.print.info('[spawnTable] - Try to spawning table with ID:', tableId) end

    -- Don't respawn already spawned tables
    if spawnedTables[tableId] then
        if Config.Debug then lib.print.info('[spawnTable] - Table already spawned, skipping:', tableId) end
        return
    end

    local tableData = serverTables[tableId]
    if not tableData then
        if Config.Debug then lib.print.error('[spawnTable] - Table with ID:', tableId, 'not found in serverTables') end
        return
    end

    local modelHash = Config.ProcessingTables[tableData.tableType].model
    modelHash = loadModel(modelHash)

    local tableEntity = CreateObject(modelHash, tableData.coords.x, tableData.coords.y, tableData.coords.z, false, false, false)
    SetEntityHeading(tableEntity, tableData.rotation)
    FreezeEntityPosition(tableEntity, true)

    local tableTarget = nil
    if serverInteraction ~= nil then
        tableTarget = generateTableTargetData(tableData, modelHash, tableEntity)
    end

    spawnedTables[tableId] = {
        entity = tableEntity,
        coords = tableData.coords,
        modelHash = modelHash,
        target = tableTarget,
    }

    if Config.Debug then lib.print.info('[spawnTable] - Table with ID:', tableId, 'spawned successfully') end
    SetModelAsNoLongerNeeded(modelHash)
end

local function deleteTable(tableId)
    if Config.Debug then lib.print.info('[deleteTable] - Deleting table with ID:', tableId) end

    local tableData = spawnedTables[tableId]
    if not tableData then
        if Config.Debug then lib.print.error('[deleteTable] - Table with ID:', tableId, 'not found in spawnedTables') end
        return
    end

    if DoesEntityExist(tableData.entity) then
        DeleteObject(tableData.entity)
        
        if tableData.target then
            exports.it_bridge:RemoveBoxZone(tableData.target)
        end
        if Config.Debug then lib.print.info('[deleteTable] - Table entity deleted successfully') end
    else
        if Config.Debug then lib.print.warn('[deleteTable] - Table entity does not exist, skipping deletion') end
    end

    spawnedTables[tableId] = nil
    if Config.Debug then lib.print.info('[deleteTable] - Table with ID:', tableId, 'deleted successfully') end
end

local function processTableInView()
    if Config.Debug then lib.print.info('[processTableInView] - Processing tables in view') end
    local currentPlayerCoords = GetEntityCoords(PlayerPedId())
    local playerHasMoved = not lastCoordinates or #(currentPlayerCoords - lastCoordinates) > 10

    if not playerHasMoved then
        if Config.Debug then lib.print.info('[processTableInView] - Player has not moved significantly, skipping update') end
        return
    end

    if Config.Debug then lib.print.info('[processTableInView] - Player moved from previous position, distance:', not lastCoordinates and "n/a" or #(currentPlayerCoords - lastCoordinates)) end
    lastCoordinates = currentPlayerCoords

    local tableToSpawn = {}
    local tablesToDelete = {}
    local tableCount = 0

    for tableId, tableData in pairs(serverTables) do
        tableCount = tableCount + 1
        if tableData and tableData.coords then
            local distance = #(currentPlayerCoords - vector3(tableData.coords.x, tableData.coords.y, tableData.coords.z))
            
            if distance <= Config.MinPropDistance and not spawnedTables[tableId] then
                tableToSpawn[tableId] = true
            elseif distance > Config.MinPropDistance and spawnedTables[tableId] then
                tablesToDelete[tableId] = true
            end
        end
    end    local spawnCount = 0
    local deleteCount = 0
    for _ in pairs(tableToSpawn) do spawnCount = spawnCount + 1 end
    for _ in pairs(tablesToDelete) do deleteCount = deleteCount + 1 end
    
    if Config.Debug then 
        lib.print.info('[processTableInView] - Total tables:', tableCount)
        lib.print.info('[processTableInView] - Tables to spawn:', spawnCount)
        lib.print.info('[processTableInView] - Tables to delete:', deleteCount)
    end

    for tableId in pairs(tableToSpawn) do
        spawnTable(tableId)
    end

    for tableId in pairs(tablesToDelete) do
        deleteTable(tableId)
    end

    if Config.Debug then
        local currentSpawned = 0
        for _ in pairs(spawnedTables) do currentSpawned = currentSpawned + 1 end
        lib.print.info('[processTableInView] - Current spawned tables count:', currentSpawned)
    end
end

function TableUpdateLoop()
    updateLoopStarted = true
    if Config.Debug then lib.print.info('[TableUpdateLoop] - Running update loop') end
    processTableInView()
    
    -- Adaptive timing: check less frequently when not moving
    local currentCoords = GetEntityCoords(PlayerPedId())    
    local stationary = lastCoordinates and #(currentCoords - lastCoordinates) < 0.5
    local interval = stationary and 8000 or checkFrequency
    
    if Config.Debug then
        lib.print.info('[TableUpdateLoop] - Player stationary:', stationary)
        lib.print.info('[TableUpdateLoop] - Next update in', interval, 'ms')
    end
    
    SetTimeout(interval, TableUpdateLoop)
end

local function requestAllTablesFromServer()
    if Config.Debug then lib.print.info('[requestAllTablesFromServer] - Requesting all tables from server') end
    
    local tables = lib.callback.await('it-drugs:server:getTables', false)
    if not tables then
        if Config.Debug then lib.print.error('[requestAllTablesFromServer] - Failed to retrieve tables from server') end
        return
    end

    local tableCount = 0
    serverTables = {}
    for k, v in pairs(tables) do
        serverTables[k] = v
        tableCount = tableCount + 1
    end

    if Config.Debug then 
        lib.print.info('[requestAllTablesFromServer] - Retrieved', tableCount, 'tables from server') 
    end

    lastCoordinates = GetEntityCoords(PlayerPedId())
    if not updateLoopStarted then
        TableUpdateLoop()
    end
end

function GetTableData(plantId)
    if Config.Debug then lib.print.info('[GetPlantData] - Getting data for plant ID:', plantId) end
    return serverTables[plantId]
end

RegisterNetEvent('it-drugs:client:syncTables', function(tables)
    if not tables then
        if Config.Debug then lib.print.error('[it-drugs:client:syncTables] - No tables received from server') end
        return
    end
    if Config.Debug then lib.print.info('[it-drugs:client:syncTables] - Syncing tables from server') end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local newTables = {}
    local removedTables = {}

    for k, v in pairs(tables) do
        if not serverTables[k] then
            newTables[k] = v
        end
    end    for k, v in pairs(serverTables) do
        if not tables[k] then
            removedTables[k] = v
        end
    end
    
    local newCount = 0
    local removedCount = 0
    for _ in pairs(newTables) do newCount = newCount + 1 end
    for _ in pairs(removedTables) do removedCount = removedCount + 1 end

    if Config.Debug then
        lib.print.info('[it-drugs:client:syncTables] - New tables:', newCount)
        lib.print.info('[it-drugs:client:syncTables] - Removed tables:', removedCount)
    end

    serverTables = tables

    for tableId in pairs(removedTables) do
        deleteTable(tableId)
    end

    for tableId, tableData in pairs(newTables) do
        if tableData and tableData.coords then
            local distance = #(playerCoords - vector3(tableData.coords.x, tableData.coords.y, tableData.coords.z))
            if distance <= Config.MinPropDistance then
                spawnTable(tableId)
            else
                if Config.Debug then
                    lib.print.warn('[it-drugs:client:syncTables] - Table with ID:', tableId, 'is too far away to spawn')
                end
            end
        end
    end

    if not updateLoopStarted then
        TableUpdateLoop()
    end
end)

local function initializeTableHandler()
    Wait(2000)
    requestAllTablesFromServer()
end

if serverFramework == 'es_extended' then
    AddEventHandler('esx:playerLoaded', function(_, _, _)
        if Config.Debug then lib.print.info('[cl_tableHandler] - ESX player loaded event triggered') end
        initializeTableHandler()
    end)
elseif serverFramework == 'qb-core' or serverFramework == 'qbx_core' then
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        if Config.Debug then lib.print.info('[cl_tableHandler] - QBCore player loaded event triggered') end
        initializeTableHandler()
    end)
elseif serverFramework == 'ND_Core' then
    AddEventHandler("ND:characterLoaded", function()
        if Config.Debug then lib.print.info('[cl_tableHandler] - ND player loaded event triggered') end
        initializeTableHandler()
    end)
else
    if Config.Debug then lib.print.error('[cl_tableHandler] - Unknown framework:', serverFramework) end
    lib.print.error('[cl_tableHandler] Unable to load player please check cl_tableHandler.lua')
end