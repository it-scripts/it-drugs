if Config.Target then return end
if Config.Debug then lib.print.info('Activating hate resmon mode') end

local plants = {}
local processingTables = {}

local shownPlant = false
local shownTable = false

-- Get the closest plant in 5 meter radius
CreateThread(function()
    Wait(5000)
    while true do
        Wait(0)
        plants = lib.callback.await('it-drugs:server:getPlants', false)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local closestPlant = nil
        local closestDist = 5.0

        for k, v in pairs(plants) do
            local dist = #(coords - v.coords)
            if dist < closestDist then
                closestDist = dist
                closestPlant = k
            end
        end

        if closestPlant then
            local plant = plants[closestPlant]
            local dist = #(coords - plant.coords)
            if dist < 2 then
                -- Show Notification
                if IsControlJustPressed(0, 38) then
                    lib.print.info('Interacting with plant')
                    TriggerEvent('it-drugs:client:checkPlant', {entity = plant.entity})
                end
                if not shownPlant and not shownTable then
                    lib.showTextUI(_U('INTERACTION__INTERACT_TEXT'), {
                        position = "left-center",
                        icon = "e",
                    })
                    shownPlant = true
                end
            end
        else
            if shownPlant then
                lib.hideTextUI()
                shownPlant = false
            end
        end

    end
end)

-- Get the closest processing table in 5 meter radius
CreateThread(function()
    Wait(5000)
    while true do
        Wait(0)
        plants = lib.callback.await('it-drugs:server:getTables', false)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local closestTable = nil
        local closestDist = 3.0

        for k, v in pairs(processingTables) do
            local dist = #(coords - v.coords)
            if dist < closestDist then
                closestDist = dist
                closestTable = k
            end
        end

        if closestTable then
            local table = processingTables[closestTable]
            local dist = #(coords - table.coords)
            if dist < 2 then
                -- Show Notification
                if IsControlJustPressed(0, 38) then
                    TriggerEvent('it-drugs:client:useTable', {entity = table.entity, type = table.type})
                end
                if not shownPlant and not shownTable then
                    lib.showTextUI(_U('INTERACTION__INTERACT_TEXT'), {
                        position = "left-center",
                        icon = "e",
                    })
                    shownTable = true
                end
            end
        else
            if shownTable then
                lib.hideTextUI()
                shownTable = false
            end
        end
    end
end)