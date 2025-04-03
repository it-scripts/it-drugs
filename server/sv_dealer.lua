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
        moneyType = priceData.moneyType,
        --amount = math.random(priceData.amount.min, priceData.amount.max)
    }
end

function Dealer:generateBuyItemData(item)
    local priceData = Config.DrugDealers[self.id].items['buying'][item]
    math.randomseed(os.time() + #self.sellItems)

    self.buyItems[item] = {
        price = math.random(priceData.min, priceData.max),
        moneyType = priceData.moneyType,
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

function Dealer:getData()
    return {
        id = self.id,
        position = self.position,
        buyItems = self.buyItems,
        sellItems = self.sellItems
    }
end

lib.callback.register('it-drugs:server:getDealers', function()
    local temp = {}
    for dealerID, dealer in pairs(dealers) do
        temp[dealerID] = dealer:getData()
    end
    return temp
end)

lib.callback.register('it-drugs:server:getDealerPosition', function(_, dealerID)
    if Config.Debug then lib.print.info("Getting position for dealer ID", dealerID) end
    if not dealers[dealerID] then
        if Config.Debug then lib.print.info("No Dealer Found") end
        return "No Dealer Found"
    end

    if Config.Debug then lib.print.info("Dealer Position", dealers[dealerID]:getPosition()) end
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

    local buyItemData = dealers[dealerID]:getBuyItemData(item)
    local serverPrice = buyItemData.price * amount

    if total ~= serverPrice then
        ShowNotification(src, _U('NOTIFICATION__PRICE__MISMATCH'), 'Error')
        return
    end

    if exports.it_bridge:HasItem(src, item, amount) then
        if exports.it_bridge:RemoveItem(src, item, amount) then
            exports.it_bridge:AddMoney(src, buyItemData.moneyType, total)
            ShowNotification(src, _U('NOTIFICATION__DEALER__SELL__SUCCESS'):format(amount, exports.it_bridge:GetItemLabel(item), total), 'success')
        end
    else
        ShowNotification(src, _U('NOTIFICATION__DEALER__NO__ITEM'), 'Error')
    end
    TriggerClientEvent('it-drugs:client:syncRestLoop', source, false)
end)

RegisterNetEvent('it-drugs:server:buyItemsFromDealer', function(dealerID, item, amount, total)
    local src = source
    -- check if data is valid
    if not dealers[dealerID] then
        if Config.Debug then lib.print.error("Dealer not found", dealerID) end
        return
    end

    local sellItemData = dealers[dealerID]:getSellItemData(item)
    local serverPrice = sellItemData.price * amount

    if total ~= serverPrice then
        ShowNotification(src, _U('NOTIFICATION__PRICE__MISMATCH'), 'Error')
        return
    end

    if exports.it_bridge:GetMoney(src, sellItemData.moneyType) < total then
        ShowNotification(src, _U('NOTIFICATION__NO__MONEY'), 'Error')
        return
    end

    if exports.it_bridge:RemoveMoney(src, sellItemData.moneyType, total) then
        exports.it_bridge:GiveItem(src, item, amount)
        ShowNotification(src, _U('NOTIFICATION__DEALER__BUY__SUCCESS'):format(amount, exports.it_bridge:GetItemLabel(item), total), 'Success')
    end

    TriggerClientEvent('it-drugs:client:syncRestLoop', source, false)
end)

CreateThread(function()
    local webhookString = ''
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

        -- Append the dealer id and position to the webhook string
        local dealerPosition = dealers[dealerId]:getPosition()
        local positionString = '{x : ' .. string.format("%.2f", dealerPosition.x) .. ', y : ' .. string.format("%.2f", dealerPosition.y) .. ', z : ' .. string.format("%.2f", dealerPosition.z) .. '}'
        webhookString = webhookString .. '**'..dealerId .. '** - `' .. positionString .. '`\n'
    end

    SendToWebhook(nil, 'message', nil, {
        description = '### Dealers have been created\n' .. webhookString
    })
end)
