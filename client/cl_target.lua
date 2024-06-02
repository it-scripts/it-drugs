-- ┌────────────────────────────────────────────────────────┐
-- │ ____  _             _     _____                    _   │
-- │|  _ \| | __ _ _ __ | |_  |_   _|_ _ _ __ __ _  ___| |_ │
-- │| |_) | |/ _` | '_ \| __|   | |/ _` | '__/ _` |/ _ \ __|│
-- │|  __/| | (_| | | | | |_    | | (_| | | | (_| |  __/ |_ │
-- │|_|   |_|\__,_|_| |_|\__|   |_|\__,_|_|  \__, |\___|\__|│
-- │                                         |___/          │
-- └────────────────────────────────────────────────────────┘
-- Plant Target
if Config.Debug and Config.Target then lib.print.info('Setting up Target System') end
CreateThread(function()
    if Config.Target == 'qb-target' then
        if Config.Debug then lib.print.info('Detected Target System: qb-target') end -- DEBUG
        
        if not exports['qb-target'] then 
            if Config.Debug then lib.print.info('Target System Running: false') end -- DEBUG
        else 
            if Config.Debug then lib.print.info('Target System Running: true') end -- DEBUG
        end
        -- Check if qb-target is running
        if not exports['qb-target'] then return end
        for k, v in pairs(Config.PlantTypes) do
            for _, plant in pairs(v) do
                exports['qb-target']:AddTargetModel(plant[1], {
                    options = {
                        {
                            label = _U('TARGET__PLANT__LABEL'),
                            icon = 'fas fa-eye',
                            action = function (entity)
                                TriggerEvent('it-drugs:client:checkPlant', {entity = entity})
                            end
                        }
                    },
                    distance = 1.5,
                })
            end
        end
        if Config.Debug then lib.print.info('Registerd all Plant Targets') end -- DEBUG
    elseif Config.Target == 'ox_target' then
        if Config.Debug then lib.print.info('Detected Target System: ox_target') end -- DEBUG

        if not exports.ox_target then 
            if Config.Debug then lib.print.info('Target System Running: false') end -- DEBUG
        else 
            if Config.Debug then lib.print.info('Target System Running: true') end -- DEBUG
        end
        -- Check if ox target is running
        if not exports.ox_target then return end
        for k, v in pairs(Config.PlantTypes) do
            for _, plant in pairs(v) do
                exports.ox_target:addModel(plant[1], {
                    {
                        label = _U('TARGET__PLANT__LABEL'),
                        name = 'it-drugs-check-plant',
                        icon = 'fas fa-eye',
                        onSelect = function(data)
                            TriggerEvent('it-drugs:client:checkPlant', {entity = data.entity})
                        end,
                        distance = 1.5
                    }
                })
            end
        end
    end
    if Config.Debug then lib.print.info('Registerd all Plant Targets') end -- DEBUG
end)

-- ┌────────────────────────────────────────────────────────────────────────────────────┐
-- │ ____                                  _               _____                    _   │
-- │|  _ \ _ __ ___   ___ ___ ___  ___ ___(_)_ __   __ _  |_   _|_ _ _ __ __ _  ___| |_ │
-- │| |_) | '__/ _ \ / __/ __/ _ \/ __/ __| | '_ \ / _` |   | |/ _` | '__/ _` |/ _ \ __|│
-- │|  __/| | | (_) | (_| (_|  __/\__ \__ \ | | | | (_| |   | | (_| | | | (_| |  __/ |_ │
-- │|_|   |_|  \___/ \___\___\___||___/___/_|_| |_|\__, |   |_|\__,_|_|  \__, |\___|\__|│
-- │                                               |___/                 |___/          │
-- └────────────────────────────────────────────────────────────────────────────────────┘
-- Proccesing Target
if Config.EnableProcessing then 
    CreateThread(function()
        if Config.Target == 'qb-target' then
            for k, v in pairs(Config.ProcessingTables) do
                if v.model ~= nil then
                    exports['qb-target']:AddTargetModel(v.model, {
                        options = {
                            {
                                icon = 'fas fa-eye',
                                label = _U('TARGET__TABLE__LABEL'),
                                action = function (entity)
                                    TriggerEvent('it-drugs:client:useTable', {entity = entity, type = k})
                                end
                            }
                        },
                        distance = 1.5,
                    })
                end
            end
        elseif Config.Target == 'ox_target' then
            -- Check if ox target is running
            if not exports.ox_target then return end
            for k, v in pairs(Config.ProcessingTables) do
                if v.model ~= nil then
                    exports.ox_target:addModel(v.model, {
                        {
                            label = _U('TARGET__TABLE__LABEL'),
                            name = 'it-drugs-use-table',
                            icon = 'fas fa-eye',
                            onSelect = function(data)
                                TriggerEvent('it-drugs:client:useTable', {entity = data.entity})
                            end,
                            distance = 1.5
                        }
                    })
                end
            end
        end
    end)
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │ ____       _ _ _               _____                    _   │
-- │/ ___|  ___| | (_)_ __   __ _  |_   _|_ _ _ __ __ _  ___| |_ │
-- │\___ \ / _ \ | | | '_ \ / _` |   | |/ _` | '__/ _` |/ _ \ __|│
-- │ ___) |  __/ | | | | | | (_| |   | | (_| | | | (_| |  __/ |_ │
-- │|____/ \___|_|_|_|_| |_|\__, |   |_|\__,_|_|  \__, |\___|\__|│
-- │                        |___/                 |___/          │
-- └─────────────────────────────────────────────────────────────┘

local function isPedBlacklisted(ped)
	local model = GetEntityModel(ped)
	for i = 1, #Config.BlacklistPeds do
		if model == GetHashKey(Config.BlacklistPeds[i]) then
			return true
		end
	end
	return false
end

-- Create the selling Targets
CreateSellTarget = function()
    if Config.Target == 'qb-target' then
        if not exports['qb-target'] then return end
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

    elseif Config.Target == 'ox_target' then
        -- Check if ox target is running
        if not exports.ox_target then return end
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

RemoveSellTarget = function()
    if Config.Target == 'qb-target' then
        if not exports['qb-target'] then return end
        exports['qb-target']:RemoveGlobalPed({_U('TARGET__SELL__LABEL')})
    elseif Config.Target == 'ox_target' then
        -- Check if ox target is running
        if not exports.ox_target then return end
        exports.ox_target:removeGlobalPed('it-drugs-sell')
    end
end

-- Remove all Targets
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if Config.Target == 'qb-target' then
        if not exports['qb-target'] then return end
        for k, v in pairs(Config.PlantTypes) do
            for _, plant in pairs(v) do
                exports['qb-target']:RemoveTargetModel(plant[1])
            end
        end
        for k, v in pairs(Config.ProcessingTables) do
            if v.model ~= nil then
                exports['qb-target']:RemoveTargetModel(v.model)
            end
        end
    elseif Config.Target == 'ox_target' then
        if not exports.ox_target then return end
        for k, v in pairs(Config.PlantTypes) do
            for _, plant in pairs(v) do
                exports.ox_target:removeModel(plant[1], 'it-drugs-check-plant')
            end
        end
        for k, v in pairs(Config.ProcessingTables) do
            if v.model ~= nil then
                exports.ox_target:removeModel(v.model, 'it-drugs-use-table')
            end
        end
    end
    if Config.EnableSelling then
        RemoveSellTarget()
    end
end)