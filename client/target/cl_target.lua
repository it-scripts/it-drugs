--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
if not exports.it_bridge:GetServerInteraction() then return end

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
            onSelect = function(_)
                lib.callback("it-drugs:server:getPlantById", false, function(plantData)
                    if not plantData then
                        lib.print.error('[TargetSystem] - Unable to find plant with ID:', targetData.id)
                    else
                        if Config.Debug then
                            lib.print.info('[TargetSystem] - Current plant data: ', plantData)
                        end
                        TriggerEvent('it-drugs:client:showPlantMenu', plantData)
                    end
                end, targetData.id)
            end,
            distance = targetData.distance or 1.5,
        }
    }

    local zoneId = 'it-drugs-plant-'..targetData.id
    local plantBox = exports.it_bridge:CreateBoxZone({
        id = zoneId,
        coords = vector3(targetData.coords.x, targetData.coords.y, targetData.coords.z),
        size = targetData.size,
        rotation = targetData.rotation,
        debug = Config.DebugPoly,
        drawSprite = targetData.drawSprite,
        distance = targetData.interactDistance or 1.5,
        maxZ = targetData.coords.z + (targetData.size.z / 2),
        minZ = targetData.coords.z,
    }, options)

    table.insert(plantZones, plantBox)
    return plantBox
end

local tableZones = {}
function CreateTableBoxTarget(targetData)
    local options = {
        {
            label = _U('TARGET__TABLE__LABEL'),
            name = 'it-drugs-use-table',
            icon = 'fas fa-eye',
            onSelect = function(_)
                lib.callback("it-drugs:server:getTableById", false, function(tableData)
                    if not tableData then
                        lib.print.error('[TargetSystem] - Unable to find plant with ID:', targetData.id)
                    else
                        if Config.Debug then
                            lib.print.info('[TargetSystem] - Current plant data: ', tableData)
                        end
                        TriggerEvent('it-drugs:client:showRecipesMenu', {tableId = tableData.id})
                    end
                end, targetData.id)
            end,
            distance = targetData.distance or 1.5,
        }
    }

    local zoneId = 'it-drugs-table-'..targetData.id
    local tableBox = exports.it_bridge:CreateBoxZone({
        id = zoneId,
        coords = vector3(targetData.coords.x, targetData.coords.y, targetData.coords.z),
        size = targetData.size,
        rotation = targetData.rotation,
        debug = Config.DebugPoly,
        drawSprite = targetData.drawSprite,
        distance = targetData.interactDistance or 1.5,
        maxZ = targetData.coords.z + (targetData.size.z / 2),
        minZ = targetData.coords.z,
    }, options)

    table.insert(plantZones, tableBox)
    return tableBox
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
    for _, v in pairs(plantZones) do
        exports.it_bridge:RemoveBoxZone(v)
    end
    
    if Config.EnableProcessing then
        for _, v in pairs(tableZones) do
            exports.it_bridge:RemoveBoxZone(v)
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