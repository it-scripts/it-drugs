--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
local Dealers = {}

--- @class Dealer : OxClass
--- @field id string
local Dealer = lib.class('Dealer')

function Dealer:constructor(id)
    self.id = id
    self.position = nil
    ---@type table: List of items the dealer is buying
    self.buyItems = {}
    ---@type table: List of items the dealer is selling
    self.sellItems = {}

    Dealers[self.id] = self

    self:generatePosition()
end

function Dealer:generatePosition()
    local locations = Config.DrugDealers[self.id].locations
    math.randomseed(os.time() + #locations)

    self.position = locations[math.random(1, #locations)]
    Dealers[self.id] = self -- Update the dealer in the Dealers table with the new position
end

function Dealer:generateSellItemData(item)
    local priceData = Config.DrugDealers[self.id].items['selling'][item]
    math.randomseed(os.time() + #self.sellItems)

    self.sellItems[item] = {
        price = math.random(priceData.min, priceData.max),
        moneyType = priceData.moneyType,
        --amount = math.random(priceData.amount.min, priceData.amount.max)
    }
    Dealers[self.id] = self -- Update the dealer in the Dealers table with the new sell item
end

function Dealer:generateBuyItemData(item)
    local priceData = Config.DrugDealers[self.id].items['buying'][item]
    math.randomseed(os.time() + #self.sellItems)

    self.buyItems[item] = {
        price = math.random(priceData.min, priceData.max),
        moneyType = priceData.moneyType,
        --amount = math.random(priceData.amount.min, priceData.amount.max)
    }
    Dealers[self.id] = self
end

function Dealer:getPosition()
    return self.position
end

function Dealer:getSellItemData(item)
    return self.sellItems[item]
end

function Dealer:getBuyItemData(item)
    return self.buyItems[item]
end

function Dealer:getData()
    return {
        id = self.id,
        position = self.position,
        buyItems = self.buyItems,
        sellItems = self.sellItems
    }
end