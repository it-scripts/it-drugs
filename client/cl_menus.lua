﻿--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]
RegisterNetEvent('it-drugs:client:showDealerActionMenu', function(dealerId)
    
    local dealerData = Config.DrugDealers[dealerId]
    local dealerName = dealerData.label

    lib.registerContext({
        id = "it-drugs-dealer-action-menu",
        title = _U('MENU__DEALER'):format(dealerName),
        onExit = function()
            TriggerEvent('it-drugs:client:syncRestLoop', false)
        end,
        options = {
            {
                title = _U('MENU__DEALER__ACTION'),
            },
            {
                title = _U('MENU__DEALER__BUY'),
                description = _U('MENU__DEALER__BUY__DESC'),
                icon = "shopping-cart",
                arrow = true,
                event = "it-drugs:client:showDealerMenu",
                args = {dealerId = dealerId, action = 'sell'}
            },
            {
                title = _U('MENU__DEALER_SELL'),
                description = _U('MENU__DEALER__SELL_DESC'),
                icon = "coins",
                arrow = true,
                event = "it-drugs:client:showDealerMenu",
                args = {dealerId = dealerId, action = 'buy'}
            }
        }
    })

    TriggerEvent('it-drugs:client:syncRestLoop', true)
    lib.showContext("it-drugs-dealer-action-menu")
end)

RegisterNetEvent("it-drugs:client:showDealerMenu", function(args)
    local options = {}

    local dealerId = args.dealerId
    local action = args.action

    local dealerData = Config.DrugDealers[dealerId]
    local dealerName = dealerData.label


    if action == 'buy' then
        local buyItems = lib.callback.await('it-drugs:server:getDealerBuyItems', false, dealerId)

        for k, v in pairs(buyItems) do
            table.insert(options, {
                title = exports.it_bridge:GetItemLabel(k),
                description = _U('MENU__DEALER_SELL_ITEM__DESC'):format(exports.it_bridge:GetItemLabel(k), v.price),
                icon = "coins",
                arrow = true,
                event = "it-drugs:client:handleDealerInteraction",
                args = {item = k, price = v.price, dealerId = dealerId, action = 'sell'}
            })
        end

    elseif action == 'sell' then

        local sellItems = lib.callback.await('it-drugs:server:getDealerSellItems', false, dealerId)

        for k, v in pairs(sellItems) do
            table.insert(options, {
                title = exports.it_bridge:GetItemLabel(k),
                description = _U('MENU__DEALER_BUY_ITEM__DESC'):format(exports.it_bridge:GetItemLabel(k), v.price),
                icon = "coins",
                arrow = true,
                event = "it-drugs:client:handleDealerInteraction",
                args = {item = k, price = v.price, dealerId = dealerId, action = 'buy'}
            })
        end

    else
        ShowNotification(nil, _U('NOTIFICATION__INVALID__ACTION'), 'Error')
        return
    end

    lib.registerContext({
        id = "it-drugs-dealer-menu",
        title = _U('MENU__DEALER'):format(dealerName),
        menu = 'it-drugs-dealer-action-menu',
        onBack = function()
            TriggerEvent('it-drugs:client:showDealerActionMenu', dealerId)
        end,
        onExit = function()
            TriggerEvent('it-drugs:client:syncRestLoop', false)
        end,
        options = options
    })

    TriggerEvent('it-drugs:client:syncRestLoop', true)
    lib.showContext("it-drugs-dealer-menu")
end)

-- ┌───────────────────────────────────────────────────┐
-- │ ____  _             _     __  __                  │
-- │|  _ \| | __ _ _ __ | |_  |  \/  | ___ _ __  _   _ │
-- │| |_) | |/ _` | '_ \| __| | |\/| |/ _ \ '_ \| | | |│
-- │|  __/| | (_| | | | | |_  | |  | |  __/ | | | |_| |│
-- │|_|   |_|\__,_|_| |_|\__| |_|  |_|\___|_| |_|\__,_|│
-- └───────────────────────────────────────────────────┘
-- Plant Menu

--[[
Plant Data:
{
        id = self.id,
        entity = self.entity,
        netId = self.netId,
        coords = self.coords,
        owner = self.owner,
        plantType = self.plantType,
        fertilizer = self.fertilizer,
        water = self.water,
        health = self.health,
        growtime = self.growtime,
        stage = self.stage
    }
]]

RegisterNetEvent("it-drugs:client:showPlantMenu", function(plantData)
    local plantName = Config.Plants[plantData.seed].label

    --TODO: Update the metadata to show the correct values
    if plantData.health == 0 then
        lib.registerContext({
            id = "it-drugs-dead-plant-menu",
            title = _U('MENU__DEAD__PLANT'),
            onExit = function()
                TriggerEvent('it-drugs:client:syncRestLoop', false)
            end,
            options = {
                {
                    title = _U('MENU__PLANT__LIFE'),
                    icon = "notes-medical",
                    description = math.floor(plantData.health).. '%',
                    metadata = {
                        _U('MENU__PLANT__LIFE__META')
                    },
                    progress = math.floor(plantData.health),
                    colorScheme = "red",
                },
                {
                    title = _U('MENU__PLANT__STAGE'),
                    description = math.floor(plantData.growth).. '%',
                    icon = "seedling",
                    metadata = {
                        _U('MENU__PLANT__STAGE__META')
                    },
                    progress = math.floor(plantData.growth),
                    colorScheme = "green"
                },
                {
                    title = _U('MENU__PLANT__FERTILIZER'),
                    description = math.floor(plantData.fertilizer).. '%',
                    icon = "bucket",
                    metadata = {
                        _U('MENU__PLANT__FERTILIZER__META')
                    },
                    progress = math.floor(plantData.fertilizer),
                    colorScheme = "orange"
                },
                {
                    title = _U('MENU__PLANT__WATER'),
                    description = math.floor(plantData.water).. '%',
                    icon = "droplet",
                    metadata = {
                        _U('MENU__PLANT__WATER__META')
                    },
                    progress = math.floor(plantData.water),
                    colorScheme = "blue"
                },
                {
                    title = _U('MENU__PLANT__DESTROY'),
                    description = _U('MENU__PLANT__DESTROY__DESC'),
                    icon = "fire",
                    arrow = true,
                    event = "it-drugs:client:destroyPlant",
                    args = {plantData = plantData}
                }
            }
        })
        lib.showContext("it-drugs-dead-plant-menu")
        TriggerEvent('it-drugs:client:syncRestLoop', true)
        return
    elseif plantData.growth == 100 then
        lib.registerContext({
            id = "it-drugs-harvest-plant-menu",
            title = _U('MENU__PLANT'):format(plantName),
            onExit = function()
                TriggerEvent('it-drugs:client:syncRestLoop', false)
            end,
            options = {
                {
                    title = _U('MENU__PLANT__LIFE'),
                    icon = "notes-medical",
                    description = math.floor(plantData.health).. '%',
                    metadata = {
                        _U('MENU__PLANT__LIFE__META')
                    },
                    progress = math.floor(plantData.health),
                    colorScheme = "red",
                },
                {
                    title = _U('MENU__PLANT__STAGE'),
                    description = math.floor(plantData.growth).. '%',
                    icon = "seedling",
                    metadata = {
                       _U('MENU__PLANT__STAGE__META')
                    },
                    progress = math.floor(plantData.growth),
                    colorScheme = "green"
                },
                {
                    title = _U('MENU__PLANT__FERTILIZER'),
                    description = math.floor(plantData.fertilizer).. '%',
                    icon = "bucket",
                    metadata = {
                        _U('MENU__PLANT__FERTILIZER__META')
                    },
                    progress = math.floor(plantData.fertilizer),
                    colorScheme = "orange"
                },
                {
                    title = _U('MENU__PLANT__WATER'),
                    description = math.floor(plantData.water).. '%',
                    icon = "droplet",
                    metadata = {
                        _U('MENU__PLANT__WATER__META')
                    },
                    progress = math.floor(plantData.water),
                    colorScheme = "blue"
                },
                {
                    title = _U('MENU__PLANT__HARVEST'),
                    icon = "scissors",
                    description = _U('MENU__PLANT__HARVEST__DESC'),
                    arrow = true,
                    event = "it-drugs:client:harvestPlant",
                    args = {plantData = plantData}

                },
                {
                    title = _U('MENU__PLANT__DESTROY'),
                    icon = "fire",
                    description = _U('MENU__PLANT__DESTROY__DESC'),
                    arrow = true,
                    event = "it-drugs:client:destroyPlant",
                    args = {plantData = plantData}
                }
            }
        })
        lib.showContext("it-drugs-harvest-plant-menu")
        TriggerEvent('it-drugs:client:syncRestLoop', true)
    
    else
        lib.registerContext({
            id = "it-drugs-plant-menu",
            title = _U('MENU__PLANT'):format(plantName),
            onExit = function()
                TriggerEvent('it-drugs:client:syncRestLoop', false)
            end,
            options = {
                {
                    title = _U('MENU__PLANT__LIFE'),
                    icon = "notes-medical",
                    description = math.floor(plantData.health).. '%',
                    metadata = {
                        _U('MENU__PLANT__LIFE__META')
                    },
                    progress = math.floor(plantData.health),
                    colorScheme = "red",
                },
                {
                    title = _U('MENU__PLANT__STAGE'),
                    description = math.floor(plantData.growth).. '%',
                    icon = "seedling",
                    metadata = {
                        _U('MENU__PLANT__STAGE__META')
                    },
                    progress = math.floor(plantData.growth),
                    colorScheme = "green"
                },
                {
                    title = _U('MENU__PLANT__FERTILIZER'),
                    description = math.floor(plantData.fertilizer).. '%',
                    icon = "bucket",
                    metadata = {
                        _U('MENU__PLANT__FERTILIZER__META')
                    },
                    arrow = true,
                    progress = math.floor(plantData.fertilizer),
                    colorScheme = "orange",
                    event = "it-drugs:client:showItemMenu",
                    args = {plantData = plantData, eventType = "fertilizer"}
                },
                {
                    title = _U('MENU__PLANT__WATER'),
                    description = math.floor(plantData.water).. '%',
                    icon = "droplet",
                    metadata = {
                        _U('MENU__PLANT__WATER__META')
                    },
                    arrow = true,
                    progress = math.floor(plantData.water),
                    colorScheme = "blue",
                    event = "it-drugs:client:showItemMenu",
                    args = {plantData = plantData, eventType = "water"}
                },
                {
                    title = _U('MENU__PLANT__DESTROY'),
                    icon = "fire",
                    description = _U('MENU__PLANT__DESTROY__DESC'),
                    arrow = true,
                    event = "it-drugs:client:destroyPlant",
                    args = {plantData = plantData}
                }
            }
        })
        lib.showContext("it-drugs-plant-menu")
        TriggerEvent('it-drugs:client:syncRestLoop', true)
    end
end)

RegisterNetEvent('it-drugs:client:showItemMenu', function(data)
    local eventType = data.eventType

    local options = {}
    if eventType == 'water' then
        for item, itemData in pairs(Config.Items) do
            if exports.it_bridge:HasItem(item, 1) and itemData.water ~= 0 then
                table.insert(options, {
                    title = exports.it_bridge:GetItemLabel(item),
                    description = _U('MENU__ITEM__DESC'),
                    metadata = {
                        {label = _U('MENU__PLANT__WATER'), value = itemData.water},
                        {label = _U('MENU__PLANT__FERTILIZER'), value = itemData.fertilizer}
                    },
                    arrow = true,
                    event = 'it-drugs:client:useItem',
                    args = {plantData = data.plantData, item = item}
                })
            end
        end
    elseif eventType == 'fertilizer' then
        for item, itemData in pairs(Config.Items) do
            if exports.it_bridge:HasItem(item, 1) and itemData.fertilizer ~= 0 then
                table.insert(options, {
                    title = exports.it_bridge:GetItemLabel(item),
                    description = _U('MENU__ITEM__DESC'),
                    metadata = {
                        {label = _U('MENU__PLANT__WATER'), value = itemData.water},
                        {label = _U('MENU__PLANT__FERTILIZER'), value = itemData.fertilizer}
                    },
                    arrow = true,
                    event = 'it-drugs:client:useItem',
                    args = {plantData = data.plantData, item = item}
                })
            end
        end
    end
    if #options == 0 then
        ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), 'Error')
        TriggerEvent('it-drugs:client:syncRestLoop', false)
        return
    end

    lib.registerContext({
        id = "it-drugs-item-menu",
        title = _U('MENU__ITEM'),
        onExit = function()
            TriggerEvent('it-drugs:client:syncRestLoop', false)
        end,
        options = options
    })

    lib.showContext("it-drugs-item-menu")
    TriggerEvent('it-drugs:client:syncRestLoop', true)
end)

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ ____                              _               __  __                  │
-- │|  _ \ _ __ ___   ___ ___  ___ ___(_)_ __   __ _  |  \/  | ___ _ __  _   _ │
-- │| |_) | '__/ _ \ / __/ _ \/ __/ __| | '_ \ / _` | | |\/| |/ _ \ '_ \| | | |│
-- │|  __/| | | (_) | (_|  __/\__ \__ \ | | | | (_| | | |  | |  __/ | | | |_| |│
-- │|_|   |_|  \___/ \___\___||___/___/_|_| |_|\__, | |_|  |_|\___|_| |_|\__,_|│
-- │                                           |___/                           │
-- └───────────────────────────────────────────────────────────────────────────┘
-- Processing Menu
RegisterNetEvent('it-drugs:client:showRecipesMenu', function(data)

    local tableId = data.tableId
    local recipes = lib.callback.await('it-drugs:server:getTableRecipes', false, tableId)

    if not recipes then
        ShowNotification(nil, _U('NOTIFICATION__NO__RECIPES'), 'Error')
        return
    end

    local options = {}

    for recipeId, recipeData in pairs(recipes) do
        table.insert(options, {
            title = recipeData.label,
            description = _U('MENU__RECIPE__DESC'),
            icon = "flask",
            arrow = true,
            event = "it-drugs:client:showProcessingMenu",
            args = {tableId = tableId, recipeId = recipeId}
        })
    end

    table.insert(options, {
        title = _U('MENU__TABLE__REMOVE'),
        icon = "ban",
        description = _U('MENU__TABLE__REMOVE__DESC'),
        arrow = true,
        event = "it-drugs:client:removeTable",
        args = {tableId = tableId}
    })

    lib.registerContext({
        id = "it-drugs-recipes-menu",
        title = _U('MENU__PROCESSING'),
        onExit = function()
            TriggerEvent('it-drugs:client:syncRestLoop', false)
        end,
        options = options
    })

    TriggerEvent('it-drugs:client:syncRestLoop', true)
    lib.showContext("it-drugs-recipes-menu")

end)

RegisterNetEvent("it-drugs:client:showProcessingMenu", function(data)

    local recipe = lib.callback.await('it-drugs:server:getRecipeById', false, data.tableId, data.recipeId)

    local options = {}
    if not recipe.showIngrediants then
        for _, v in pairs(recipe.ingrediants) do
            -- Menu only shows the amount not the name of the item
            table.insert(options, {
                title = _U('MENU__UNKNOWN__INGREDIANT'),
                description = _U('MENU__INGREDIANT__DESC'):format(v.amount),
                icon = "flask",
            })
        end
    else
        for k, v in pairs(recipe.ingrediants) do
            table.insert(options, {
                title = exports.it_bridge:GetItemLabel(k),
                description = _U('MENU__INGREDIANT__DESC'):format(v.amount), --:replace("{amount}", v),
                icon = "flask",
            })
        end
    end

    table.insert(options, {
        title = _U('MENU__TABLE__PROCESS'),
        icon = "play",
        description = _U('MENU__TABLE__PROCESS__DESC'),
        arrow = true,
        event = "it-drugs:client:processDrugs",
        args = {tableId = data.tableId, recipeId = data.recipeId}
    })

    lib.registerContext({
        id = "it-drugs-processing-menu",
        title = recipe.label,
        options = options,
        menu = 'it-drugs-recipes-menu',
        onBack = function()
            TriggerEvent('it-drugs:client:showRecipesMenu', {tableId = data.tableId})
        end,
        onExit = function()
            TriggerEvent('it-drugs:client:syncRestLoop', false)
        end,
    })
    TriggerEvent('it-drugs:client:syncRestLoop', true)
    lib.showContext("it-drugs-processing-menu")
end)

-- ┌──────────────────────────────────────────┐
-- │ ____       _ _   __  __                  │
-- │/ ___|  ___| | | |  \/  | ___ _ __  _   _ │
-- │\___ \ / _ \ | | | |\/| |/ _ \ '_ \| | | |│
-- │ ___) |  __/ | | | |  | |  __/ | | | |_| |│
-- │|____/ \___|_|_| |_|  |_|\___|_| |_|\__,_|│
-- └──────────────────────────────────────────┘
-- Sell Menu

RegisterNetEvent("it-drugs:client:showSellMenu", function(data)
    local item = data.item
    local amount = data.amount
    local price = data.price
    local ped = data.entity
    local rewardItems = data.rewardItems

    local itemLabel = exports.it_bridge:GetItemLabel(item)


    local options = {}
    if price > 0 then
        table.insert(options, {
            title = _U('MENU__SELL__DEAL'),
            description = _U('MENU__SELL__DESC'):format(itemLabel, amount, amount * price),
            icon = "coins",
        })
    else
        table.insert(options, {
            title = _U('MENU__SELL__DEAL'),
            description = _U('MENU__SEEL__DESC__ZERO'):format(itemLabel, amount),
            icon = "coins",
        })
    end

    if rewardItems then
        table.insert(options, {
            title = _U('MENU__SELL__REWARD'),
            icon = "gift",
        })
        for _, itemData in pairs(rewardItems) do
            table.insert(options, {
                title = exports.it_bridge:GetItemLabel(itemData.name),
                description = _U('MENU__SELL_REWARD_DESC'):format(itemData.amount * amount),
                icon = "coins",
            })
        end
    end

    table.insert(options, {
        title = _U('MENU__SELL__ACCEPT'),
        icon = "circle-check",
        description = _U('MENU__SELL__ACCEPT__DESC'),
        arrow = true,
        event = "it-drugs:client:salesInitiate",
        args = {type = 'buy', item = item, price = price, amount = amount, tped = ped}
    })

    table.insert(options, {
        title = _U('MENU__SELL__REJECT'),
        icon = "circle-xmark",
        description = _U('MENU__SELL__REJECT__DESC'),
        arrow = true,
        event = "it-drugs:client:salesInitiate",
        args = {type = 'close', tped = ped}
    })

    lib.registerContext({
        id = "it-drugs-sell-menu",
        title = _U('MENU__SELL'),
        options = options,
    })
    lib.showContext("it-drugs-sell-menu")
end)

-- ┌──────────────────────────────────────────────────────────┐
-- │    _       _           _         __  __                  │
-- │   / \   __| |_ __ ___ (_)_ __   |  \/  | ___ _ __  _   _ │
-- │  / _ \ / _` | '_ ` _ \| | '_ \  | |\/| |/ _ \ '_ \| | | |│
-- │ / ___ \ (_| | | | | | | | | | | | |  | |  __/ | | | |_| |│
-- │/_/   \_\__,_|_| |_| |_|_|_| |_| |_|  |_|\___|_| |_|\__,_|│
-- └──────────────────────────────────────────────────────────┘

local function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

RegisterNetEvent('it-drugs:client:showMainAdminMenu', function(data)

    local menuType = data.menuType
    if menuType == 'plants' then
        local allPlants = lib.callback.await('it-drugs:server:getPlants', false)
        local plantCount = tablelength(allPlants)

        lib.registerContext({
            id = "it-drugs-admin-main-menu-plants",
            title = _U('MENU__ADMIN__PLANT__MAIN'),
            options = {
                {
                    title = _U('MENU__PLANT__COUNT'),
                    description = _U('MENU__PLANT__COUNT__DESC'):format(plantCount),
                    icon = "seedling",
                },
                {
                    title = _U('MENU__LIST__PLANTS'),
                    description = _U('MENU__LIST__PLANTS__DESC'),
                    icon = "list",
                    arrow = true,
                    event = "it-drugs:client:generatePlantListMenu",
                },
                {
                    title = _U('MENU__ADD__BLIPS'),
                    description = _U('MENU__ADD__PLANT__BLIPS__DESC'),
                    icon = "map-location-dot",
                    arrow = true,
                    event = "it-drugs:client:addAllAdminBlips",
                    args = {type = 'plants'}
                },
                {
                    title = _U('MENU__REMOVE__BLIPS'),
                    description = _U('MENU__REMOVE__PLANT__BLIPS__DESC'),
                    icon = "eraser",
                    arrow = true,
                    event = "it-drugs:client:removeAllAdminBlips",
                    args = {type = 'plants'}
                },
            }
        })
        lib.showContext("it-drugs-admin-main-menu-plants")
    elseif menuType == 'tables' then
        local allTables = lib.callback.await('it-drugs:server:getTables', false)
        local tableCount = tablelength(allTables)

        lib.registerContext({
            id = "it-drugs-admin-main-menu-tables",
            title = _U('MENU__ADMIN__TABLE__MAIN'),
            options = {
                {
                    title = _U('MENU__TABLE__COUNT'),
                    description = _U('MENU__TABLE__COUNT__DESC'):format(tableCount),
                    icon = "flask-vial",
                },
                {
                    title = _U('MENU__LIST__TABLES'),
                    description = _U('MENU__LIST__TABLES__DESC'),
                    icon = "list",
                    arrow = true,
                    event = "it-drugs:client:generateTableListMenu",
                },
                {
                    title = _U('MENU__ADD__BLIPS'),
                    description = _U('MENU__ADD_TABLE__BLIPS__DESC'),
                    icon = "map-location-dot",
                    arrow = true,
                    event = "it-drugs:client:addAllAdminBlips",
                    args = {type = 'tables'}
                },
                {
                    title = _U('MENU__REMOVE__BLIPS'),
                    description = _U('MENU__REMOVE__TABLE__BLIPS__DESC'),
                    icon = "eraser",
                    arrow = true,
                    event = "it-drugs:client:removeAllAdminBlips",
                    args = {type = 'tables'}
                },
            }
        })
        lib.showContext("it-drugs-admin-main-menu-tables")
    end
end)

RegisterNetEvent('it-drugs:client:showPlantListMenu', function(data)

    local plantList = data.plantList

    local options = {}
    for _, v in ipairs(plantList) do
        table.insert(options, {
            title = v.label,
            description = _U('MENU__DIST'):format(math.round(v.distance, 2)),
            icon = "seedling",
            arrow = true,
            event = "it-drugs:client:showPlantAdminMenu",
            args = {plantData = v}
        })
    end

    lib.registerContext({
        id = "it-drugs-plant-list-menu",
        title = _U('MENU__PLANT__LIST'),
        menu = 'it-drugs-placeholder',
        onBack = function()
            Wait(5)
            TriggerEvent('it-drugs:client:showMainAdminMenu', {menuType = 'plants'})
        end,
        options = options
    })
    lib.showContext("it-drugs-plant-list-menu")
end)

RegisterNetEvent('it-drugs:client:showTableListMenu', function(data)
    
    local tableList = data.tableList

    local options = {}
    for _, v in ipairs(tableList) do
        table.insert(options, {
            title = v.label,
            description = _U('MENU__DIST'):format(math.round(v.distance, 2)),
            icon = "flask-vial",
            arrow = true,
            event = "it-drugs:client:showTableAdminMenu",
            args = {tableData = v}
        })
    end

    lib.registerContext({
        id = "it-drugs-table-list-menu",
        title = _U('MENU__TABLE__LIST'),
        menu = 'it-drugs-placeholder',
        onBack = function()
            TriggerEvent('it-drugs:client:showMainAdminMenu', {menuType = 'tables'})
        end,
        options = options
    })
    lib.showContext("it-drugs-table-list-menu")
end)

RegisterNetEvent('it-drugs:client:showPlantAdminMenu', function(data)
    local plantData = data.plantData
    local streetNameHash, _ = GetStreetNameAtCoord(plantData.coords.x, plantData.coords.y, plantData.coords.z)
    local streetName = GetStreetNameFromHashKey(streetNameHash)

    lib.registerContext({
        id = "it-drugs-plant-admin-menu",
        title = _U('MENU__PLANT__ID'):format(plantData.id),
        menu = 'it-drugs-placeholder',
        onBack = function()
            TriggerEvent('it-drugs:client:generatePlantListMenu')
        end,
        options = {
            {
                title = _U('MENU__OWNER'),
                description = plantData.owner,
                icon = "user",
                metadata = {
                    _U('MENU__OWNER__META')
                },
                onSelect = function()
                    lib.setClipboard(plantData.owner)
                    ShowNotification(nil, _U('NOTIFICATION__COPY__CLIPBOARD'):format(plantData.owner), 'Success')
                end
            },
            {
                title = _U('MENU__PLANT__LOCATION'),
                description = _U('MENU__LOCATION__DESC'):format(streetName, plantData.coords.x, plantData.coords.y, plantData.coords.z),
                metadata = {
                    _U('MENU__LOCATION__META')
                },
                icon = "map-marker",
                onSelect = function()
                    lib.setClipboard('('..plantData.coords.x..", "..plantData.coords.y..", "..plantData.coords.z..')')
                    ShowNotification(nil, _U('NOTIFICATION__COPY__CLIPBOARD'):format('('..plantData.coords.x..", "..plantData.coords.y..", "..plantData.coords.z..')'), 'Success')
                end
            },
            {
                title = _U('MENU__PLANT__TELEPORT'),
                description = _U('MENU__PLANT__TELEPORT__DESC'),
                icon = "route",
                arrow = true,
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), plantData.coords.x, plantData.coords.y, plantData.coords.z)
                    ShowNotification(nil, _U('NOTIFICATION__TELEPORTED'), 'Success')
                end
            },
            {
                title = _U('MENU__ADD__BLIP'),
                description = _U('MENU__ADD__PLANT__BLIP__DESC'),
                icon = "map-location-dot",
                arrow = true,
                event = "it-drugs:client:addAdminBlip",
                args = {id = plantData.id, coords = plantData.coords, entityType = plantData.type, type = 'plant'}
            },
            {
                title = _U('MENU__PLANT__DESTROY'),
                description = _U('MENU__PLANT__DESTROY__DESC'),
                icon = "fire",
                arrow = true,
                onSelect = function()
                    TriggerServerEvent('it-drugs:server:destroyPlant', {plantId = plantData.id, extra='admin'})
                    ShowNotification(nil, _U('NOTIFICATION__PLANT__DESTROYED'), 'Success')
                end
            }
        }
    })
    lib.showContext("it-drugs-plant-admin-menu")
end)

RegisterNetEvent('it-drugs:client:showTableAdminMenu', function(data)
    local tableData = data.tableData
    local streetNameHash, _ = GetStreetNameAtCoord(tableData.coords.x, tableData.coords.y, tableData.coords.z)
    local streetName = GetStreetNameFromHashKey(streetNameHash)

    lib.registerContext({
        id = "it-drugs-table-admin-menu",
        title = _U('MENU__TABLE__ID'):format(tableData.id),
        menu = 'it-drugs-placeholder',
        onBack = function()
            TriggerEvent('it-drugs:client:generateTableListMenu')
        end,
        options = {
            {
                title = _U('MENU__PLANT__LOCATION'),
                description = _U('MENU__LOCATION__DESC'):format(streetName, tableData.coords.x, tableData.coords.y, tableData.coords.z),
                metadata = {
                    _U('MENU__LOCATION__META')
                },
                icon = "map-marker",
                onSelect = function()
                    lib.setClipboard('('..tableData.coords.x..", "..tableData.coords.y..", "..tableData.coords.z..')')
                    ShowNotification(nil, _U('NOTIFICATION__COPY__CLIPBOARD'):format('('..tableData.coords.x..", "..tableData.coords.y..", "..tableData.coords.z..')'), 'Success')
                end
            },
            {
                title = _U('MENU__TABLE__TELEPORT'),
                description = _U('MENU__TABLE__TELEPORT__DESC'),
                icon = "route",
                arrow = true,
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), tableData.coords.x, tableData.coords.y, tableData.coords.z)
                    ShowNotification(nil, _U('NOTIFICATION__TELEPORTED'), 'Success')
                end
            },
            {
                title = _U('MENU__ADD__BLIP'),
                description = _U('MENU__ADD__TABLE__BLIP__DESC'),
                icon = "map-location-dot",
                arrow = true,
                event = "it-drugs:client:addAdminBlip",
                args = {id = tableData.id, coords = tableData.coords, entityType = tableData.type, type = 'table'}
            },
            {
                title = _U('MENU__TABLE__DESTROY'),
                description = _U('MENU__TABLE__DESTROY__DESC'),
                icon = "trash",
                arrow = true,
                onSelect = function()
                    TriggerServerEvent('it-drugs:server:removeTable', {tableId = tableData.id, extra='admin'})
                    ShowNotification(nil, _U('NOTIFICATION__TABLE__DESTROYED'), 'Success')
                end,
                
            }
        }
    })
    lib.showContext("it-drugs-table-admin-menu")
end)