--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
if not Config.EnableDealers then return end

lib.callback.register('it-drugs:server:getDealers', function()
    local temp = {}
    for dealerID, dealer in pairs(Dealers) do
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
            ShowNotification(src, _U('NOTIFICATION__DEALER__SELL__SUCCESS', amount, exports.it_bridge:GetItemLabel(item), total), 'success')
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
        ShowNotification(src, _U('NOTIFICATION__DEALER__BUY__SUCCESS', amount, exports.it_bridge:GetItemLabel(item), total), 'Success')
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
