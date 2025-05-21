﻿--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
if not exports.it_bridge:GetServerInteraction() then return end

local tableOptions = nil
local dealerOptions = nil
local sellOptions = nil
-- ┌────────────────────────────────────────────────────────┐
-- │ ____  _             _     _____                    _   │
-- │|  _ \| | __ _ _ __ | |_  |_   _|_ _ _ __ __ _  ___| |_ │
-- │| |_) | |/ _` | '_ \| __|   | |/ _` | '__/ _` |/ _ \ __|│
-- │|  __/| | (_| | | | | |_    | | (_| | | | (_| |  __/ |_ │
-- │|_|   |_|\__,_|_| |_|\__|   |_|\__,_|_|  \__, |\___|\__|│
-- │                                         |___/          │
-- └────────────────────────────────────────────────────────┘

local plantZones = {}
--- Create a target for a plant handeld by the script
--- @param targetData table: the target data
function CreatePlantBoxTarget(targetData)
    local options = {
        {
            label = _U('TARGET__PLANT__LABEL'),
            name = 'it-drugs-check-plant',
            icon = 'fas fa-eye',
            onSelect = function(data)
                lib.callback("it-drugs:server:getPlantById", false, function(plantData)
                    if not plantData then
                        lib.print.error('[TargetSystem] - Unable to find plant with ID:', targetData.id)
                    else
                        if Config.Debug then
                            lib.print.info('[TargetSystem] - Current plant data: ', plantData)
                        end
                        TriggerEvent('it-drugs:client:showPlantMenu', targetData.id)
                    end
                end, targetData.id)
            end,
            distance = targetData.distance or 1.5,
        }
    }

    local plantBox = exports.it_bridge:CreateBoxZone({
        coords = vector3(targetData.coords.x, targetData.coords.y, targetData.coords.z),
        size = targetData.size,
        rotation = (targetData.rotation + targetData.zoneRotation),
        debug = Config.DebugPoly,
        drawSprite = targetData.drawSprite,
        distance = targetData.interactDistance or 1.5,
        maxZ = targetData.coords.z + (targetData.size.z / 2),
        minZ = targetData.coords.z,
    }, options)

    return plantBox
end



local function createDealerTargets()
    for k, v in pairs(Config.DrugDealers) do
        if v.ped ~= nil then
            dealerOptions = exports.it_bridge:AddTargetModel(v.ped, {
                {
                    label = _U('TARGET__DEALER__LABLE'),
                    name = 'it-drugs-talk-dealer',
                    icon = 'fas fa-eye',
                    onSelect = function(_)
                        TriggerEvent('it-drugs:client:showDealerActionMenu', k)
                    end,
                    canInteract = function(_, _)
                        return true
                    end,
                    distance = 1.5
                }
            })
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
    for _, v in pairs(Config.ProcessingTables) do
        if v.model ~= nil then
            tableOptions = exports.it_bridge:AddTargetModel(v.model, {
                {
                    label = _U('TARGET__TABLE__LABEL'),
                    name = 'it-drugs-use-table',
                    icon = 'fas fa-eye',
                    onSelect = function(entity)
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
                    end,
                    canInteract = function(_, _)
                        return true
                    end,
                    distance = 1.5
                }
            })
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
    sellOptions = exports.it_bridge:AddGlobalPed({
        {
            label = _U('TARGET__SELL__LABEL'),
            name = 'it-drugs-sell',
            icon = 'fas fa-comment',
            onSelect = function(entity)
                TriggerEvent('it-drugs:client:checkSellOffer', entity)
            end,
            canInteract = function(entity, _)
                if not IsPedDeadOrDying(entity, false) and not IsPedInAnyVehicle(entity, false) and (GetPedType(entity)~=28) and (not IsPedAPlayer(entity)) and (not isPedBlacklisted(entity)) and not IsPedInAnyVehicle(PlayerPedId(), false) then
                    return true
                end
                return false
            end,
            distance = 4
        }
    })
end

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

RemoveSellTarget = function()
    exports.it_bridge:RemoveGlobalPed(sellOptions)
end

-- Remove all Targets
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, v in pairs(Config.PlantTypes) do
        for _, plant in pairs(v) do
            exports.it_bridge:RemoveTargetModel(plant[1], plantOptions)
            
        end
    end
    
    if Config.EnableProcessing then
        for _, v in pairs(Config.ProcessingTables) do
            if v.model ~= nil then
                exports.it_bridge:RemoveTargetModel(v.model, tableOptions)
            end
        end
    end

    if Config.EnableDealers then
        for k, v in pairs(Config.DrugDealers) do
            if v.ped ~= nil then
                exports.it_bridge:RemoveTargetModel(v.ped, dealerOptions)
            end
        end
    end
    if Config.EnableSelling then
        RemoveSellTarget()
    end
end)