if not Config.Target then return end
local targetSystem = nil
-- ┌────────────────────────────────────────────────────────┐
-- │ ____  _             _     _____                    _   │
-- │|  _ \| | __ _ _ __ | |_  |_   _|_ _ _ __ __ _  ___| |_ │
-- │| |_) | |/ _` | '_ \| __|   | |/ _` | '__/ _` |/ _ \ __|│
-- │|  __/| | (_| | | | | |_    | | (_| | | | (_| |  __/ |_ │
-- │|_|   |_|\__,_|_| |_|\__|   |_|\__,_|_|  \__, |\___|\__|│
-- │                                         |___/          │
-- └────────────────────────────────────────────────────────┘

local function createPlantTargets()

    if targetSystem == 'qb-target' then
        for k, v in pairs(Config.PlantTypes) do
            for _, plant in pairs(v) do
                exports['qb-target']:AddTargetModel(plant[1], {
                    options = {
                        {
                            label = _U('TARGET__PLANT__LABEL'),
                            icon = 'fas fa-eye',
                            action = function (entity)
                                local networkId = NetworkGetNetworkIdFromEntity(entity)
                                lib.callback("it-drugs:server:getPlantByNetId", false, function(plantData)
                                    if not plantData then
                                        lib.print.error('[it-drugs] Unable to get plant data by network id')
                                    else
                                        if Config.Debug then
                                            lib.print.info('[plantSelect] Current plant data: ', plantData)
                                        end
                                        TriggerEvent('it-drugs:client:showPlantMenu', plantData)
                                    end
                                end, networkId)
                            end
                        }
                    },
                    distance = 1.5,
                })
            end
        end
    elseif targetSystem == 'ox_target' then
        for k, v in pairs(Config.PlantTypes) do
            for _, plant in pairs(v) do
                exports.ox_target:removeModel(plant[1], 'it-drugs-check-plant')
                exports.ox_target:addModel(plant[1], {
                    {
                        label = _U('TARGET__PLANT__LABEL'),
                        name = 'it-drugs-check-plant',
                        icon = 'fas fa-eye',
                        onSelect = function(data)
                            local networkId = NetworkGetNetworkIdFromEntity(data.entity)
                            lib.callback("it-drugs:server:getPlantByNetId", false, function(plantData)
                                if not plantData then
                                    lib.print.error('[it-drugs] Unable to get plant data by network id')
                                else
                                    if Config.Debug then
                                        lib.print.info('[plantSelect] Current plant data: ', plantData)
                                    end
                                    TriggerEvent('it-drugs:client:showPlantMenu', plantData)
                                end
                            end, networkId)
                        end,
                        distance = 1.5
                    }
                })
            end
        end
    end
end

local function createDealerTargets()
    if targetSystem == 'qb-target' then
        for k, v in pairs(Config.DrugDealers) do
            if v.ped ~= nil then
                exports['qb-target']:AddTargetModel(v.ped, {
                    options = {
                        {
                            icon = 'fas fa-eye',
                            label = _U('TARGET__DEALER__LABLE'),
                            action = function (entity)
                                TriggerEvent('it-drugs:client:showDealerActionMenu', k)
                            end
                        }
                    },
                    distance = 1.5,
                })
            end
        end
    elseif targetSystem == 'ox_target' then
        for k, v in pairs(Config.DrugDealers) do
            if v.ped ~= nil then
                exports.ox_target:addModel(v.ped, {
                    {
                        label = _U('TARGET__DEALER__LABLE'),
                        name = 'it-drugs-talk-dealer',
                        icon = 'fas fa-eye',
                        onSelect = function(data)
                            TriggerEvent('it-drugs:client:showDealerActionMenu', k)
                        end,
                        distance = 1.5
                    }
                })
            end
        end
    end
end

-- ┌────────────────────────────────────────────────────────────────────────────────────┐
-- │ ____                                  _               _____                    _   │
-- │|  _ \ _ __ ___   ___ ___ ___  ___ ___(_)_ __   __ _  |_   _|_ _ _ __ __ _  ___| |_ │
-- │| |_) | '__/ _ \ / __/ __/ _ \/ __/ __| | '_ \ / _` |   | |/ _` | '__/ _` |/ _ \ __|│
-- │|  __/| | | (_) | (_| (_|  __/\__ \__ \ | | | | (_| |   | | (_| | | | (_| |  __/ |_ │
-- │|_|   |_|  \___/ \___\___\___||___/___/_|_| |_|\__, |   |_|\__,_|_|  \__, |\___|\__|│
-- │                                               |___/                 |___/          │
-- └────────────────────────────────────────────────────────────────────────────────────┘
-- Proccesing Target
local function createProccessingTargets()
    if targetSystem == 'qb-target' then
        for k, v in pairs(Config.ProcessingTables) do
            if v.model ~= nil then
                exports['qb-target']:AddTargetModel(v.model, {
                    options = {
                        {
                            icon = 'fas fa-eye',
                            label = _U('TARGET__TABLE__LABEL'),
                            action = function (entity)
                                local networkId = NetworkGetNetworkIdFromEntity(entity)
                                lib.callback("it-drugs:server:getTableByNetId", false, function(tableData)
                                    if not tableData then
                                        lib.print.error('[it-drugs] Unable to get table data by network id')
                                    else
                                        if Config.Debug then
                                            lib.print.info('[createProccessingTargets] Current table data: ', tableData)
                                        end
                                        TriggerEvent('it-drugs:client:showRecipesMenu', {tableId = tableData.id})
                                    end
                                end, networkId)
                            end
                        }
                    },
                    distance = 1.5,
                })
            end
        end
    elseif targetSystem == 'ox_target' then
        for k, v in pairs(Config.ProcessingTables) do
            if v.model ~= nil then
                exports.ox_target:addModel(v.model, {
                    {
                        label = _U('TARGET__TABLE__LABEL'),
                        name = 'it-drugs-use-table',
                        icon = 'fas fa-eye',
                        onSelect = function(data)
                            local networkId = NetworkGetNetworkIdFromEntity(data.entity)
                            lib.callback("it-drugs:server:getTableByNetId", false, function(tableData)
                                if not tableData then
                                    lib.print.error('[it-drugs] Unable to get table data by network id')
                                else
                                    if Config.Debug then
                                        lib.print.info('[createProccessingTargets] Current table data: ', tableData)
                                    end
                                    TriggerEvent('it-drugs:client:showRecipesMenu', {tableId = tableData.id})
                                end
                            end, networkId)
                        end,
                        distance = 1.5
                    }
                })
            end
        end
    end
end

local function isPedBlacklisted(ped)
	local model = GetEntityModel(ped)
	for i = 1, #Config.BlacklistPeds do
		if model == GetHashKey(Config.BlacklistPeds[i]) then
			return true
		end
	end
	return false
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │ ____       _ _ _               _____                    _   │
-- │/ ___|  ___| | (_)_ __   __ _  |_   _|_ _ _ __ __ _  ___| |_ │
-- │\___ \ / _ \ | | | '_ \ / _` |   | |/ _` | '__/ _` |/ _ \ __|│
-- │ ___) |  __/ | | | | | | (_| |   | | (_| | | | (_| |  __/ |_ │
-- │|____/ \___|_|_|_|_| |_|\__, |   |_|\__,_|_|  \__, |\___|\__|│
-- │                        |___/                 |___/          │
-- └─────────────────────────────────────────────────────────────┘
function CreateSellingTargets()
    if targetSystem == 'qb-target' then
        exports['qb-target']:AddGlobalPed({
            options = {
                {
                    label = _U('TARGET__SELL__LABEL'),
                    icon = 'fas fa-comment',
                    action = function(entity)
                        TriggerEvent('it-drugs:client:checkSellOffer', entity)
                    end,
                    canInteract = function(entity)
                        if not IsPedDeadOrDying(entity, false) and not IsPedInAnyVehicle(entity, false) and (GetPedType(entity)~=28) and (not IsPedAPlayer(entity)) and (not isPedBlacklisted(entity)) and not IsPedInAnyVehicle(PlayerPedId(), false) then
                            return true
                        end
                        return false
                    end,
                }
            },
            distance = 4,
        })
    elseif targetSystem == 'ox_target' then
        exports.ox_target:addGlobalPed({
            {
                label = _U('TARGET__SELL__LABEL'),
                name = 'it-drugs-sell',
                icon = 'fas fa-comment',
                onSelect = function(data)
                    TriggerEvent('it-drugs:client:checkSellOffer', data.entity)
                end,
                canInteract = function(entity, _, _, _, _)
                    if not IsPedDeadOrDying(entity, false) and not IsPedInAnyVehicle(entity, false) and (GetPedType(entity)~=28) and (not IsPedAPlayer(entity)) and (not isPedBlacklisted(entity)) and not IsPedInAnyVehicle(PlayerPedId(), false) then
                        return true
                    end
                    return false
                end,
                distance = 4
            }
        })
    end
end

-- Plant Target
CreateThread(function()
    local function detectQbTarget()

       
        if GetResourceState('qb-target') ~= 'started' then
            return false
        else
            if not exports['qb-target'] then return false else return true end
            return true
        end
    end

    local function detectOxTarget()

        if GetResourceState('ox_target') ~= 'started' then
            return false
        else
            if not exports.ox_target then return false else return true end
        end
    end

    if Config.Target == 'autodetect' then
        if Config.Debug then lib.print.info('[targetSystem] Autodetecting target system...') end
        if detectQbTarget() then
            targetSystem = 'qb-target'
        elseif detectOxTarget() then
            targetSystem = 'ox_target'
        else
            lib.print.error('[targetSystem] Unable to detect target system! Please set it manually in the config.lua')
            return
        end
    else
        if Config.Target == 'qb-target' then
            if detectQbTarget() then
                targetSystem = 'qb-target'
            else
                lib.print.error('[targetSystem] Ubable to detect qb-target! Please make sure it is running')
                return
            end
        elseif Config.Target == 'ox_target' then
            if detectOxTarget() then
                targetSystem = 'ox_target'
            else
                lib.print.error('[targetSystem] Ubable to detect ox_target! Please make sure it is running')
                return
            end
        end
    end

    while not targetSystem do
        Wait(100)
    end

    createPlantTargets()
    if Config.EnableDealers then
        createDealerTargets()
    end
    if Config.EnableProcessing then
        createProccessingTargets()
    end

    for _, dealerData in pairs(Config.DrugDealers) do
        if dealerData.ped ~= nil then
            table.insert(Config.BlacklistPeds, dealerData.ped)
        end
    end

    if Config.EnableSelling and Config.SellEverywhere['enabled'] then
        CreateSellingTargets()
    end
end)

RemoveSellTarget = function()
    if targetSystem == 'qb-target' then
        if not exports['qb-target'] then return end
        exports['qb-target']:RemoveGlobalPed({_U('TARGET__SELL__LABEL')})
    elseif targetSystem == 'ox_target' then
        -- Check if ox target is running
        if not exports.ox_target then return end
        exports.ox_target:removeGlobalPed('it-drugs-sell')
    end
end

-- Remove all Targets
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if targetSystem == 'qb-target' then
        for _, v in pairs(Config.PlantTypes) do
            for _, plant in pairs(v) do
                exports['qb-target']:RemoveTargetModel(plant[1])
            end
        end
        for k, v in pairs(Config.ProcessingTables) do
            if v.model ~= nil then
                exports['qb-target']:RemoveTargetModel(v.model)
            end
        end
    elseif targetSystem == 'ox_target' then
        for _, v in pairs(Config.PlantTypes) do
            for _, plant in pairs(v) do
                if Config.Debug then lib.print.info('Removing plant target: ', plant[1]) end
                exports.ox_target:removeModel(plant[1], 'it-drugs-check-plant')
            end
        end

        if Config.EnableProcessing then
            for _, v in pairs(Config.ProcessingTables) do
                if v.model ~= nil then
                    exports.ox_target:removeModel(v.model, 'it-drugs-use-table')
                end
            end
        end
    end
    if Config.EnableSelling then
        RemoveSellTarget()
    end
end)