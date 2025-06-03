--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
ProcessingTables = {}

---@class ProcessingTable : OxClass
---@field id string
ProcessingTable = lib.class('ProcessingTable')

function ProcessingTable:constructor(id, tableData)

    if Config.Debug then lib.print.info('[ProcessingTable:constructor] - Start constructing ProcessingTable with ID:', id) end

    ---@type string: The ID of the processing table
    self.id = id
    ---@type vector3: The coords of the processing table
    self.coords = tableData.coords
    ---@type number: The rotation of the processing table
    self.rotation = tableData.rotation
    ---@type number: The dimension of the processing table
    self.dimension = tableData.dimension
    ---@type string: The owner of the processing table
    self.owner = tableData.owner
    ---@type string: The type of the processing table
    self.tableType = tableData.tableType

    ---@type table: The recipe of the processing table
    self.recipes = {}

    ProcessingTables[self.id] = self

    if Config.Debug then lib.print.info('[ProcessingTable:constructor] - Finished constructing ProcessingTable with ID:', id) end
end

function ProcessingTable:delete()
    ProcessingTables[self.id] = nil
end

function ProcessingTable:getData()
    return {
        id = self.id,
        coords = self.coords,
        rotation = self.rotation,
        dimension = self.dimension,
        owner = self.owner,
        tableType = self.tableType,
        recipes = self.recipes
    }
end

--- Method to add a recipe to the processing table
---@param recipeid string: The ID of the recipe
---@param recipe Recipe: The recipe object
function ProcessingTable:addRecipe(recipeid, recipe)
    self.recipes[recipeid] = recipe
    ProcessingTables[self.id] = self
end

--- Method to remove a recipe from the processing table
--- @param recipeid string: The ID of the recipe
function ProcessingTable:removeRecipe(recipeid)
    self.recipes[recipeid] = nil
    ProcessingTables[self.id] = self
end

--- Method to get the recipe data from the processing table
--- @param recipeid string: The ID of the recipe
function ProcessingTable:getRecipeData(recipeid)
    local recipe = self.recipes[recipeid]
    if not recipe then return nil end
    return recipe:getData()
end

function ProcessingTable:getRecipes()
    local temp = {}

    for k, v in pairs(self.recipes) do
        temp[k] = v:getData()
    end

    return temp
end