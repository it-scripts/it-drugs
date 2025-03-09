local serverInventory = exports.it_bridge:GetServerInventory()
local serverFramework = exports.it_bridge:GetServerFramework()

local getMetadata = function(itemData)
    if not itemData then return nil end
    if serverFramework == 'ox' then
        return itemData.metadata or nil
    elseif serverFramework == "qb-core" then
        return itemData.info or nil
    elseif serverFramework == "esx" then
        return itemData.metadata or nil
    end

    return nil
end
if serverInventory == 'ox_inventory' then
    exports('useSeed', function(event, item, inventory, slot, data)
        if Config.Debug then lib.print.info('useSeed', item) end
        local plant = item.name

        if event == 'usingItem' then
            local src = inventory.id
            if exports.it_bridge:HasItem(src, plant, 1) then
                local metadata = nil
                if Config.Debug then lib.print.info('Plant metadata', metadata) end
                TriggerClientEvent('it-drugs:client:useSeed', src, plant, metadata)
            else
                if Config.Debug then lib.print.error('Failed to use seed', src, exports.it_bridge:HasItem(src, plant, 1)) end
            end
        end
    end)

    if Config.EnableProcessing then
        exports('placeProcessingTable', function(event, item, inventory, slot, data)

            if Config.Debug then lib.print.info('placeProcessingTable', item) end

            local prTable = item.name
            if event == 'usingItem' then
                local src = inventory.id
                if exports.it_bridge:HasItem(src, prTable, 1) then
                    local metadata = getMetadata(prTable)
                    if Config.Debug then lib.print.info('Table metadata', metadata) end
                    TriggerClientEvent('it-drugs:client:placeProcessingTable', src, prTable, metadata)
                end
            end
        end)
    end

    if Config.EnableDrugs then
        exports('takeDrug', function(event, item, inventory, slot, data)

            if Config.Debug then lib.print.info('takeDrug', item) end

            local drug = item.name
            if event == 'usingItem' then -- EVENT MIGHT BE usingItem
                local src = inventory.id
                local currentDrug = lib.callback.await('it-drugs:client:getCurrentDrugEffect', src)
                if Config.Debug then lib.print.info('currentDrug', currentDrug) end
                if not currentDrug then

                    local isDrugOnCooldown = lib.callback.await('it-drugs:client:isDrugOnCooldown', src, drug)
                    if isDrugOnCooldown then
                        ShowNotification(src, _U('NOTIFICATION__DRUG__COOLDOWN'), "info")
                        return
                    end

                    TriggerClientEvent('it-drugs:client:takeDrug', src, drug)
                    exports.ox_inventory:RemoveItem(src, item, 1, nil, slot) -- ADDED THIS ONE TO REMOVE ITEM, on ox_inventory consume = 0
                
                else
                    ShowNotification(src, _U('NOTIFICATION__DRUG__ALREADY'), "info")
                end
            end
        end)
    end
else
    for plant, _ in pairs(Config.Plants) do
        exports.it_bridge:CreateUsableItem(plant, function(source, data)
            local src = source
            if exports.it_bridge:HasItem(src, plant, 1) then
                local metadata = getMetadata(data)
                if Config.Debug then lib.print.info('Plant metadata', metadata) end
                TriggerClientEvent('it-drugs:client:useSeed', src, plant, metadata)
            end
        end)
    end

    if Config.EnableProcessing then
        for prTable, _ in pairs(Config.ProcessingTables) do
            exports.it_bridge:CreateUsableItem(prTable, function(source, data)
                local src = source
                if exports.it_bridge:HasItem(src, prTable, 1) then
                    local metadata = getMetadata(data)
                    if Config.Debug then lib.print.info('Table metadata', metadata) end
                    TriggerClientEvent('it-drugs:client:placeProcessingTable', src, prTable, metadata)
                end
            end)
        end
    end

    if Config.EnableDrugs then
        for drug, _ in pairs(Config.Drugs) do
            exports.it_bridge:CreateUsableItem(drug, function(source, data)
                local src = source
                if exports.it_bridge:HasItem(src, drug, 1) then
                    local currentDrug = lib.callback.await('it-drugs:client:getCurrentDrugEffect', src)
                    if Config.Debug then lib.print.info('currentDrug', currentDrug) end
                    if not currentDrug then

                        local isDrugOnCooldown = lib.callback.await('it-drugs:client:isDrugOnCooldown', src, drug)
                        if isDrugOnCooldown then
                            ShowNotification(src, _U('NOTIFICATION__DRUG__COOLDOWN'), "info")
                            return
                        end

                        local metadata = getMetadata(data)
                        if exports.it_bridge:RemoveItem(src, drug, 1, metadata) then
                            TriggerClientEvent('it-drugs:client:takeDrug', src, drug)
                        else
                            if Config.Debug then lib.print.error('Failed to remove item') end
                        end
                    else
                        ShowNotification(src, _U('NOTIFICATION__DRUG__ALREADY'), "info")
                    end
                end
            end)
        end
    end
end
