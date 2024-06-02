local getMetadata = function(itemData)
    if not itemData then return nil end
    local encodedData = json.encode(itemData)
    if it.inventory == 'ox' then
        return itemData.metadata or nil
    elseif it.core == "qb-core" then
        return itemData.info or nil
    elseif it.core == "esx" then
        return itemData.metadata or nil
    end
end

for plant, _ in pairs(Config.Plants) do
    it.createUsableItem(plant, function(source, data)
        local src = source
        if it.hasItem(src, plant, 1) then
            local metadata = getMetadata(data)
            if Config.Debug then lib.print.info('Plant metadata', metadata) end
            TriggerClientEvent('it-drugs:client:useSeed', src, plant, metadata)
        end
    end)
end

if Config.EnableProcessing then
    for prTable, _ in pairs(Config.ProcessingTables) do
        it.createUsableItem(prTable, function(source, data)
            local src = source
            if it.hasItem(src, prTable, 1) then
                local metadata = getMetadata(data)
                if Config.Debug then lib.print.info('Table metadata', metadata) end
                TriggerClientEvent('it-drugs:client:placeProcessingTable', src, prTable, metadata)
            end
        end)
    end
end

if Config.EnableDrugs then
    for drug, _ in pairs(Config.Drugs) do
        it.createUsableItem(drug, function(source, data)
            local src = source
            if it.hasItem(src, drug, 1) then
                local currentDrug = lib.callback.await('it-drugs:client:getCurrentDrugEffect', src)
                if Config.Debug then lib.print.info('currentDrug', currentDrug) end
                if not currentDrug then
                    local metadata = getMetadata(data)
                    if it.removeItem(src, drug, 1, metadata) then
                        TriggerClientEvent('it-drugs:client:takeDrug', src, drug)
                    else
                        if Config.Debug then lib.print.error('Failed to remove item') end
                    end
                end
                ShowNotification(src, _U('NOTIFICATION__DRUG__ALREADY'), "info")
            end
        end)
    end
end