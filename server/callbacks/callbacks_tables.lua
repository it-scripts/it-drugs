--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
local function getTableById(tableId)
    if Config.Debug then lib.print.info('[getTableById] - Try to get Table with ID:', tableId) end

    if not ProcessingTables[tableId] then
        if Config.Debug then lib.print.error('[getTableById] - Table with ID:', tableId, 'not found') end
        return nil
    end

    if Config.Debug then lib.print.info('[getTableById] - Table with ID:', tableId, 'found') end
    return ProcessingTables[tableId]:getData()
end

lib.callback.register('it-drugs:server:getTableById', function(source, tableId)
    return getTableById(tableId)
end)

exports('getTableById', function(tableId)
    return getTableById(tableId)
end)

local function getTableByOwner(citId)
    if Config.Debug then lib.print.info('[getTableByOwner] - Try to get all tables owned by:', citId) end

    ---@type table: the temporary table to store the tables
    local temp = {}

    -- Loop through all the processing tables and check if the player owns them
    for tableId, table in pairs(ProcessingTables) do
        if table.owner == citId then
            temp[tableId] = table:getData()
        end
    end

    -- If the player does not own any tables, return nil
    if next(temp) == nil then
        if Config.Debug then lib.print.info('[getTableByOwner] - Player:', citId, 'does not own any tables') end
        return nil
    end

    if Config.Debug then lib.print.info('[getTableByOwner] - Successfully get all tables owned by player:', citId) end
    return temp
end

lib.callback.register('it-drugs:server:getTableByOwner', function(source)
    local citId = exports.it_bridge:GetCitizenId(source)
    return getTableByOwner(citId)
end)

exports('getTableByOwner', function(source)
    local citId = exports.it_bridge:GetCitizenId(source)
    return getTableByOwner(citId)
end)

local function getAllTables()
    if Config.Debug then lib.print.info('[getAllTables] - Try to get all processing tables') end

    local temp = {}

    for k, v in pairs(ProcessingTables) do
        temp[k] = v:getData()
    end

    if Config.Debug then lib.print.info('[getAllTables] - Successfully get all processing tables') end
    return temp
end

lib.callback.register('it-drugs:server:getTables', function(_)
    return getAllTables()
end)

exports('getAllTables', function()
    return getAllTables()
end)

local function getRecipeById(tableId, recipeId)
    if Config.Debug then lib.print.info('[getRecipeById] - Try to get Recipe with ID:', recipeId, 'from Table with ID:', tableId) end

    if not ProcessingTables[tableId] then
        if Config.Debug then lib.print.error('[getRecipeById] - Table with ID:', tableId, 'not found') end
        return nil
    end

    local currentTable = ProcessingTables[tableId]
    local recipe = currentTable:getRecipeData(recipeId)

    if not recipe then
        if Config.Debug then lib.print.error('[getRecipeById] - Recipe with ID:', recipeId, 'not found') end
        return nil
    end

    if Config.Debug then lib.print.info('[getRecipeById] - Recipe with ID:', recipeId, 'from Table with ID:', tableId, 'found') end
    return recipe
end

lib.callback.register('it-drugs:server:getRecipeById', function(source, tableId, recipeId)
    return getRecipeById(tableId, recipeId)
end)

exports('getRecipeById', function(tableId, recipeId)
    return getRecipeById(tableId, recipeId)
end)

local function getTableRecipes(id)
    if Config.Debug then lib.print.info('[getTableRecipes] - Try to get Recipes from Table with ID:', id) end

    if not ProcessingTables[id] then
        if Config.Debug then lib.print.error('[getTableRecipes] - Table with ID:', id, 'not found') end
        return nil
    end

    if Config.Debug then lib.print.info('[getTableRecipes] - Recipes from Table with ID:', id, 'found') end
    return ProcessingTables[id]:getRecipes()
end

lib.callback.register('it-drugs:server:getTableRecipes', function(source, id)
    return getTableRecipes(id)
end)

exports('getTableRecipes', function(id)
    return getTableRecipes(id)
end)

