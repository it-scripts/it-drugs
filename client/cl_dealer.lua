if not Config.EnableDealers then return end

local dealerPeds = {}

--- Spawn a ped at the given position
--- @param model string
--- @param position vector4
local function spawnDealerPed(model, position)
    local pedHash = GetHashKey(model)

    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do
        Wait(200)
    end

    local ped = CreatePed(4, pedHash, position.x, position.y, position.z, position.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    SetPedCanRagdoll(ped, false)

    return ped
end


CreateThread(function()
    for dealerID, dealerData in pairs(Config.DrugDealers) do
       
        local dealerPosition = lib.callback.await('it-drugs:server:getDealerPosition', false, dealerID)

        while not dealerPosition do
            Wait(500)
            dealerPosition = lib.callback.await('it-drugs:server:getDealerPosition', false, dealerID)
            if Config.Debug then lib.print.info("New Dealer Poistion:", dealerPosition) end
        end

        local ped = spawnDealerPed(dealerData.ped, dealerPosition)
        dealerPeds[dealerID] = ped

        if dealerData.blip.display then
            AddDealerBlip(dealerPosition, dealerData.blip.sprite, dealerData.blip.displayColor, dealerData.blip.displayText)
        end
    end
end)

RegisterNetEvent('it-drugs:client:handleDealerInteraction', function(args)

    local item = args.item
    local itemLabel = exports.it_bridge:GetItemLabel(item)
    local dealerId = args.dealerId
    local price = args.price
    local action = args.action

    local _description
    if action == "buy" then
        _description = _U('INPUT__BUY__DESCRIPTION'):format(itemLabel)
    else
        _description = _U('INPUT__SELL__DESCRIPTION'):format(itemLabel)
    end
    local input = lib.inputDialog(_U('INPUT__BUY__HEADER'), {
        {type = 'number', label = _U('INPUT__BUY__TEXT'), description = _description, required = true, min = 1, default = 1, max = 10}
    })

    if not input then
        ShowNotification(nil, _U('NOTIFICATION__NO__AMOUNT'), 'Error')
        return
    end

    local amount = tonumber(input[1])
    local total = price * amount

    if action == 'sell' then
        TriggerServerEvent('it-drugs:server:sellItemsToDealer', dealerId, item, amount, total)
        return
    end

    if action == 'buy' then
        TriggerServerEvent('it-drugs:server:buyItemsFromDealer', dealerId, item, amount, total)
        return
    end
end)


AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, ped in pairs(dealerPeds) do
            DeleteEntity(ped)
        end
    end
end)
