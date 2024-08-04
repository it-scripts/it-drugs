if Config.Debug and Config.Target then lib.print.info('Setting up Target System') end

-- ┌────────────────────────────────────────────────────────┐
-- │ ____  _             _     _____                    _   │
-- │|  _ \| | __ _ _ __ | |_  |_   _|_ _ _ __ __ _  ___| |_ │
-- │| |_) | |/ _` | '_ \| __|   | |/ _` | '__/ _` |/ _ \ __|│
-- │|  __/| | (_| | | | | |_    | | (_| | | | (_| |  __/ |_ │
-- │|_|   |_|\__,_|_| |_|\__|   |_|\__,_|_|  \__, |\___|\__|│
-- │                                         |___/          │
-- └────────────────────────────────────────────────────────┘
-- Plant Target
local inZone = false
local zonaActual = nil
local currentZone = nil
local isNearAnyNPC = false



function GetEntitiesByModel(model)
    local entities = {}
    local modelHash = GetHashKey(model)
    
    local handle, entity = FindFirstObject()
    local success
    repeat
        if DoesEntityExist(entity) and GetEntityModel(entity) == modelHash then
            table.insert(entities, entity)
        end
        success, entity = FindNextObject(handle)
    until not success

    EndFindObject(handle)
    
    return entities
end



CreateThread(function()
    if Config.Target == false then
        local inZone = false
        local zonaActual = nil

        while true do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local isNearAnyPlant = false
            local dentroDeZona = false
            local currentPlant = nil


            for plantType, plants in pairs(Config.PlantTypes) do

                for _, plantData in pairs(plants) do
                    local model = plantData[1]


                    local plantEntities = GetEntitiesByModel(model)
                    
                    for _, plantEntity in ipairs(plantEntities) do
                        if DoesEntityExist(plantEntity) then
                            local plantCoords = GetEntityCoords(plantEntity)
                            local distance = #(playerCoords - plantCoords)

                            if distance < 2.5 then
                                isNearAnyPlant = true
                                currentPlant = plantEntity
                                break
                            end
                        end
                    end
                    if isNearAnyPlant then break end
                end
                if isNearAnyPlant then break end
            end

            if isNearAnyPlant then

                while isNearAnyPlant do
                    playerCoords = GetEntityCoords(playerPed)
                    dentroDeZona = false

                    for plantType, plants in pairs(Config.PlantTypes) do
                        for _, plantData in pairs(plants) do
                            local model = plantData[1]
                            local plantEntities = GetEntitiesByModel(model)
                            
                            for _, plantEntity in ipairs(plantEntities) do
                                if DoesEntityExist(plantEntity) then
                                    local plantCoords = GetEntityCoords(plantEntity)
                                    local distance = #(playerCoords - plantCoords)

                                    if distance < 2.5 then
                                        dentroDeZona = true
                                        currentPlant = plantEntity
                                        if not inZone or zonaActual ~= plantEntity then
                                            exports['qb-core']:DrawText('[E] Inspeccionar Planta', 'right')
                                            inZone = true
                                            zonaActual = plantEntity
                                        end
                                        break
                                    end
                                end
                            end
                            if dentroDeZona then break end
                        end
                        if dentroDeZona then break end
                    end

                    if dentroDeZona and IsControlJustReleased(0, 38) then -- E key
                        exports['qb-core']:KeyPressed()
                        TriggerEvent('it-drugs:client:checkPlant', {entity = currentPlant})
                    end

                    if not dentroDeZona and inZone then
                        exports['qb-core']:HideText()
                        inZone = false
                        zonaActual = nil
                    end

                    Wait(0)

                    isNearAnyPlant = false
                    for plantType, plants in pairs(Config.PlantTypes) do
                        for _, plantData in pairs(plants) do
                            local model = plantData[1]
                            local plantEntities = GetEntitiesByModel(model)
                            
                            for _, plantEntity in ipairs(plantEntities) do
                                if DoesEntityExist(plantEntity) then
                                    local plantCoords = GetEntityCoords(plantEntity)
                                    local distance = #(playerCoords - plantCoords)

                                    if distance < 2.5 then
                                        isNearAnyPlant = true
                                        break
                                    end
                                end
                            end
                            if isNearAnyPlant then break end
                        end
                        if isNearAnyPlant then break end
                    end
                end
            else
                if inZone then
                    exports['qb-core']:HideText()
                    inZone = false
                    zonaActual = nil
                end
            end

            Wait(1000)
        end
    end
end)







if Config.EnableDealers then
    CreateThread(function()
        if Config.Target == false then
            while true do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local isNearAnyDealer = false
                local currentDealer = nil
                local currentKey = nil

                for k, v in pairs(Config.DrugDealers) do
                    if v.ped ~= nil then
                        for _, location in ipairs(v.locations) do
                            local dealerCoords = vector3(location.x, location.y, location.z)
                            local distance = #(playerCoords - dealerCoords)
                            if distance < 1.5 then
                                isNearAnyDealer = true
                                currentDealer = v
                                currentKey = k
                                break
                            end
                        end
                        if isNearAnyDealer then break end
                    end
                end

                if isNearAnyDealer then
                    while isNearAnyDealer do
                        playerCoords = GetEntityCoords(PlayerPedId())
                        local dentroDeZona = false

                        for k, v in pairs(Config.DrugDealers) do
                            if v.ped ~= nil then
                                for _, location in ipairs(v.locations) do
                                    local dealerCoords = vector3(location.x, location.y, location.z)
                                    local distance = #(playerCoords - dealerCoords)
                                    if distance < 1.5 then
                                        dentroDeZona = true
                                        currentDealer = v
                                        currentKey = k

                                        if not inZone or zonaActual ~= k then
                                            exports['qb-core']:DrawText('[E] Hablar con el vendedor', 'right')
                                            inZone = true
                                            zonaActual = k
                                        end
                                        break 
                                    end
                                end
                                if dentroDeZona then break end
                            end
                        end

                        if dentroDeZona and IsControlJustReleased(0, 38) then -- E key
                            exports['qb-core']:KeyPressed()
                            TriggerEvent('it-drugs:client:showDealerMenu', currentKey)
                        end

                        if not dentroDeZona and inZone then
                            exports['qb-core']:HideText()
                            inZone = false
                            zonaActual = nil
                        end

                        Wait(0) 

                        isNearAnyDealer = false
                        for k, v in pairs(Config.DrugDealers) do
                            if v.ped ~= nil then
                                for _, location in ipairs(v.locations) do
                                    local dealerCoords = vector3(location.x, location.y, location.z)
                                    local distance = #(playerCoords - dealerCoords)
                                    if distance < 1.5 then
                                        isNearAnyDealer = true
                                        break
                                    end
                                end
                                if isNearAnyDealer then break end
                            end
                        end
                    end
                end

                Wait(1000) 
            end
        end
    end)
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
if Config.EnableProcessing then 
    CreateThread(function()
        if Config.Target == false then
            while true do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local isNearAnyTable = false
    
                for k, v in pairs(Config.ProcessingTables) do
                    if v.model ~= nil then
                        local tableCoords = GetEntityCoords(v.model)
                        local distance = #(playerCoords - tableCoords)
                        if distance < 1.5 then
                            isNearAnyTable = true
                            break
                        end
                    end
                end
    
                if isNearAnyTable then
                    while isNearAnyTable do
                        playerCoords = GetEntityCoords(PlayerPedId())
                        local dentroDeZona = false
                        local currentTable = nil
                        local currentKey = nil
    
                        for k, v in pairs(Config.ProcessingTables) do
                            if v.model ~= nil then
                                local tableCoords = GetEntityCoords(v.model)
                                local distance = #(playerCoords - tableCoords)
                                if distance < 1.5 then
                                    dentroDeZona = true
                                    currentTable = v
                                    currentKey = k
    
                                    if not inZone or zonaActual ~= v.model then
                                        exports['qb-core']:DrawText('[E] Usar mesa de procesamiento', 'right')
                                        inZone = true
                                        zonaActual = v.model
                                    end
                                    break 
                                end
                            end
                        end
    
                        if dentroDeZona and IsControlJustReleased(0, 38) then -- E key
                            exports['qb-core']:KeyPressed()
                            TriggerEvent('it-drugs:client:useTable', {entity = currentTable.model, type = currentKey})
                        end
    
                        if not dentroDeZona and inZone then
                            exports['qb-core']:HideText()
                            inZone = false
                            zonaActual = nil
                        end
    
                        Wait(0) 
    
                        
                        isNearAnyTable = false
                        for k, v in pairs(Config.ProcessingTables) do
                            if v.model ~= nil then
                                local tableCoords = GetEntityCoords(v.model)
                                local distance = #(playerCoords - tableCoords)
                                if distance < 1.5 then
                                    isNearAnyTable = true
                                    break
                                end
                            end
                        end
                    end
                end
    
                Wait(1000) 
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
    print("CreateSellTarget function called") 
    local inZone = false
    local zonaActual = nil

    while currentZone do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local isNearAnyNPC = false
        local nearbyNPC = nil

        for ped in EnumeratePeds() do
            if not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, false) and not IsPedInAnyVehicle(ped, false) and GetPedType(ped) ~= 28 and not isPedBlacklisted(ped) then
                local pedCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - pedCoords)
                print("Coordenadas del jugador:", playerCoords)
                print("Coordenadas del NPC:", pedCoords)
                print("Distancia al NPC:", distance)
                if distance < 4.0 then
                    isNearAnyNPC = true
                    nearbyNPC = ped
                    print("NPC cercano detectado:", ped)
                    break
                end
            end
        end

        if isNearAnyNPC then
            print("NPC dentro de la zona.")
            while isNearAnyNPC do
                playerCoords = GetEntityCoords(playerPed)
                local dentroDeZona = false

                for ped in EnumeratePeds() do
                    if not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, false) and not IsPedInAnyVehicle(ped, false) and GetPedType(ped) ~= 28 and not isPedBlacklisted(ped) then
                        local pedCoords = GetEntityCoords(ped)
                        local distance = #(playerCoords - pedCoords)
                        print("Coordenadas del jugador (en bucle):", playerCoords)
                        print("Coordenadas del NPC (en bucle):", pedCoords)
                        print("Distancia al NPC (en bucle):", distance)
                        if distance < 4.0 then
                            dentroDeZona = true
                            nearbyNPC = ped

                            if not inZone or zonaActual ~= ped then
                                exports['qb-core']:DrawText('[E] ' .. _U('TARGET__SELL__LABEL'), 'right')
                                print("Texto de inspección de venta mostrado.")
                                inZone = true
                                zonaActual = ped
                            end
                            break
                        end
                    end
                end

                if dentroDeZona and IsControlJustReleased(0, 38) then -- E key
                    exports['qb-core']:KeyPressed()
                    TriggerEvent('it-drugs:client:checkSellOffer', nearbyNPC)
                    print("Evento de oferta de venta disparado.")
                end

                if not dentroDeZona and inZone then
                    exports['qb-core']:HideText()
                    inZone = false
                    zonaActual = nil
                    print("Texto de inspección de venta oculto.")
                end

                Wait(0) 

                isNearAnyNPC = false
                for ped in EnumeratePeds() do
                    if not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, false) and not IsPedInAnyVehicle(ped, false) and GetPedType(ped) ~= 28 and not isPedBlacklisted(ped) then
                        local pedCoords = GetEntityCoords(ped)
                        local distance = #(playerCoords - pedCoords)
                        if distance < 4.0 then
                            isNearAnyNPC = true
                            break
                        end
                    end
                end

                if not isNearAnyNPC then
                    print("Ningún NPC cercano detectado.")
                end
            end
        else
            if inZone then
                exports['qb-core']:HideText()
                inZone = false
                zonaActual = nil
                print("Texto de inspección de venta oculto porque no hay NPC cerca.")
            end
        end

        Wait(1000) 
    end
end




RemoveSellTarget = function()
    if inZone then
        exports['qb-core']:HideText()
        inZone = false
        zonaActual = nil
    end
end

-- Remove all Targets
