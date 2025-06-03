--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
---@param plantId string: the plant ID
---@return Plant | nil: the plant object
local function getPlantById(plantId)
    if Config.Debug then lib.print.info('[getPlantById] - Try to get plant with ID:', plantId) end

    if not Plants[plantId] then
        lib.print.error('[getPlantById] - Plant with ID:', plantId, 'does not exist')
        return nil
    end

    if Config.Debug then lib.print.info('[getPlantById] - Successfully get Plant with ID:', plantId) end
    return Plants[plantId]:getData()
end

--- Callback to get the plant data by ID
---@param source number | nil: the source player
---@param plantId string: the plant ID
---@return Plant | nil: the plant object
lib.callback.register('it-drugs:server:getPlantById', function(source, plantId)
   return getPlantById(plantId)
end)

exports('getPlantById', function(plantId)
    return getPlantById(plantId)
end)


---@param citId string: the cit id of a player
---@return table | nil: the list of plants
local function getPlantByOwner(citId)
    if Config.Debug then lib.print.info('[getPlantByOwner] - Try to get plant with owner:', citId) end

    ---@type table: the temporary table to store the plants
    local temp = {}

    -- Loop through all the plants and check if the player owns them
    for plantId, plant in pairs(Plants) do
        if plant.owner == citId then
            temp[plantId] = plant:getData()
        end
    end

    -- If the player does not own any plants, return nil
    if next(temp) == nil then
        if Config.Debug then lib.print.info('[getPlantByOwner] - Player:', citId, 'does not own any plants') end
        return nil
    end

    if Config.Debug then lib.print.info('[getPlantByOwner] - Successfully get all plants owned by player:', citId) end
    return temp
end

--- Callback to get all plants owned by a player
---@param source number: the source player
---@return table | nil: the list of plants
lib.callback.register('it-drugs:server:getPlantByOwner', function(source)
    if Config.Debug then lib.print.info('[getPlantByOwner] - Try to get all plants owned by player:', source) end

    local src = source
    local citId = exports.it_bridge:GetCitizenId(src)

    return getPlantByOwner(citId)
end)

exports('getPlantByOwner', function(playerServerId)
    local citId = exports.it_bridge:GetCitizenId(playerServerId)
    return getPlantByOwner(citId)
end)


---@return table | nil: the list of plants
local function getAllPlants()
    if Config.Debug then lib.print.info('[getAllPlants] - Try to get all plants') end

    ---@type table: the temporary table to store the plants
    local temp = {}

    -- Loop through all the plants and add them to the temporary table
    for k, v in pairs(Plants) do
        temp[k] = v:getData()
    end

    if Config.Debug then lib.print.info('[getAllPlants] - Successfully get all plants') end
    return temp
end
--- Callback to get all plants
---@return table | nil: the list of plants
lib.callback.register('it-drugs:server:getPlants', function(_)
    return getAllPlants()
end)

exports('getAllPlants', function()
    return getAllPlants()
end)

lib.callback.register('it-drugs:server:getPlayerBucket', function(source)
    local src = source
    return GetPlayerRoutingBucket(src)
end)