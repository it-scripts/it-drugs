-- ┌───────────────────────────────────────────────────┐
-- │ ____  _             _     __  __                  │
-- │|  _ \| | __ _ _ __ | |_  |  \/  | ___ _ __  _   _ │
-- │| |_) | |/ _` | '_ \| __| | |\/| |/ _ \ '_ \| | | |│
-- │|  __/| | (_| | | | | |_  | |  | |  __/ | | | |_| |│
-- │|_|   |_|\__,_|_| |_|\__| |_|  |_|\___|_| |_|\__,_|│
-- └───────────────────────────────────────────────────┘
-- Plant Menu

RegisterNetEvent("it-drugs:client:showPlantMenu", function(plantData)
    local plantName = Config.Plants[plantData.type].label

    if plantData.health == 0 then
        lib.registerContext({
            id = "it-drugs-dead-plant-menu",
            title = _U('MENU__DEAD_PLANT'),
            options = {
                {
                    title = _U('MENU__PLANT__LIFE'),
                    icon = "notes-medical",
                    description = math.floor(plantData.health).. '%',
                    metadata = {
                        {label = _U('MENU__PLANT__LIFE__META'), value = " "}
                    },
                    progress = math.floor(plantData.health),
                    colorScheme = "red",
                },
                {
                    title = _U('MENU__PLANT__STAGE'),
                    description = math.floor(plantData.growth).. '%',
                    icon = "seedling",
                    metadata = {
                        {label = _U('MENU__PLANT__STAGE__META'), value = " "}
                    },
                    progress = math.floor(plantData.growth),
                    colorScheme = "green"
                },
                {
                    title = _U('MENU__PLANT__FERTILIZER'),
                    description = math.floor(plantData.fertilizer).. '%',
                    icon = "bucket",
                    metadata = {
                        {label = _U('MENU__PLANT__STAGE__META'), value = " "}
                    },
                    progress = math.floor(plantData.fertilizer),
                    colorScheme = "orange"
                },
                {
                    title = _U('MENU__PLANT__WATER'),
                    description = math.floor(plantData.water).. '%',
                    icon = "droplet",
                    metadata = {
                        {label = _U('MENU__PLANT__STAGE__META'), value = " "}
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
                    args = {entity = plantData.entity, type = plantData.type}
                }
            }
        })
        lib.showContext("it-drugs-dead-plant-menu")
        return
    elseif plantData.growth == 100 then
        lib.registerContext({
            id = "it-drugs-harvest-plant-menu",
            title = _U('MENU_PLANT'):format(plantName),
            options = {
                {
                    title = _U('MENU__PLANT__LIFE'),
                    icon = "notes-medical",
                    description = math.floor(plantData.health).. '%',
                    metadata = {
                        {label = _U('MENU__PLANT__LIFE__META'), value = " "}
                    },
                    progress = math.floor(plantData.health),
                    colorScheme = "red",
                },
                {
                    title = _U('MENU__PLANT__STAGE'),
                    description = math.floor(plantData.growth).. '%',
                    icon = "seedling",
                    metadata = {
                        {label = _U('MENU__PLANT__STAGE__META'), value = " "}
                    },
                    progress = math.floor(plantData.growth),
                    colorScheme = "green"
                },
                {
                    title = _U('MENU__PLANT__FERTILIZER'),
                    description = math.floor(plantData.fertilizer).. '%',
                    icon = "bucket",
                    metadata = {
                        {label = _U('MENU__PLANT__FERTILIZER__META'), value = " "}
                    },
                    progress = math.floor(plantData.fertilizer),
                    colorScheme = "orange"
                },
                {
                    title = _U('MENU__PLANT__WATER'),
                    description = math.floor(plantData.water).. '%',
                    icon = "droplet",
                    metadata = {
                        {label = _U('MENU__PLANT__WATER__META'), value = " "}
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
                    args = {entity = plantData.entity, type = plantData.type}

                },
                {
                    title = _U('MENU__PLANT__DESTROY'),
                    icon = "fire",
                    description = _U('MENU__PLANT__DESTROY__DESC'),
                    arrow = true,
                    event = "it-drugs:client:destroyPlant",
                    args = {entity = plantData.entity, type = plantData.type}
                }
            }
        })
        lib.showContext("it-drugs-harvest-plant-menu")
    
    else
        lib.registerContext({
            id = "it-drugs-plant-menu",
            title = _U('MENU_PLANT'):format(plantName),
            options = {
                {
                    title = _U('MENU__PLANT__LIFE'),
                    icon = "notes-medical",
                    description = math.floor(plantData.health).. '%',
                    metadata = {
                        {label = _U('MENU__PLANT__LIFE__META'), value = " "}
                    },
                    progress = math.floor(plantData.health),
                    colorScheme = "red",
                },
                {
                    title = _U('MENU__PLANT__STAGE'),
                    description = math.floor(plantData.growth).. '%',
                    icon = "seedling",
                    metadata = {
                        {label = _U('MENU__PLANT__STAGE__META'), value = " "}
                    },
                    progress = math.floor(plantData.growth),
                    colorScheme = "green"
                },
                {
                    title = _U('MENU__PLANT__FERTILIZER'),
                    description = math.floor(plantData.fertilizer).. '%',
                    icon = "bucket",
                    metadata = {
                        {label = _U('MENU__PLANT__FERTILIZER__META'), value = " "}
                    },
                    arrow = true,
                    progress = math.floor(plantData.fertilizer),
                    colorScheme = "orange",
                    event = "it-drugs:client:showItemMenu",
                    args = {entity = plantData.entity, type = plantData.type, eventType = "fertilizer"}
                },
                {
                    title = _U('MENU__PLANT__WATER'),
                    description = math.floor(plantData.water).. '%',
                    icon = "droplet",
                    metadata = {
                        {label = _U('MENU__PLANT__WATER__META'), value = " "}
                    },
                    arrow = true,
                    progress = math.floor(plantData.water),
                    colorScheme = "blue",
                    event = "it-drugs:client:showItemMenu",
                    args = {entity = plantData.entity, type = plantData.type, eventType = "water"}
                },
                {
                    title = _U('MENU__PLANT__DESTROY'),
                    icon = "fire",
                    description = _U('MENU__PLANT__DESTROY__DESC'),
                    arrow = true,
                    event = "it-drugs:client:destroyPlant",
                    args = {entity = plantData.entity, type = plantData.type}
                }
            }
        })
        lib.showContext("it-drugs-plant-menu")
    end
end)

RegisterNetEvent('it-drugs:client:showItemMenu', function(data)
    local entity = data.entity
    local type = data.type
    local eventType = data.eventType

    local options = {}
    if eventType == 'water' then
        for item, itemData in pairs(Config.Items) do
            if it.hasItem(item, 1) and itemData.water ~= 0 then
                table.insert(options, {
                    title = it.getItemLabel(item),
                    description = _U('MENU__ITEM__DESC'),
                    metadata = {
                        {label = _U('MENU__PLANT__WATER'), value = itemData.water},
                        {label = _U('MENU__PLANT__FERTILIZER'), value = itemData.fertilizer}
                    },
                    arrow = true,
                    event = 'it-drugs:client:useItem',
                    args = {entity = entity, type = type, item = item}
                })
            end
        end
    elseif eventType == 'fertilizer' then
        for item, itemData in pairs(Config.Items) do
            if it.hasItem(item, 1) and itemData.fertilizer ~= 0 then
                table.insert(options, {
                    title = it.getItemLabel(item),
                    description = _U('MENU__ITEM__DESC'),
                    metadata = {
                        {label = _U('MENU__PLANT__WATER'), value = itemData.water},
                        {label = _U('MENU__PLANT__FERTILIZER'), value = itemData.fertilizer}
                    },
                    arrow = true,
                    event = 'it-drugs:client:useItem',
                    args = {entity = entity, type = type, item = item}
                })
            end
        end
    end
    if #options == 0 then
        ShowNotification(_U('NOTIFICATION__NO__ITEMS'), 'error')
        return
    end

    lib.registerContext({
        id = "it-drugs-item-menu",
        title = _U('MENU__ITEM'),
        options = options
    })

    lib.showContext("it-drugs-item-menu")
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
RegisterNetEvent("it-drugs:client:showProcessingMenu", function(data)

    local targetTable = Config.ProcessingTables[data.type]

    local options = {}
    if not Config.ShowIngrediants then
        for k, v in pairs(targetTable.ingrediants) do
            -- Menu only shows the amount not the name of the item
            table.insert(options, {
                title = _U('MENU__UNKNOWN__INGREDIANT'),
                description = _U('MENU__INGREDIANT__DESC'):format(v),
                icon = "flask",
            })
        end
    else
        for k, v in pairs(targetTable.ingrediants) do
            table.insert(options, {
                title = it.getItemLabel(k),
                description = _U('MENU__INGREDIANT__DESC'):format(v), --:replace("{amount}", v),
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
        args = {entity = data.entity, type = data.type}
    })

    table.insert(options, {
        title = _U('MENU__TABLE__REMOVE'),
        icon = "ban",
        description = _U('MENU__TABLE__REMOVE__DESC'),
        arrow = true,
        event = "it-drugs:client:removeTable",
        args = {entity = data.entity, type = data.type}
    })

    lib.registerContext({
        id = "it-drugs-processing-menu",
        title = _U('MENU_PROCESSING'),
        options = options
    })
    lib.showContext("it-drugs-processing-menu")
end)