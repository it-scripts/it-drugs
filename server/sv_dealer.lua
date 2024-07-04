if not Config.EnableDealers then return end

local dealers = {}

--- @class Dealer : OxClass
--- @field id string
local Dealer = lib.class('Dealer')

function Dealer:constructor(id)
    self.id = id
    self.position = nil
    self.items = {}

    self:generatePosition()
end

function Dealer:generatePosition()
    local locations = Config.DrugDealers[self.id].locations
    math.randomseed(os.time() + #locations)

    self.position = locations[math.random(1, #locations)]
end

function Dealer:generateItemData(item)
    local priceData = Config.DrugDealers[self.id].items[item]
    math.randomseed(os.time() + #self.items)

    self.items[item] = {
        price = math.random(priceData.min, priceData.max),
        --amount = math.random(priceData.amount.min, priceData.amount.max)
    }
end

function Dealer:getPosition()
    return self.position
end

function Dealer:getItemData(item)
    return self.items[item]
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

lib.callback.register('it-drugs:server:getDealerItemData', function(_, dealerID, item)
    if not dealers[dealerID] then
        return
    end

    return dealers[dealerID]:getItemData(item)
end)

RegisterNetEvent('it-drugs:server:buyDealerItem', function(dealerID, item, amount, total)
    local src = source
    -- check if data is valid
    if not dealers[dealerID] then
        if Config.Debug then lib.print.info("Dealer not found", dealerID) end
        return
    end

    local serverPrice = dealers[dealerID]:getItemData(item).price * amount

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

        for item, _ in pairs(dealerData.items) do
            dealers[dealerId]:generateItemData(item)
        end
    end
end)