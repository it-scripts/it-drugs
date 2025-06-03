--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
---@class Recipe : OxClass
---@field id string
Recipe = lib.class('Recipe')

function Recipe:constructor(id, recipeData)
    self.id = id
    self.label = recipeData.label
    self.ingrediants = recipeData.ingrediants
    self.outputs = recipeData.outputs
    self.failChance = recipeData.failChance
    self.processTime = recipeData.processTime
    self.showIngrediants = recipeData.showIngrediants
    self.animation = recipeData.animation or {dict = 'anim@amb@drug_processors@coke@female_a@idles', name = 'idle_a',}
    self.particlefx = recipeData.particlefx or nil
end

function Recipe:getData()
    return {
        id = self.id,
        label = self.label,
        ingrediants = self.ingrediants,
        outputs = self.outputs,
        failChance = self.failChance,
        processTime = self.processTime,
        showIngrediants = self.showIngrediants,
        animation = self.animation,
        particlefx = self.particlefx
    }
end