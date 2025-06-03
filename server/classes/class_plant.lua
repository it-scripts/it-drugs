--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
math = lib.math
Plants = {}

--- @class Plant : OxClass
--- @field id string
Plant = lib.class('Plant')

--- Plant constructor
---@param id string
---@param plantData table
function Plant:constructor(id, plantData)

    if Config.Debug then lib.print.info('[Plant:constructor] - Start constructing plant with ID:', id) end

    ---@type string: the plant ID
    self.id = id
    ---@type vector3: the plant coords
    self.coords = plantData.coords
    ---@type number:
    self.dimension = plantData.dimension
    ---@type string: the plant owner
    self.owner = plantData.owner
    ---@type number: the plant time
    self.plantTime = plantData.plantTime
    ---@type string: the plant type
    self.plantType = plantData.plantType
    ---@type string: the plant seed
    self.seed = plantData.seed
    ---@type number: the plant fertilizer
    self.fertilizer = plantData.fertilizer
    ---@type number: the plant water
    self.water = plantData.water
    ---@type number: the plant health
    self.health = plantData.health
    ---@type number: the plant growth
    self.growth = self:calcGrowth()

    self.growtime = plantData.growtime
    self.stage = self:calcStage()

    Plants[self.id] = self

    --self.metadata = plantData.metadata -- Experimental feature / can only used with ox_inventory

    if Config.Debug then lib.print.info('[Plant:constructor] - Plant constructed with ID:', id) end
end

--- Method to delete the plant object
---@return nil
function Plant:delete()
    Plants[self.id] = nil
end

--- Method to update the plant fertilizer
---@param fertilizer number
---@return nil
function Plant:updateFertilizer(fertilizer)
    self.fertilizer = fertilizer

    -- Update the plant fertilizer in the plants table
    Plants[self.id].fertilizer = fertilizer

    MySQL.update('UPDATE drug_plants SET fertilizer = (:fertilizer) WHERE id = (:id)', {
        ['fertilizer'] = json.encode(self.fertilizer),
        ['id'] = self.id,
    })
end

--- Method to update the plant water
---@param water number
---@return nil
function Plant:updateWater(water)
    self.water = water

    -- Update the plant water in the plants table
    Plants[self.id].water = water

    MySQL.update('UPDATE drug_plants SET water = (:water) WHERE id = (:id)', {
        ['water'] = json.encode(self.water),
        ['id'] = self.id,
    })
end

--- Method to update the plant health
---@param health number
---@return nil
function Plant:updateHealth(health)
    self.health = math.max(health, 0.0)

    -- Update the plant health in the plants table
    Plants[self.id].health = health

    -- Send data to database
    MySQL.update('UPDATE drug_plants SET health = (:health) WHERE id = (:id)', {
        ['health'] = health,
        ['id'] = self.id,
    })
end

--- Method to get the plant data
---@return table
function Plant:getData()
    return {
        id = self.id,
        coords = self.coords,
        dimension = self.dimension,
        owner = self.owner,
        plantType = self.plantType,
        seed = self.seed,
        plantTime = self.plantTime,
        fertilizer = self.fertilizer,
        water = self.water,
        health = self.health,
        growtime = self.growtime,
        stage = self.stage,
        growth = self:calcGrowth()
    }
end

-- Method to calculate the health percentage for a given WeedPlants index
---@return integer: health percentage
function Plant:calcHealth()

    if not Plants[self.id] then return 0 end

    -- Getting plant data to calculate current plant health
    ---@type number
    local health = self.health
    ---@type number
    local fertilizer_amount = self.fertilizer
    ---@type number
    local water_amount = self.water

    -- If the plant has no fertilizer and water, decrease the health
    if fertilizer_amount == 0 or water_amount == 0 then
        health = health - math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    elseif fertilizer_amount < Config.FertilizerThreshold or water_amount < Config.WaterThreshold then
        health = health - math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    end

    health = math.max(health, 0.0)

    self.health = health
    -- Return the health value with a minimum of 0
    return math.max(health)
end

--- Method to calculate the growth percentage for a given WeedPlants index
---@return integer: growth percentage
function Plant:calcGrowth()
    if not Plants[self.id] then return 0 end
    -- If the plant is dead the growth doesnt change anymore
    if self.health <= 0 then return self.growth end
    ---@type number: the current time
    local current_time = os.time()
    ---@type number: the grow time
    local growTime = self.growtime * 60
    ---@type number: the progress
    local progress = os.difftime(current_time, self.plantTime)
    ---@type number: the local growth
    local growth = math.round(progress * 100 / growTime, 2)
    ---@type number: the return value
    local retval = math.min(growth, 100.00)
    self.growth = retval
    return retval
end

--- Method to calculate the growth stage for a given WeedPlants index
---@return integer: growth stage
function Plant:calcStage()
    local growth = self:calcGrowth()
    
    local stages = #Config.PlantTypes[self.plantType]

    local stage = math.floor(growth / (100 / stages)) + 1
    if stage > stages then stage = stages end
    return stage
end