--[[
    https://github.com/it-scripts/it-drugs

    This file is licensed under GPL-3.0 or higher <https://www.gnu.org/licenses/gpl-3.0.en.html>

    Copyright © 2025 AllRoundJonU <https://github.com/allroundjonu>
]]

local placing = false

--- Math function to convert rotation to direction vector
---@param rot vector3 Camera rotation
---@return vector3 Direction vector
local function rotationToDirection(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

--- Create a raycast from the gameplay camera
---@param dist number Distance to cast the ray
---@return boolean|integer hit: 0 = hit, 1 = no hit
---@return vector3 endPos: End position of the ray
---@return integer entityHit: Entity hit by the ray
---@return vector3 surfaceNormal: Surface normal at hit position
local function RayCastCamera(dist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = rotationToDirection(camRot)
    local dest = camPos + (dir * dist)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

RegisterNetEvent('it-drugs:client:placeProp', function(type, item, metadata)
    if placing then return end

    local ped = PlayerPedId()
    if not IsPedOnFoot(ped) then
        ShowNotification(nil, _U('NOTIFICATION__IN__VEHICLE'), "Error")
        return
    end

    local currentModel = nil
    local modelOffset = 0

    -- Load the model based on the type and item
    if type == 'plant' then
        local plantInfos = Config.Plants[item]
        currentModel = GetHashKey(Config.PlantTypes[plantInfos.plantType][1][1])
        modelOffset = Config.PlantTypes[plantInfos.plantType][1][2]
        lib.requestModel(currentModel)

        exports.it_bridge:ShowTextUI(_U('INTERACTION__PLACING__TEXT'), {
        position = "left",
        icon = "cannabis",
        color = "info",
        playSound = false,
        })

    elseif type == 'table' then
        currentModel = GetHashKey(Config.ProcessingTables[item].model)
        lib.requestModel(currentModel)

        exports.it_bridge:ShowTextUI(_U('INTERACTION__PLACING__TABLE__TEXT'), {
        position = 'left',
        icon = 'fa-info',
        color = 'info',
        playSound = true,
        })
    else
        ShowNotification(nil, _U('NOTIFICATION__INVALID__TYPE'), "Error")
        return
    end


    local hit, dest, _, _ = RayCastCamera(Config.rayCastingDistance)
    local coords = GetEntityCoords(ped)
    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)

    local currentProp = CreateObject(currentModel, coords.x, coords.y, groundZ + modelOffset, false, false, false)
    SetEntityCollision(currentProp, false, false)
    SetEntityAlpha(currentProp, 150, true)
    SetEntityHeading(currentProp, 0.0)

    local placed = false
    local rotation = 0.0
    while not placed do
        Wait(0)
        hit, dest, _, _ = RayCastCamera(Config.rayCastingDistance)
        if hit == 1 then
            SetEntityCoords(currentProp, dest.x, dest.y, dest.z + modelOffset)

            if IsControlJustPressed(0, 14) or IsControlJustPressed(0, 16) then
                rotation = rotation + 1.0
                if rotation >= 360.0 then
                    rotation = 0.0
                end
                SetEntityHeading(currentProp, rotation)
            end

            if IsControlJustPressed(0, 15) or IsControlJustPressed(0, 17) then
                rotation = rotation - 1.0
                if rotation <= 0.0 then
                    rotation = 360.0
                end
                SetEntityHeading(currentProp, rotation)
            end

            if IsControlJustPressed(0, 38) then
                placed = true
                exports.it_bridge:CloseTextUI(nil)

                DeleteObject(currentProp)
                if type == 'plant' then
                    PlantSeed(ped, item, dest, metadata)
                elseif type == 'table' then
                    PlaceProcessingTable(ped, item, dest, rotation, metadata)
                end
                return
            end

            if IsControlJustPressed(0, 47) then
                placed = true
                exports.it_bridge:CloseTextUI(nil)
                DeleteObject(currentProp)
                SetModelAsNoLongerNeeded(currentModel)
                TriggerEvent('it-drugs:client:syncRestLoop', false)
                return
            end
        else
            coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            rotation = heading -- Update the rotation to the player heading when not hitting anything
            local forardVector = GetEntityForwardVector(ped)
            _, groundZ = GetGroundZFor_3dCoord(coords.x + (forardVector.x * .5), coords.y + (forardVector.y * .5), coords.z + (forardVector.z * .5), true)

            SetEntityCoords(currentProp, coords.x + (forardVector.x * .5), coords.y + (forardVector.y * .5), groundZ + modelOffset)
            SetEntityHeading(currentProp, heading)
            if IsControlJustPressed(0, 38) then
                placed = true
                local coords = GetEntityCoords(currentProp)
                exports.it_bridge:CloseTextUI(nil)
                DeleteObject(currentProp)
                if type == 'plant' then
                    PlantSeed(ped, item, coords, metadata)
                elseif type == 'table' then
                    PlaceProcessingTable(ped, item, coords, rotation, metadata)
                end
                SetModelAsNoLongerNeeded(currentModel)
                return
            end

            if IsControlJustPressed(0, 47) then
                placed = true
                exports.it_bridge:CloseTextUI(nil)
                DeleteObject(currentProp)
                SetModelAsNoLongerNeeded(currentModel)
                TriggerEvent('it-drugs:client:syncRestLoop', false)
                return
            end
        end
    end
end)