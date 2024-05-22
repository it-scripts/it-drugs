for plant, _ in pairs(Config.Plants) do
    -- it.createUsableItem(plant, function(source, item)  
    it.createUsableItem(plant, function(source)
        local src = source
        
        if it.hasItem(src, plant, 1) then
            TriggerClientEvent('it-drugs:client:useSeed', src, plant)
        end
    end)
end

if Config.EnableProcessing then
    for prTable, _ in pairs(Config.ProcessingTables) do
        it.createUsableItem(prTable, function(source)
            local src = source
            if it.hasItem(src, prTable, 1) then
                TriggerClientEvent('it-drugs:client:placeProcessingTable', src, prTable)
            end
        end)
    end
end

if Config.EnableDrugs then
    for drug, _ in pairs(Config.Drugs) do
        it.createUsableItem(drug, function(source)
            local src = source
            if it.hasItem(src, drug, 1) then
                local currentDrug = lib.callback.await('it-drugs:client:getCurrentDrugEffect', src)
                if Config.Debug then lib.print.info('currentDrug', currentDrug) end
                if not currentDrug then
                    it.removeItem(src, drug, 1)
                    TriggerClientEvent('it-drugs:client:takeDrug', src, drug)
                    return
                end
                ShowNotification(src, _U('NOTIFICATION__DRUG__ALREADY'), "info")
            end
        end)
    end
end