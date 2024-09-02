if not Config.EnableDealers then return end

local dealers = {}

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

    self:generatePosition()
end

function Dealer:generatePosition()
    local locations = Config.DrugDealers[self.id].locations
    math.randomseed(os.time() + #locations)

    self.position = locations[math.random(1, #locations)]
end

function Dealer:generateSellItemData(item)
    local priceData = Config.DrugDealers[self.id].items['selling'][item]
    math.randomseed(os.time() + #self.sellItems)

    self.sellItems[item] = {
        price = math.random(priceData.min, priceData.max),
        --amount = math.random(priceData.amount.min, priceData.amount.max)
    }
end

function Dealer:generateBuyItemData(item)
    local priceData = Config.DrugDealers[self.id].items['buying'][item]
    math.randomseed(os.time() + #self.sellItems)

    self.buyItems[item] = {
        price = math.random(priceData.min, priceData.max),
        --amount = math.random(priceData.amount.min, priceData.amount.max)
    }
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

lib.callback.register('it-drugs:server:getDealerPosition', function(_, dealerID)
    lib.print.info("Getting position for dealer ID", dealerID)
    if not dealers[dealerID] then
        if Config.Debug then lib.print.info("No Dealer Found") end
        return "No Dealer Found"
    end

    lib.print.info("Dealer Position", dealers[dealerID]:getPosition())
    return dealers[dealerID]:getPosition()
end)

lib.callback.register('it-drugs:server:getDealerSellItems', function(_, dealerID)
    if not dealers[dealerID] then
        return
    end

    local temp = {}
    local dealer = dealers[dealerID]
    for item, _ in pairs(dealer.sellItems) do
        temp[item] = dealer:getSellItemData(item)
    end
    return temp
end)

lib.callback.register('it-drugs:server:getDealerBuyItems', function(_, dealerID)
    if not dealers[dealerID] then
        return
    end

    local temp = {}
    local dealer = dealers[dealerID]
    for item, _ in pairs(dealer.buyItems) do
        temp[item] = dealer:getBuyItemData(item)
    end
    return temp
end)


RegisterNetEvent('it-drugs:server:sellItemsToDealer', function (dealerID, item, amount, total)

    local src = source

    if not dealers[dealerID] then
        if Config.Debug then lib.print.error("Dealer not found", dealerID) end
        return
    end

    local serverPrice = dealers[dealerID]:getBuyItemData(item).price * amount

    if total ~= serverPrice then
        ShowNotification(src, _U('NOTIFICATION__PRICE__MISMATCH'), 'error')
        return
    end

    if it.hasItem(src, item, amount) then
        if it.removeItem(src, item, amount) then
            it.addMoney(src, 'cash', total)
            ShowNotification(src, _U('NOTIFICATION__SELL__SUCCESS'):format(it.getItemLabel(source, item)), 'success')
        end
    else
        ShowNotification(src, _U('NOTIFICATION__NO__ITEM'), 'error')
    end
end)

RegisterNetEvent('it-drugs:server:buyItemsFromDealer', function(dealerID, item, amount, total)
    local src = source
    -- check if data is valid
    if not dealers[dealerID] then
        if Config.Debug then lib.print.error("Dealer not found", dealerID) end
        return
    end

    local serverPrice = dealers[dealerID]:getSellItemData(item).price * amount

    if total ~= serverPrice then
        ShowNotification(src, _U('NOTIFICATION__PRICE__MISMATCH'), 'error')
        return
    end

    if it.getMoney(src, 'cash') < total then
        ShowNotification(src, _U('NOTIFICATION__NO__MONEY'), 'error')
        return
    end

    if it.removeMoney(src, 'cash', total) then
        it.giveItem(src, item, amount)
        ShowNotification(src, _U('NOTIFICATION__BUY__SUCCESS'):format(it.getItemLabel(source, item)), 'success')
    end
end)

CreateThread(function()
    local dealer = Config.DrugDealers
    for dealerId, dealerData in pairs(dealer) do
        if Config.Debug then lib.print.info("Create Dealer", dealerId) end
        dealers[dealerId] = Dealer:new(dealerId)


        if dealerData.items['buying'] then
            for item, _ in pairs(dealerData.items['buying']) do
                dealers[dealerId]:generateBuyItemData(item)
            end
        end

        if dealerData.items['selling'] then
            for item, _ in pairs(dealerData.items['selling']) do
                dealers[dealerId]:generateSellItemData(item)
            end
        end
    end
end)